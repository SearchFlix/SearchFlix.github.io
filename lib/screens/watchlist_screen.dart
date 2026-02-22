import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final movies = watchlistProvider.watchlist;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.watchlist),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: movies.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.favorite_border, size: 80, color: Colors.white24),
                   const SizedBox(height: 20),
                   Text(
                     "Your watchlist is empty",
                     style: TextStyle(color: Colors.white54, fontSize: 18),
                   ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
              itemCount: movies.length,
              itemBuilder: (context, index) {
                return MovieCard(
                  movie: movies[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailsScreen(movie: movies[index]),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
