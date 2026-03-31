import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodie/core/di/injection.dart';
import 'package:foodie/core/services/file_export_service.dart';
import 'package:foodie/features/basket/presentation/cubit/basket_cubit.dart';

class BasketPage extends StatelessWidget {
  const BasketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BasketCubit, BasketState>(
      builder: (context, state) {
        final exportService = getIt<FileExportService>();
        return Scaffold(
          appBar: AppBar(title: const Text('Basket Matches')),
          body: state.loading
              ? const Center(child: CircularProgressIndicator())
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: state.matches.isEmpty
                      ? const Center(key: ValueKey('empty'), child: Text('No matches yet'))
                      : ListView(
                          key: const ValueKey('list'),
                          children: [
                            for (final item in state.matches)
                              ListTile(
                                title: Text('Restaurant #${item.restaurantId}'),
                                subtitle: Text(item.createdAt.toIso8601String()),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => context.read<BasketCubit>().removeMatch(item.id),
                                ),
                              ),
                          ],
                        ),
                ),
          floatingActionButton: state.matches.isEmpty
              ? null
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: 'emptyBasket',
                      onPressed: () => context.read<BasketCubit>().emptyBasket(),
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Empty Basket'),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.extended(
                      heroTag: 'exportBasket',
                      onPressed: () async {
                        final jsonFile = await exportService.exportJson('basket_export', {
                          'matches': state.matches
                              .map((e) => {'id': e.id, 'restaurantId': e.restaurantId, 'createdAt': e.createdAt.toIso8601String()})
                              .toList()
                        });
                        final csvFile = await exportService.exportCsv(
                          'basket_export',
                          [
                            ['id', 'restaurantId', 'createdAt'],
                            ...state.matches.map((m) => [m.id.toString(), m.restaurantId.toString(), m.createdAt.toIso8601String()]),
                          ],
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Exported to ${jsonFile.path} and ${csvFile.path}')),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Export JSON/CSV'),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
