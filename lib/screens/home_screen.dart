import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/localization_service.dart';
import '../services/watchlist_provider.dart';
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

  void _surpriseMe() {
    if (_movies.isNotEmpty) {
      final randomMovie = _movies[Random().nextInt(_movies.length)];
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
            opacity: animation,
            child: DetailsScreen(movie: randomMovie),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Lang.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient for Premium feel
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F0F0F),
                    Color(0xFF1A1A1A),
                    Color(0xFF0F0F0F),
                  ],
                ),
              ),
            ),
          ),
          
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
                              // Beautiful Project Name with Gradient/Styling
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFFE50914), Color(0xFFFF5252)],
                                ).createShader(bounds),
                                child: const Text(
                                  'SEARCHFLIX',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
                                    onPressed: _surpriseMe,
                                    tooltip: lang.surpriseMe,
                                  ),
                                  PopupMenuButton<String>(
                                    offset: const Offset(0, 50),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    icon: const Icon(Icons.language, color: Colors.white70),
                                    onSelected: (v) => widget.onLocaleChange(Locale(v)),
                                    itemBuilder: (c) => [
                                      _langItem('fa', 'فارسی'),
                                      _langItem('en', 'English'),
                                      _langItem('ar', 'العربية'),
                                      _langItem('es', 'Español'),
                                      _langItem('fr', 'Français'),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Hero(
                            tag: 'search-bar',
                            child: Material(
                              color: Colors.transparent,
                              child: GlassBox(
                                borderRadius: 30,
                                opacity: 0.1,
                                blur: 15,
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: _handleSearch,
                                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: lang.searchHint,
                                    hintStyle: const TextStyle(color: Colors.white38),
                                    prefixIcon: const Icon(Icons.search, color: Color(0xFFE50914)),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (!_isSearching)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: _isLoading
                      ? SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFE50914).withOpacity(0.8)),
                            ),
                          ),
                        )
                      : SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            mainAxisSpacing: 25,
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
                                    PageRouteBuilder(
                                      transitionDuration: const Duration(milliseconds: 400),
                                      pageBuilder: (context, a1, a2) => FadeTransition(opacity: a1, child: DetailsScreen(movie: movie)),
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: _isSearching ? _searchResults.length : _movies.length,
                          ),
                        ),
                ),
                // Padding for Bottom Nav
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          
          // Floating Bottom Navigation
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
                    _NavItem(icon: Icons.home_rounded, label: lang.trending, isActive: true, onTap: () {}),
                    _NavItem(icon: Icons.favorite_rounded, label: lang.watchlist, onTap: () {
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

  PopupMenuItem<String> _langItem(String code, String name) {
    return PopupMenuItem(
      value: code,
      child: Text(name, style: const TextStyle(fontSize: 14)),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          boxShadow: isActive ? [BoxShadow(color: const Color(0xFFE50914).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
          color: isActive ? const Color(0xFFE50914) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isActive ? Colors.transparent : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFFE50914) : Colors.white54,
              size: 26,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? const Color(0xFFE50914) : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
