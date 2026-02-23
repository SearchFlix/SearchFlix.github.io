import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/searchflix_service.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../services/watchlist_provider.dart';
import '../widgets/movie_card.dart';

class DetailsScreen extends StatefulWidget {
  final Movie movie;
  const DetailsScreen({super.key, required this.movie});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final TMDBService _service = TMDBService();
  final SearchFlixService _searchFlixService = SearchFlixService();
  Map<String, dynamic>? _details;
  List<Movie> _similarMovies = [];
  bool _isLoading = true;
  bool _isFetchingLinks = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _updateWebMeta();
  }

  void _updateWebMeta() {
    if (kIsWeb) {
      html.document.title = "SearchFlix | ${widget.movie.title}";
    }
  }

  Future<void> _loadData() async {
    try {
      final bool isTV = widget.movie.mediaType == 'tv';
      final details = isTV 
        ? await _service.getTVShowDetails(widget.movie.id)
        : await _service.getMovieDetails(widget.movie.id);
        
      final similar = isTV
        ? await _service.getSimilarTVShows(widget.movie.id)
        : await _service.getSimilarMovies([widget.movie.id]);
      
      if (mounted) {
        setState(() {
          _details = details;
          _similarMovies = similar.map((m) => Movie.fromJson({...m.toJson(), 'media_type': isTV ? 'tv' : 'movie'})).toList();
          _isLoading = false;
        });
      }
      
      _fetchDownloadLinks();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDownloadLinks() async {
    if (widget.movie.sources != null && widget.movie.sources!.isNotEmpty) return;
    
    setState(() => _isFetchingLinks = true);
    try {
      final sources = await _searchFlixService.fetchDownloadLinks(widget.movie.title);
      if (mounted) {
        setState(() {
          widget.movie.sources = sources;
          _isFetchingLinks = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetchingLinks = false);
    }
  }

  Future<void> _launchTrailer() async {
    if (_details != null && _details!['videos']['results'].isNotEmpty) {
      final trailer = _details!['videos']['results'].firstWhere(
        (v) => v['type'] == 'Trailer' && v['site'] == 'YouTube',
        orElse: () => _details!['videos']['results'].first,
      );
      final url = Uri.parse('https://www.youtube.com/watch?v=${trailer['key']}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Lang.of(context);
    final watchlistProvider = Provider.of<WatchlistProvider>(context);
    final isFavorite = watchlistProvider.isInWatchlist(widget.movie.id);
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: width > 900 ? 500 : 400,
            pinned: true,
            backgroundColor: const Color(0xFF0F0F0F),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: (widget.movie.backdropPath != '') ? widget.movie.backdropUrl : widget.movie.posterUrl,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0F0F0F).withOpacity(0.8),
                          const Color(0xFF0F0F0F),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Movie Schema/Meta Content
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.movie.title,
                          style: TextStyle(
                            fontSize: width > 600 ? 40 : 28, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 1.2
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? const Color(0xFFE50914) : Colors.white70,
                          size: 32,
                        ),
                        onPressed: () => watchlistProvider.toggleWatchlist(widget.movie),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 15,
                    runSpacing: 10,
                    children: [
                      _Badge(label: widget.movie.voteAverage.toStringAsFixed(1), icon: Icons.star, color: Colors.amber),
                      _Badge(label: widget.movie.releaseDate.split('-')[0], icon: Icons.calendar_today, color: Colors.white60),
                      if (_details != null)
                        ...(_details!['genres'] as List).take(3).map((g) => _Badge(label: g['name'], icon: Icons.movie_filter, color: Colors.white30)),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text(
                    widget.movie.overview,
                    style: TextStyle(
                      fontSize: width > 600 ? 18 : 16, 
                      height: 1.6, 
                      color: Colors.white.withOpacity(0.9)
                    ),
                  ),
                  const SizedBox(height: 30),
                                   if (_details != null && _details!['videos']['results'].isNotEmpty)
                    SizedBox(
                      width: width > 600 ? 300 : double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE50914),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: _launchTrailer,
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                                         const SizedBox(height: 20),

                  // Hidden Download Section
                  Consumer<AuthService>(
                    builder: (context, auth, child) {
                      if (!auth.isLoggedIn) return const SizedBox.shrink();
                      
                      final sources = widget.movie.sources;
                      if (sources == null || sources.isEmpty) {
                        return _isFetchingLinks 
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: Colors.white10, height: 40),
                          // Generic title to not draw too much attention or mention "Login"
                          Text(
                            lang.currentLocale == 'fa' ? 'نسخه‌های موجود' : 'Available Versions', 
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)
                          ),
                          const SizedBox(height: 15),
                          ...sources.map((source) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.download_rounded, color: Color(0xFFE50914)),
                              title: Text(source.quality, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(source.type, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                              onPressed: () async {
                                final url = Uri.parse(source.url);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                          )),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),

                  // External Links Section
                  if (_details != null && _details!['external_ids'] != null)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (_details!['external_ids']['imdb_id'] != null)
                          _ExternalLinkBtn(
                            label: 'IMDb',
                            color: const Color(0xFFF5C518),
                            textColor: Colors.black,
                            icon: Icons.star,
                            url: 'https://www.imdb.com/title/${_details!['external_ids']['imdb_id']}/',
                          ),
                        if (_details!['external_ids']['imdb_id'] != null)
                          _ExternalLinkBtn(
                            label: 'Letterboxd',
                            color: const Color(0xFF202c33),
                            textColor: const Color(0xFF00e054),
                            icon: Icons.remove_red_eye_outlined,
                            url: 'https://letterboxd.com/imdb/${_details!['external_ids']['imdb_id']}/',
                          ),
                        if (_details!['external_ids']['tvdb_id'] != null)
                          _ExternalLinkBtn(
                            label: 'TV Time',
                            color: const Color(0xFFffd400),
                            textColor: Colors.black,
                            icon: Icons.tv,
                            url: 'https://www.tvtime.com/en/show/${_details!['external_ids']['tvdb_id']}',
                          ),
                      ],
                    ),
                  
                  const SizedBox(height: 40),
                  const Text('Top Cast', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 160,
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: (_details?['credits']['cast'] as List).take(12).length,
                          itemBuilder: (context, index) {
                            final actor = _details?['credits']['cast'][index];
                            return _ActorCard(
                              id: actor['id'],
                              name: actor['name'],
                              character: actor['character'],
                              imageUrl: actor['profile_path'] != null 
                                ? 'https://image.tmdb.org/t/p/w200${actor['profile_path']}' 
                                : 'https://via.placeholder.com/200x300?text=No+Photo',
                            );
                          },
                        ),
                  ),
                  
                  const SizedBox(height: 40),
                  const Text('More Like This', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: width > 1200 ? 6 : (width > 800 ? 4 : 3),
                childAspectRatio: 0.65,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => MovieCard(
                  movie: _similarMovies[index],
                onTap: () {
                  context.pushReplacement('/movie/${_similarMovies[index].id}', extra: _similarMovies[index]);
                },
                ),
                childCount: _similarMovies.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Badge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ActorCard extends StatelessWidget {
  final int id;
  final String name;
  final String character;
  final String imageUrl;
  const _ActorCard({required this.id, required this.name, required this.character, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/actor/$id?name=${Uri.encodeComponent(name)}'),
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(55),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 90,
                width: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text(character, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _ExternalLinkBtn extends StatelessWidget {
  final String label;
  final String url;
  final Color color;
  final Color textColor;
  final IconData icon;

  const _ExternalLinkBtn({
    required this.label,
    required this.url,
    required this.color,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
