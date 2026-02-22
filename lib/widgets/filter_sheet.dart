import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';

class FilterSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApply;

  const FilterSheet({super.key, required this.currentFilters, required this.onApply});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  final TMDBService _service = TMDBService();
  List<Map<String, dynamic>> _genres = [];
  List<Map<String, dynamic>> _selectedActors = [];
  final TextEditingController _actorController = TextEditingController();
  
  String? _selectedGenreId;
  double _minRating = 0;
  int? _selectedYear;
  
  @override
  void initState() {
    super.initState();
    _selectedGenreId = widget.currentFilters['genreId'];
    _minRating = widget.currentFilters['minRating'] ?? 0;
    _selectedYear = widget.currentFilters['year'];
    _selectedActors = List<Map<String, dynamic>>.from(widget.currentFilters['actors'] ?? []);
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    final genres = await _service.getGenres();
    setState(() => _genres = genres);
  }

  Future<void> _searchActors(String query) async {
    if (query.length < 3) return;
    final results = await _service.searchActors(query);
    if (results.isNotEmpty) {
      _showActorPicker(results);
    }
  }

  void _showActorPicker(List<Map<String, dynamic>> actors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Select Actor'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: actors.length,
            itemBuilder: (context, index) {
              final actor = actors[index];
              return ListTile(
                leading: actor['profile_path'] != null 
                  ? CircleAvatar(backgroundImage: NetworkImage('https://image.tmdb.org/t/p/w200${actor['profile_path']}'))
                  : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(actor['name']),
                onTap: () {
                  setState(() {
                    if (!_selectedActors.any((a) => a['id'] == actor['id'])) {
                      _selectedActors.add(actor);
                    }
                  });
                  Navigator.pop(context);
                  _actorController.clear();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 25, left: 25, right: 25, top: 25),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Advanced Filters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 20),
            
            const Text('Search Actor', style: TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 10),
            TextField(
              controller: _actorController,
              onSubmitted: _searchActors,
              decoration: InputDecoration(
                hintText: 'Type actor name and press enter...',
                prefixIcon: const Icon(Icons.person_search),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            if (_selectedActors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                children: _selectedActors.map((actor) => Chip(
                  label: Text(actor['name']),
                  onDeleted: () => setState(() => _selectedActors.remove(actor)),
                  deleteIconColor: Colors.white,
                  backgroundColor: const Color(0xFFE50914),
                )).toList(),
              ),
            ),

            const SizedBox(height: 25),
            const Text('Release Year', style: TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: _selectedYear,
              dropdownColor: const Color(0xFF1A1A1A),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              items: List.generate(50, (i) => 2026 - i).map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
              onChanged: (v) => setState(() => _selectedYear = v),
              hint: const Text('Select Year'),
            ),
            
            const SizedBox(height: 25),
            const Text('Genres', style: TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 10),
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _genres.length,
                itemBuilder: (context, index) {
                  final genre = _genres[index];
                  final isSelected = _selectedGenreId == genre['id'].toString();
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: FilterChip(
                      label: Text(genre['name']),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _selectedGenreId = val ? genre['id'].toString() : null),
                      selectedColor: const Color(0xFFE50914),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 25),
            const Text('Minimum Rating', style: TextStyle(fontSize: 16, color: Colors.white70)),
            Slider(
              value: _minRating,
              min: 0, max: 10, divisions: 10,
              activeColor: const Color(0xFFE50914),
              label: _minRating.toString(),
              onChanged: (val) => setState(() => _minRating = val),
            ),
            
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () {
                  widget.onApply({
                    'genreId': _selectedGenreId,
                    'minRating': _minRating,
                    'year': _selectedYear,
                    'actors': _selectedActors,
                  });
                  Navigator.pop(context);
                },
                child: const Text('Apply Global Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
