import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../widgets/movie_card.dart';

class ActorScreen extends StatefulWidget {
  final int actorId;
  final String actorName;

  const ActorScreen({super.key, required this.actorId, required this.actorName});

  @override
  State<ActorScreen> createState() => _ActorScreenState();
}

class _ActorScreenState extends State<ActorScreen> {
  final TMDBService _service = TMDBService();
  Map<String, dynamic>? _details;
  List<Movie> _movies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final details = await _service.getPersonDetails(widget.actorId);
      final movies = await _service.getActorMovies(widget.actorId);
      if (mounted) {
        setState(() {
          _details = details;
          _movies = movies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.actorName, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CachedNetworkImage(
                          imageUrl: _details?['profile_path'] != null 
                            ? 'https://image.tmdb.org/t/p/w300${_details?['profile_path']}' 
                            : 'https://via.placeholder.com/300x450?text=No+Photo',
                          width: 150,
                          height: 225,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Biography', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text(
                              _details?['biography']?.isNotEmpty == true 
                                ? _details!['biography'] 
                                : 'No biography available for this actor.',
                              maxLines: 8,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text('Known For', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => MovieCard(
                      movie: _movies[index],
                      onTap: () => context.push('/movie/${_movies[index].id}', extra: _movies[index]),
                    ),
                    childCount: _movies.length,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
