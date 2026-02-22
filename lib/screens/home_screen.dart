import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/localization_service.dart';
import '../services/watchlist_provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/glass_box.dart';
import '../widgets/filter_sheet.dart';
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
  List<int> _selectedMovieIds = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _selectionMode = false;
  String _currentCategory = 'trending';
  Map<String, dynamic> _filters = {'genreId': null, 'minRating': 0.0, 'year': null};

  @override
  void initState() {
    super.initState();
    _fetchMovies(_currentCategory);
  }

  Future<void> _fetchMovies(String category) async {
    setState(() {
      _isLoading = true;
      _currentCategory = category;
      _isSearching = false;
    });
    try {
      List<Movie> movies;
      if (category == 'trending') {
        movies = await _tmdbService.getTrendingMovies();
      } else if (category == 'popular') {
        movies = await _tmdbService.getPopularMovies();
      } else if (category == 'top_rated') {
        movies = await _tmdbService.getTopRatedMovies();
      } else {
        // Discovery mode with filters
        movies = await _tmdbService.discoverMovies(
          genreId: _filters['genreId'],
          minRating: _filters['minRating'],
          year: _filters['year'],
        );
      }
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
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await _tmdbService.searchMovies(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {}
  }

  Future<void> _findSimilarBasedOnSelection() async {
    setState(() => _isLoading = true);
    try {
      final similar = await _tmdbService.getSimilarMovies(_selectedMovieIds);
      setState(() {
        _movies = similar;
        _isLoading = false;
        _selectionMode = false;
        _selectedMovieIds = [];
        _currentCategory = 'discovery';
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedMovieIds.contains(id)) {
        _selectedMovieIds.remove(id);
        if (_selectedMovieIds.isEmpty) _selectionMode = false;
      } else {
        _selectedMovieIds.add(id);
      }
    });
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FilterSheet(
        currentFilters: _filters,
        onApply: (newFilters) {
          setState(() => _filters = newFilters);
          _fetchMovies('discovery');
        },
      ),
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width > 1200) return 6;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Lang.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: const Color(0xFF0F0F0F))),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  expandedHeight: 200,
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
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFFE50914), Color(0xFFFF5252)],
                                ).createShader(bounds),
                                child: const Text(
                                  'SEARCHFLIX',
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
                                ),
                              ),
                              if (_selectionMode)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                onPressed: _findSimilarBasedOnSelection,
                                icon: const Icon(Icons.compare_arrows, size: 18),
                                label: Text('Find Similar (${_selectedMovieIds.length})'),
                              )
                              else
                              Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.filter_list, color: Colors.white70), onPressed: _showFilters),
                                  PopupMenuButton<String>(
                                    offset: const Offset(0, 50),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    icon: const Icon(Icons.language, color: Colors.white70),
                                    onSelected: (v) => widget.onLocaleChange(Locale(v)),
                                    itemBuilder: (c) => [
                                      const PopupMenuItem(value: 'fa', child: Text('فارسی')),
                                      const PopupMenuItem(value: 'en', child: Text('English')),
                                      const PopupMenuItem(value: 'ar', child: Text('العربية')),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          GlassBox(
                            borderRadius: 30,
                            opacity: 0.1,
                            child: TextField(
                              controller: _searchController,
                              onChanged: _handleSearch,
                              textAlign: isRtl ? TextAlign.right : TextAlign.left,
                              decoration: InputDecoration(
                                hintText: lang.searchHint,
                                prefixIcon: const Icon(Icons.search, color: Color(0xFFE50914)),
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
                                _CategoryChip(label: lang.trending, isActive: _currentCategory == 'trending', onTap: () => _fetchMovies('trending')),
                                _CategoryChip(label: 'Popular', isActive: _currentCategory == 'popular', onTap: () => _fetchMovies('popular')),
                                _CategoryChip(label: 'Top Rated', isActive: _currentCategory == 'top_rated', onTap: () => _fetchMovies('top_rated')),
                              ],
                            ),
                          ),
                        ],
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
                            crossAxisCount: _calculateCrossAxisCount(width),
                            childAspectRatio: 0.65,
                            mainAxisSpacing: 25,
                            crossAxisSpacing: 20,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final movie = _isSearching ? _searchResults[index] : _movies[index];
                              return MovieCard(
                                movie: movie,
                                selectionMode: _selectionMode,
                                isSelected: _selectedMovieIds.contains(movie.id),
                                onLongPress: () {
                                   setState(() {
                                     _selectionMode = true;
                                     _selectedMovieIds.add(movie.id);
                                   });
                                },
                                onTap: () {
                                  if (_selectionMode) {
                                    _toggleSelection(movie.id);
                                  } else {
                                    Navigator.push(context, MaterialPageRoute(builder: (c) => DetailsScreen(movie: movie)));
                                  }
                                },
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
          
          if (!_selectionMode)
          Positioned(
            bottom: 25,
            left: 20,
            right: 20,
            child: GlassBox(
              borderRadius: 35,
              opacity: 0.15,
              blur: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(icon: Icons.home_rounded, label: lang.trending, isActive: _currentCategory != 'watchlist', onTap: () => _fetchMovies('trending')),
                    _NavItem(icon: Icons.favorite_rounded, label: lang.watchlist, isActive: false, onTap: () {
                       Navigator.push(context, MaterialPageRoute(builder: (c) => const WatchlistScreen()));
                    }),
                    _NavItem(icon: Icons.person_rounded, label: lang.login, onTap: () {}),
                  ],
                ),
              ),
            ),
          ),
        ],
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
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE50914) : Colors.white10,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
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
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? const Color(0xFFE50914) : Colors.white54),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: isActive ? const Color(0xFFE50914) : Colors.white54)),
        ],
      ),
    );
  }
}
