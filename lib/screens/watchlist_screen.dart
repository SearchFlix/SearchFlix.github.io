import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/watchlist_provider.dart';
import '../services/localization_service.dart';
import '../widgets/movie_card.dart';
import 'details_screen.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Lang.of(context);
    final watchlistProvider = Provider.of<WatchlistProvider>(context);
    final movies = watchlistProvider.items;
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: CustomScrollView(
        slivers: [
          // PREMIUM HEADER
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F0F0F),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                children: [
                  Text(
                    lang.watchlist,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${movies.length}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
                      ),
                    ),
                  ),
                  // Subtle glowing circles for atmosphere
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE50914).withOpacity(0.05),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (movies.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: TextButton.icon(
                    onPressed: () => _showClearDialog(context, watchlistProvider, lang),
                    icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white70),
                    label: Text(lang.clearAll, style: const TextStyle(color: Colors.white70)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ),

          // MOVIE GRID OR EMPTY STATE
          movies.isEmpty
              ? SliverFillRemaining(
                  child: _EmptyState(lang: lang),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? (width > 1400 ? 6 : 5) : (width > 700 ? 3 : 2),
                      childAspectRatio: 0.68,
                      mainAxisSpacing: 25,
                      crossAxisSpacing: 20,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return MovieCard(
                          movie: movies[index],
                          onTap: () {
                            // Using context.push for professional routing
                            GoRouter.of(context).push('/movie/${movies[index].id}', extra: movies[index]);
                          },
                        );
                      },
                      childCount: movies.length,
                    ),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context, WatchlistProvider provider, Lang lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('SearchFlix', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to clear your entire watchlist?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
            onPressed: () {
              provider.clearWatchlist();
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Lang lang;
  const _EmptyState({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.02),
            ),
            child: const Icon(
              Icons.bookmark_add_outlined,
              size: 100,
              color: Colors.white10,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            lang.emptyWatchlist,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Add movies you want to watch later to see them here!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              lang.exploreNow,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
