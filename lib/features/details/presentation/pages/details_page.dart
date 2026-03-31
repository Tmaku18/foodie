import 'package:flutter/material.dart';
import 'package:foodie/core/models.dart';
import 'package:foodie/core/di/injection.dart';
import 'package:foodie/domain/repositories/food_repository.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final _repo = getIt<FoodRepository>();
  final _noteController = TextEditingController();
  List<MenuItem> _menu = const [];
  List<ReviewNote> _notes = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final menu = await _repo.getMenuByRestaurant(widget.restaurant.id);
    final notes = await _repo.getNotes(widget.restaurant.id);
    if (!mounted) return;
    setState(() {
      _menu = menu;
      _notes = notes;
      _loading = false;
      if (_notes.isNotEmpty) {
        _noteController.text = _notes.first.text;
      }
    });
  }

  Future<void> _saveNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    await _repo.upsertNote(widget.restaurant.id, text);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.restaurant.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Menu', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                for (final item in _menu.take(8))
                  ListTile(
                    title: Text(item.name),
                    subtitle: Text(item.description),
                    trailing: Text('\$${item.price.toStringAsFixed(2)}'),
                  ),
                const Divider(),
                Text('Your notes/review', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                FilledButton(onPressed: _saveNote, child: const Text('Save note')),
              ],
            ),
    );
  }
}
