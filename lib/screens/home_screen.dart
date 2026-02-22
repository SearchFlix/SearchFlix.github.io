import 'dart:math';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/localization_service.dart';
import '../widgets/movie_card.dart';
import '../widgets/glass_box.dart';
import 'details_screen.dart';
import 'watchlist_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  const HomeScreen({super.key, required this.onLocaleChange});

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
  String _currentCategory = 'trending';

  @override
  void initState() {
    super.initState();
    _fetchMovies('trending');
  }

  Future<void> _fetchMovies(String category) async {
    setState(() {
      _isLoading = true;
      _currentCategory = category;
    });
    try {
      List<Movie> movies;
      if (category == 'trending') {
        movies = await _tmdbService.getTrendingMovies();
      } else if (category == 'popular') {
        movies = await _tmdbService.getPopularMovies();
      } else {
        movies = await _tmdbService.getTopRatedMovies();
      }
      setState(() {
        _movies = movies;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await _tmdbService.searchMovies(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {}
  }

  void _surpriseMe() {
    if (_movies.isNotEmpty) {
      final randomMovie = _movies[Random().nextInt(_movies.length)];
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DetailsScreen(movie: randomMovie)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Lang.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              expandedHeight: 180,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SearchFlix',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                                onPressed: _surpriseMe,
                                tooltip: lang.surpriseMe,
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.language, color: Colors.white),
                                onSelected: (v) => widget.onLocaleChange(Locale(v)),
                                itemBuilder: (c) => [
                                  const PopupMenuItem(value: 'fa', child: Text('فارسی')),
                                  const PopupMenuItem(value: 'en', child: Text('English')),
                                  const PopupMenuItem(value: 'ar', child: Text('العربية')),
                                  const PopupMenuItem(value: 'es', child: Text('Español')),
                                  const PopupMenuItem(value: 'fr', child: Text('Français')),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      GlassBox(
                        borderRadius: 30,
                        opacity: 0.15,
                        child: TextField(
                          controller: _searchController,
                          onChanged: _handleSearch,
                          textAlign: isRtl ? TextAlign.right : TextAlign.left,
                          decoration: InputDecoration(
                            hintText: lang.searchHint,
                            prefixIcon: const Icon(Icons.search, color: Colors.white70),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (!_isSearching)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _CategoryChip(
                              label: lang.trending,
                              isActive: _currentCategory == 'trending',
                              onTap: () => _fetchMovies('trending'),
                            ),
                            _CategoryChip(
                              label: 'Popular',
                              isActive: _currentCategory == 'popular',
                              onTap: () => _fetchMovies('popular'),
                            ),
                            _CategoryChip(
                              label: 'Top Rated',
                              isActive: _currentCategory == 'top_rated',
                              onTap: () => _fetchMovies('top_rated'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: _isLoading
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                  : SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final movie = _isSearching ? _searchResults[index] : _movies[index];
                          return MovieCard(
                            movie: movie,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DetailsScreen(movie: movie)),
                              );
                            },
                          );
                        },
                        childCount: _isSearching ? _searchResults.length : _movies.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          border: const Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home, label: lang.trending, isActive: true, onTap: () {}),
            _NavItem(icon: Icons.favorite_border, label: lang.watchlist, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const WatchlistScreen()));
            }),
            _NavItem(icon: Icons.person_outline, label: lang.login, onTap: () {
              // Login logic
            }),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE50914) : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, this.isActive = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? const Color(0xFFE50914) : Colors.white60),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? const Color(0xFFE50914) : Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}
