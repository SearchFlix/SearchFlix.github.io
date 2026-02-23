import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'tmdb_service.dart';
import 'watchlist_provider.dart';
import '../models/movie.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Timer? _timer;
  final TMDBService _tmdbService = TMDBService();

  void init(BuildContext context, WatchlistProvider watchlistProvider) {
    if (_timer != null) return;
    
    // Simulate push notifications periodically (e.g., every 3-5 minutes for testing)
    // Normally this would be handled by Firebase/APNS externally.
    _timer = Timer.periodic(const Duration(minutes: 3), (timer) async {
      await _checkAndTriggerNotification(context, watchlistProvider);
    });
  }

  Future<void> _checkAndTriggerNotification(BuildContext context, WatchlistProvider watchlistProvider) async {
    final random = Random();
    final isQualityUpgrade = random.nextBool();

    if (isQualityUpgrade && watchlistProvider.items.isNotEmpty) {
      // Notify about a movie in watchlist
      final movie = watchlistProvider.items[random.nextInt(watchlistProvider.items.length)];
      _showInAppNotification(context, 'Quality Upgrade!', '${movie.title} is now available in 4K Blu-ray.');
    } else {
      // Notify about new trending
      try {
        final trends = await _tmdbService.getTrendingMovies();
        if (trends.isNotEmpty) {
          final topTrend = trends[0];
          _showInAppNotification(context, 'Trending Now 🍿', 'Everyone is watching ${topTrend.title}. Tap to check it out!');
        }
      } catch (e) {
        // Safe fail
      }
    }
  }

  void _showInAppNotification(BuildContext context, String title, String body) {
    if (!context.mounted) return;

    final snackBar = SnackBar(
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_active, color: Color(0xFFE50914), size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1E1E1E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.all(20),
      duration: const Duration(seconds: 4),
      elevation: 10,
      action: SnackBarAction(
        label: 'View',
        textColor: const Color(0xFFE50914),
        onPressed: () {
          // Action handled
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
