import 'package:flutter/material.dart';
import '../widgets/glass_box.dart';
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
  String? _selectedGenreId;
  double _minRating = 0;
  int? _selectedYear;
  
  @override
  void initState() {
    super.initState();
    _selectedGenreId = widget.currentFilters['genreId'];
    _minRating = widget.currentFilters['minRating'] ?? 0;
    _selectedYear = widget.currentFilters['year'];
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    final genres = await _service.getGenres();
    setState(() => _genres = genres);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Advance Filters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 20),
          
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
                    onSelected: (val) {
                      setState(() => _selectedGenreId = val ? genre['id'].toString() : null);
                    },
                    selectedColor: const Color(0xFFE50914),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 25),
          const Text('Minimum Rating', style: TextStyle(fontSize: 16, color: Colors.white70)),
          Slider(
            value: _minRating,
            min: 0,
            max: 10,
            divisions: 10,
            activeColor: const Color(0xFFE50914),
            label: _minRating.toString(),
            onChanged: (val) => setState(() => _minRating = val),
          ),
          
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () {
                widget.onApply({
                  'genreId': _selectedGenreId,
                  'minRating': _minRating,
                  'year': _selectedYear,
                });
                Navigator.pop(context);
              },
              child: const Text('Apply Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
