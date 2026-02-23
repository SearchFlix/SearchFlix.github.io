import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';

class FilterPanel extends StatefulWidget {
  final Map<String, dynamic> filters;
  final Function(Map<String, dynamic>) onFilterChanged;
  final VoidCallback onApply;

  const FilterPanel({
    super.key,
    required this.filters,
    required this.onFilterChanged,
    required this.onApply,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  final TMDBService _service = TMDBService();
  List<Map<String, dynamic>> _genres = [];
  final TextEditingController _actorController = TextEditingController();

  final List<Map<String, String>> _sortOptions = [
    {'value': 'popularity.desc', 'label': 'Most Popular'},
    {'value': 'revenue.desc', 'label': 'Top Box Office'},
    {'value': 'vote_average.desc', 'label': 'Top Rated'},
    {'value': 'primary_release_date.desc', 'label': 'Newest'},
  ];

  final List<Map<String, String>> _languages = [
    {'value': 'all', 'label': 'All Languages'},
    {'value': 'en', 'label': 'English'},
    {'value': 'fa', 'label': 'Persian'},
    {'value': 'fr', 'label': 'French'},
    {'value': 'es', 'label': 'Spanish'},
    {'value': 'ko', 'label': 'Korean'},
    {'value': 'ja', 'label': 'Japanese'},
  ];

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    final genres = await _service.getGenres();
    setState(() => _genres = genres);
  }

  void _updateFilter(String key, dynamic value) {
    final newFilters = Map<String, dynamic>.from(widget.filters);
    newFilters[key] = value;
    widget.onFilterChanged(newFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SEARCH FILTERS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFE50914), letterSpacing: 1.5)),
            const SizedBox(height: 25),

            // Sort By
            _sectionTitle('Sort By'),
            DropdownButtonFormField<String>(
              value: widget.filters['sortBy'] ?? 'popularity.desc',
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _inputDecoration(),
              items: _sortOptions.map((opt) => DropdownMenuItem(value: opt['value'], child: Text(opt['label']!))).toList(),
              onChanged: (v) => _updateFilter('sortBy', v),
            ),

            const SizedBox(height: 20),

            // Year
            _sectionTitle('Release Year'),
            DropdownButtonFormField<int>(
              value: widget.filters['year'],
              dropdownColor: const Color(0xFF1A1A1A),
              decoration: _inputDecoration(),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any Year')),
                ...List.generate(60, (i) => DateTime.now().year - i).map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))),
              ],
              onChanged: (v) => _updateFilter('year', v),
            ),

            const SizedBox(height: 20),

            // Actor Search
            _sectionTitle('Add Actor/Cast'),
            TextField(
              controller: _actorController,
              onSubmitted: (q) async {
                final results = await _service.searchActors(q);
                if (results.isNotEmpty) {
                  _showActorPicker(results);
                }
              },
              decoration: _inputDecoration(hint: 'Search actor...', icon: Icons.person_add),
            ),
            if ((widget.filters['actors'] as List).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 5,
                children: (widget.filters['actors'] as List).map((actor) => Chip(
                  label: Text(actor['name'], style: const TextStyle(fontSize: 10)),
                  onDeleted: () {
                    final list = List<Map<String, dynamic>>.from(widget.filters['actors']);
                    list.remove(actor);
                    _updateFilter('actors', list);
                  },
                  backgroundColor: const Color(0xFFE50914).withOpacity(0.3),
                )).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Language
            _sectionTitle('Language'),
            DropdownButtonFormField<String>(
              value: widget.filters['language'] ?? 'all',
              dropdownColor: const Color(0xFF1A1A1A),
              decoration: _inputDecoration(),
              items: _languages.map((l) => DropdownMenuItem(value: l['value'], child: Text(l['label']!))).toList(),
              onChanged: (v) => _updateFilter('language', v),
            ),

            const SizedBox(height: 20),

            // Genres
            _sectionTitle('Genres'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _genres.map((genre) {
                final isSelected = widget.filters['genreId'] == genre['id'].toString();
                return ChoiceChip(
                  label: Text(genre['name'], style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (val) => _updateFilter('genreId', val ? genre['id'].toString() : null),
                  selectedColor: const Color(0xFFE50914),
                  backgroundColor: Colors.white12,
                );
              }).toList(),
            ),

            const SizedBox(height: 25),

            // Rating
            _sectionTitle('Min Rating: ${widget.filters['minRating']}'),
            Slider(
              value: (widget.filters['minRating'] as num).toDouble(),
              min: 0, max: 10, divisions: 10,
              activeColor: const Color(0xFFE50914),
              onChanged: (val) => _updateFilter('minRating', val),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: widget.onApply,
                child: Text(Lang.of(context).searchNow.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70)),
    );
  }

  InputDecoration _inputDecoration({String? hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.white38) : null,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    );
  }

  void _showActorPicker(List<Map<String, dynamic>> actors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Add Actor to Filter'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: actors.take(5).length,
            itemBuilder: (context, index) {
              final actor = actors[index];
              return ListTile(
                title: Text(actor['name']),
                onTap: () {
                  final list = List<Map<String, dynamic>>.from(widget.filters['actors']);
                  if (!list.any((a) => a['id'] == actor['id'])) {
                    list.add(actor);
                    _updateFilter('actors', list);
                  }
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
}
