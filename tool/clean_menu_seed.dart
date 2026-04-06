import 'dart:convert';
import 'dart:io';

import 'menu_seed_filters.dart';

const _defaultPath = 'data/menu_seed.json';
const _defaultOverridesPath = 'data/menu_price_overrides.json';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final inputPath = _readStringArg(args, '--input') ?? _defaultPath;
  final outArg = _readStringArg(args, '--out');
  final outputPath = outArg ?? inputPath;
  final overridesPath =
      _readStringArg(args, '--overrides') ?? _defaultOverridesPath;

  final inputFile = File(inputPath);
  if (!await inputFile.exists()) {
    stderr.writeln('Input file not found: $inputPath');
    exitCode = 64;
    return;
  }

  final raw = await inputFile.readAsString();
  final decoded = jsonDecode(raw);
  if (decoded is! List<dynamic>) {
    stderr.writeln('Invalid JSON. Root must be an array.');
    exitCode = 64;
    return;
  }
  final overridesByRestaurant = await _loadOverridesByRestaurant(overridesPath);

  var totalBefore = 0;
  var totalAfter = 0;
  var totalOverridesUpdated = 0;
  var totalOverridesInserted = 0;
  final out = <Map<String, dynamic>>[];

  for (final entry in decoded) {
    if (entry is! Map<String, dynamic>) continue;
    final name = (entry['restaurantName'] as String?)?.trim() ?? '';
    if (name.isEmpty) continue;

    final itemsRaw = entry['items'] as List<dynamic>? ?? const [];
    final kept = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final item in itemsRaw) {
      if (item is! Map<String, dynamic>) continue;
      totalBefore++;
      if (!isValidMenuSeedItem(item)) continue;

      final desc = (item['description'] as String?)?.trim();
      final priceVal = item['price'];
      final price = priceVal is num
          ? priceVal.toDouble()
          : double.tryParse(priceVal?.toString() ?? '');
      if (price == null) continue;

      final itemName = cleanMenuItemText(item['name'] as String);
      final key = itemName.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);

      kept.add(<String, dynamic>{
        'name': itemName,
        'price': double.parse(price.toStringAsFixed(2)),
        'description': (desc != null && desc.isNotEmpty)
            ? desc
            : 'Imported from restaurant website.',
      });
    }
    final overrideStats = _applyOverrides(
      restaurantName: name,
      items: kept,
      overridesByRestaurant: overridesByRestaurant,
    );
    totalOverridesUpdated += overrideStats.updated;
    totalOverridesInserted += overrideStats.inserted;
    totalAfter += kept.length;

    out.add(<String, dynamic>{
      'restaurantName': name,
      'items': kept,
    });
  }

  final outputFile = File(outputPath);
  await outputFile.parent.create(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  await outputFile.writeAsString(encoder.convert(out), flush: true);

  stdout.writeln(
    'Wrote ${out.length} restaurants to $outputPath '
    '($totalAfter / $totalBefore items kept, '
    '$totalOverridesUpdated prices updated, '
    '$totalOverridesInserted items inserted via overrides).',
  );
}

Future<Map<String, List<_MenuPriceOverride>>> _loadOverridesByRestaurant(
  String path,
) async {
  final file = File(path);
  if (!await file.exists()) {
    stdout.writeln('Override file not found: $path (continuing without overrides).');
    return const {};
  }

  final raw = await file.readAsString();
  final decoded = jsonDecode(raw);
  final entries = switch (decoded) {
    List<dynamic>() => decoded,
    Map<String, dynamic>() => decoded['restaurants'] as List<dynamic>? ?? const [],
    _ => const <dynamic>[],
  };
  final result = <String, List<_MenuPriceOverride>>{};
  for (final entry in entries) {
    if (entry is! Map<String, dynamic>) continue;
    final restaurantName = (entry['restaurantName'] as String?)?.trim() ?? '';
    if (restaurantName.isEmpty) continue;
    final items = entry['items'] as List<dynamic>? ?? const [];
    final overrides = <_MenuPriceOverride>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final itemName = cleanMenuItemText((item['name'] as String?) ?? '');
      if (itemName.isEmpty) continue;
      final priceValue = item['price'];
      final price = priceValue is num
          ? priceValue.toDouble()
          : double.tryParse(priceValue?.toString() ?? '');
      if (price == null || !looksLikeReasonablePrice(price)) continue;
      final description = (item['description'] as String?)?.trim();
      final setName = (item['setName'] as String?)?.trim();
      final addIfMissing = item['addIfMissing'] is bool
          ? item['addIfMissing'] as bool
          : true;
      overrides.add(
        _MenuPriceOverride(
          name: itemName,
          price: price,
          description: description,
          setName: setName,
          addIfMissing: addIfMissing,
        ),
      );
    }
    if (overrides.isNotEmpty) {
      result[restaurantName.toLowerCase()] = overrides;
    }
  }
  return result;
}

_OverrideStats _applyOverrides({
  required String restaurantName,
  required List<Map<String, dynamic>> items,
  required Map<String, List<_MenuPriceOverride>> overridesByRestaurant,
}) {
  final overrides = overridesByRestaurant[restaurantName.toLowerCase()];
  if (overrides == null || overrides.isEmpty) {
    return const _OverrideStats(updated: 0, inserted: 0);
  }

  final indexByName = <String, int>{};
  for (var i = 0; i < items.length; i++) {
    final name = items[i]['name'];
    if (name is String) {
      indexByName[_normalizeNameForMatch(name)] = i;
    }
  }

  var updated = 0;
  var inserted = 0;
  for (final override in overrides) {
    final overrideKey = _normalizeNameForMatch(override.name);
    final existingIndex = indexByName[overrideKey];
    final resolvedName =
        cleanMenuItemText((override.setName?.isNotEmpty ?? false) ? override.setName! : override.name);
    if (existingIndex != null) {
      final target = items[existingIndex];
      target['price'] = double.parse(override.price.toStringAsFixed(2));
      if (override.description != null && override.description!.isNotEmpty) {
        target['description'] = override.description;
      }
      if (resolvedName.isNotEmpty && looksLikeMenuItemName(resolvedName)) {
        target['name'] = resolvedName;
      }
      updated += 1;
      continue;
    }

    if (!override.addIfMissing) continue;
    if (!looksLikeMenuItemName(resolvedName)) continue;
    if (indexByName.containsKey(_normalizeNameForMatch(resolvedName))) continue;
    items.add(
      <String, dynamic>{
        'name': resolvedName,
        'price': double.parse(override.price.toStringAsFixed(2)),
        'description': (override.description?.isNotEmpty ?? false)
            ? override.description
            : 'Manual price override.',
      },
    );
    indexByName[_normalizeNameForMatch(resolvedName)] = items.length - 1;
    inserted += 1;
  }
  return _OverrideStats(updated: updated, inserted: inserted);
}

String _normalizeNameForMatch(String value) {
  final lower = cleanMenuItemText(value).toLowerCase();
  return lower.replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

class _MenuPriceOverride {
  const _MenuPriceOverride({
    required this.name,
    required this.price,
    required this.description,
    required this.setName,
    required this.addIfMissing,
  });

  final String name;
  final double price;
  final String? description;
  final String? setName;
  final bool addIfMissing;
}

class _OverrideStats {
  const _OverrideStats({
    required this.updated,
    required this.inserted,
  });

  final int updated;
  final int inserted;
}

String? _readStringArg(List<String> args, String key) {
  final prefix = '$key=';
  for (final arg in args) {
    if (arg.startsWith(prefix)) {
      return arg.substring(prefix.length).trim();
    }
  }
  return null;
}

void _printUsage() {
  stdout.writeln('Usage: dart run tool/clean_menu_seed.dart [options]');
  stdout.writeln('');
  stdout.writeln('Filters junk rows from menu_seed.json using the same rules as');
  stdout.writeln('tool/load_menu_from_websites.dart (name/price/junk heuristics).');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln('  --input=PATH   Input JSON (default: $_defaultPath)');
  stdout.writeln(
    '  --out=PATH     Output JSON (default: same as --input, overwrite)',
  );
  stdout.writeln(
    '  --overrides=PATH  Manual override JSON (default: $_defaultOverridesPath)',
  );
  stdout.writeln('  --help, -h     Show this help');
  stdout.writeln('');
  stdout.writeln('Override JSON format:');
  stdout.writeln('[{"restaurantName":"Hungry AF Downtown","items":[');
  stdout.writeln('  {"name":"6pc Wing w/ Fries","price":12.99,"addIfMissing":true},');
  stdout.writeln('  {"name":"10pc Wings w/ Fries","price":17.99,"setName":"10pc Wings w/ Fries"}');
  stdout.writeln(']}]');
  stdout.writeln('');
  stdout.writeln('Typical pipeline:');
  stdout.writeln('  dart run tool/load_menu_from_websites.dart');
  stdout.writeln('  dart run tool/clean_menu_seed.dart');
  stdout.writeln('  dart run tool/load_menu_seed.dart');
}
