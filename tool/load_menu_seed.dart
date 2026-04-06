import 'dart:convert';
import 'dart:io';

import 'package:foodie/core/models.dart';
import 'package:foodie/data/seed/generated_google_places_seed.dart';
import 'package:foodie/data/seed/seed_data.dart';

const _defaultInputPath = 'data/menu_seed.json';
const _defaultOutputPath = 'lib/data/seed/generated_menu_items_seed.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final inputPath = _readStringArg(args, '--input') ?? _defaultInputPath;
  final outputPath = _readStringArg(args, '--out') ?? _defaultOutputPath;

  final inputFile = File(inputPath);
  if (!await inputFile.exists()) {
    stderr.writeln('Input file not found: $inputPath');
    stderr.writeln('Create it with a JSON array of restaurant menu records.');
    exitCode = 64;
    return;
  }

  final raw = await inputFile.readAsString();
  final decoded = jsonDecode(raw);
  if (decoded is! List<dynamic>) {
    stderr.writeln('Invalid JSON format. Root must be an array.');
    exitCode = 64;
    return;
  }

  final restaurantsByName = _buildRestaurantIdByName();
  final generated = <MenuItem>[];
  var nextMenuItemId = 1000000;

  for (final entry in decoded) {
    if (entry is! Map<String, dynamic>) continue;
    final restaurantName = (entry['restaurantName'] as String?)?.trim() ?? '';
    if (restaurantName.isEmpty) continue;
    final restaurantId = restaurantsByName[restaurantName.toLowerCase()];
    if (restaurantId == null) {
      stderr.writeln('Skipping unknown restaurant name: $restaurantName');
      continue;
    }

    final items = (entry['items'] as List<dynamic>? ?? const <dynamic>[]);
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final name = (item['name'] as String?)?.trim() ?? '';
      final description = (item['description'] as String?)?.trim() ?? '';
      final price = (item['price'] as num?)?.toDouble();
      if (name.isEmpty || description.isEmpty || price == null) {
        continue;
      }
      generated.add(
        MenuItem(
          id: nextMenuItemId,
          restaurantId: restaurantId,
          name: name,
          price: price,
          description: description,
        ),
      );
      nextMenuItemId += 1;
    }
  }

  final outputFile = File(outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(
    _buildGeneratedMenuSeedFile(generated),
    flush: true,
  );

  stdout.writeln('Wrote ${generated.length} menu items to ${outputFile.path}.');
}

Map<String, int> _buildRestaurantIdByName() {
  final allRestaurants = <Restaurant>[
    ...demoRestaurants,
    ...generatedGooglePlacesRestaurants,
  ];
  final result = <String, int>{};
  for (final restaurant in allRestaurants) {
    result[restaurant.name.toLowerCase()] = restaurant.id;
  }
  return result;
}

String _buildGeneratedMenuSeedFile(List<MenuItem> items) {
  final buffer = StringBuffer()
    ..writeln('// GENERATED FILE - DO NOT EDIT BY HAND.')
    ..writeln('// Regenerate with: dart run tool/load_menu_seed.dart')
    ..writeln("import 'package:foodie/core/models.dart';")
    ..writeln('')
    ..writeln('const generatedMenuItems = <MenuItem>[');

  for (final item in items) {
    buffer
      ..writeln('  MenuItem(')
      ..writeln('    id: ${item.id},')
      ..writeln('    restaurantId: ${item.restaurantId},')
      ..writeln("    name: '${_escapeDartString(item.name)}',")
      ..writeln('    price: ${item.price.toStringAsFixed(2)},')
      ..writeln("    description: '${_escapeDartString(item.description)}',")
      ..writeln('  ),');
  }

  buffer
    ..writeln('];')
    ..writeln('');

  return buffer.toString();
}

String _escapeDartString(String input) {
  return input
      .replaceAll(r'\', r'\\')
      .replaceAll(r'$', r'\$')
      .replaceAll("'", r"\'");
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
  stdout.writeln('Usage: dart run tool/load_menu_seed.dart [options]');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln(
    '  --input=PATH         Menu JSON input file (default: $_defaultInputPath)',
  );
  stdout.writeln(
    '  --out=PATH           Dart output file (default: $_defaultOutputPath)',
  );
  stdout.writeln('  --help, -h           Show this help text');
  stdout.writeln('');
  stdout.writeln('Input JSON format:');
  stdout.writeln(
    '[{"restaurantName":"Barcelona Wine Bar","items":[{"name":"Patatas Bravas","price":8.99,"description":"Crispy potatoes"}]}]',
  );
}
