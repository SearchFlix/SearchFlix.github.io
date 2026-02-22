import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/localization_service.dart';
import '../widgets/movie_card.dart';
import '../widgets/glass_box.dart';

class HomeScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  const HomeScreen({super.key, required this.onLocaleChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TMDBService _tmdbService = TMDBService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Movie> _trendingMovies = [];
  List<Movie> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchTrending();
  }

  Future<void> _fetchTrending() async {
    try {
      final movies = await _tmdbService.getTrendingMovies();
      setState(() {
        _trendingMovies = movies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
    } catch (e) {
      // Handle error
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
              expandedHeight: 140,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SearchFlix',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.language, color: Colors.white),
                            onSelected: (value) {
                              widget.onLocaleChange(Locale(value));
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'fa', child: Text('فارسی')),
                              const PopupMenuItem(value: 'en', child: Text('English')),
                              const PopupMenuItem(value: 'ar', child: Text('العربية')),
                              const PopupMenuItem(value: 'es', child: Text('Español')),
                              const PopupMenuItem(value: 'fr', child: Text('Français')),
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
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text(
                    _isSearching ? lang.searchHint : lang.trending,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: _isLoading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final movie = _isSearching ? _searchResults[index] : _trendingMovies[index];
                          return MovieCard(
                            movie: movie,
                            onTap: () {
                              // Details logic
                            },
                          );
                        },
                        childCount: _isSearching ? _searchResults.length : _trendingMovies.length,
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
            _NavItem(icon: Icons.home, label: lang.trending, isActive: true),
            _NavItem(icon: Icons.favorite_border, label: lang.watchlist),
            _NavItem(icon: Icons.person_outline, label: lang.login),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _NavItem({required this.icon, required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}
