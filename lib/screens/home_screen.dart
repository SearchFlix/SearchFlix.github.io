import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/localization_service.dart';
import '../widgets/movie_card.dart';
import '../widgets/filter_panel.dart';
import 'details_screen.dart';
import 'watchlist_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(Locale)? onLocaleChange;
  const HomeScreen({super.key, this.onLocaleChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TMDBService _tmdbService = TMDBService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Movie> _movies = [];
  List<Movie> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  
  Map<String, dynamic> _filters = {
    'genreId': null, 
    'minRating': 0.0, 
    'year': null, 
    'actors': [], 
    'sortBy': 'popularity.desc', 
    'language': 'all'
  };

  @override
  void initState() {
    super.initState();
    _applyFilters();
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isLoading = true;
      _isSearching = false;
    });
    try {
      String? castIds;
      if ((_filters['actors'] as List).isNotEmpty) {
        castIds = (_filters['actors'] as List).map((a) => a['id'].toString()).join(',');
      }
      
      final movies = await _tmdbService.discoverMovies(
        genreId: _filters['genreId'],
        minRating: (_filters['minRating'] as num).toDouble(),
        year: _filters['year'],
        castIds: castIds,
        sortBy: _filters['sortBy'],
        language: _filters['language'],
      );
      
      if (mounted) {
        setState(() {
          _movies = movies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _isSearching = false);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await _tmdbService.searchMovies(query);
      if (mounted) setState(() => _searchResults = results);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final lang = Lang.of(context);
    final width = MediaQuery.of(context).size.width;
    final bool isWide = width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PC SIDEBAR FILTER
          if (isWide)
            SizedBox(
              width: 320,
              height: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20),
                child: GlassBox(
                  child: FilterPanel(
                    filters: _filters,
                    onFilterChanged: (f) => setState(() => _filters = f),
                    onApply: _applyFilters,
                  ),
                ),
              ),
            ),

          // MAIN CONTENT
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  title: Row(
                    children: [
                      const Text('SEARCHFLIX', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFFE50914))),
                      const Spacer(),
                      IconButton(
                        tooltip: lang.surpriseMe,
                        icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFE50914)),
                        onPressed: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (c) => const Center(child: CircularProgressIndicator(color: Color(0xFFE50914))),
                          );
                          try {
                            final movie = await _tmdbService.getRandomMovie();
                            if (mounted) {
                              context.pop(); // Close loading
                              context.push('/movie/${movie.id}', extra: movie);
                            }
                          } catch (e) {
                             if (mounted) context.pop();
                          }
                        },
                      ),
                      IconButton(
                        tooltip: lang.watchlist,
                        icon: const Icon(Icons.favorite_rounded, color: Colors.white70),
                        onPressed: () => context.push('/watchlist'),
                      ),
                      IconButton(
                        tooltip: 'Profile',
                        icon: const Icon(Icons.account_circle, color: Colors.white70),
                        onPressed: () => context.push('/profile'),
                      ),
                      IconButton(
                        tooltip: lang.language,
                        icon: const Icon(Icons.language, color: Colors.white70),
                        onPressed: () {
                           final currentCode = Localizations.localeOf(context).languageCode;
                           final supported = ['fa', 'en', 'ar', 'es', 'fr'];
                           final nextIndex = (supported.indexOf(currentCode) + 1) % supported.length;
                           widget.onLocaleChange?.call(Locale(supported[nextIndex]));
                        },
                      ),
                    ],
                  ),
                ),

                // Mobile Filter Section
                if (!isWide)
                  SliverToBoxAdapter(
                    child: ExpansionTile(
                      title: const Text('SEARCH FILTERS', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold, fontSize: 13)),
                      initiallyExpanded: false,
                      children: [
                        FilterPanel(
                          filters: _filters,
                          onFilterChanged: (f) => setState(() => _filters = f),
                          onApply: _applyFilters,
                        ),
                      ],
                    ),
                  ),

                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _handleSearch,
                      decoration: InputDecoration(
                        hintText: lang.searchHint,
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFE50914)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: _isLoading
                      ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                      : SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isWide ? (width > 1400 ? 5 : 4) : 2,
                            childAspectRatio: 0.68,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final movie = _isSearching ? _searchResults[index] : _movies[index];
                                return MovieCard(
                                  movie: movie,
                                  onTap: () => context.push('/movie/${movie.id}', extra: movie),
                                );
                            },
                            childCount: _isSearching ? _searchResults.length : _movies.length,
                          ),
                        ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
