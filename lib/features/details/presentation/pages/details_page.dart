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

  Future<void> _deleteNote(int noteId) async {
    await _repo.deleteNote(noteId);
    _noteController.clear();
    await _load();
  }

  bool _isPlaceholderPrice(MenuItem item) {
    return item.description.contains('Placeholder price estimate (*)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.restaurant.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Menu',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _menu[index];
                        final placeholder = _isPlaceholderPrice(item);
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text(item.description),
                          trailing: Text(
                            '\$${item.price.toStringAsFixed(2)}${placeholder ? '*' : ''}',
                          ),
                        );
                      },
                      childCount: _menu.length,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(),
                        Text(
                          'Your notes/review',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _saveNote,
                          child: const Text('Save note'),
                        ),
                        if (_notes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Saved notes',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          for (final note in _notes)
                            ListTile(
                              title: Text(note.text),
                              subtitle: Text(
                                'Updated ${note.updatedAt.toLocal()}',
                              ),
                              trailing: IconButton(
                                onPressed: () => _deleteNote(note.id),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
