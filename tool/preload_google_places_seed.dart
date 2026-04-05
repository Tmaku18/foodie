import 'dart:io';

import 'package:foodie/data/import/google_places_import_service.dart';

const _defaultOutputPath = 'lib/data/seed/generated_google_places_seed.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final apiKeyArg = _readStringArg(args, '--api-key');
  final outputPath = _readStringArg(args, '--out') ?? _defaultOutputPath;
  final maxResultsArg = _readStringArg(args, '--max-results');

  final apiKey =
      (apiKeyArg ?? Platform.environment['GOOGLE_MAPS_API_KEY'] ?? '').trim();
  if (apiKey.isEmpty) {
    stderr.writeln('Missing API key.');
    stderr.writeln(
      'Pass --api-key=YOUR_KEY or set GOOGLE_MAPS_API_KEY in your environment.',
    );
    exitCode = 64;
    return;
  }

  final maxResults = int.tryParse(maxResultsArg ?? '') ?? 20;
  if (maxResults <= 0) {
    stderr.writeln(
      'Invalid --max-results value. It must be a positive integer.',
    );
    exitCode = 64;
    return;
  }

  final importService = GooglePlacesImportService(apiKey: apiKey);
  final places = await importService.fetchNearbyRestaurants(
    maxResultCount: maxResults,
  );
  places.sort((a, b) {
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (byName != 0) return byName;
    return a.externalPlaceId.compareTo(b.externalPlaceId);
  });

  final outputFile = File(outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(_buildSeedFileContent(places), flush: true);

  stdout.writeln(
    'Wrote ${places.length} generated Google Places restaurants to ${outputFile.path}.',
  );
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
  stdout.writeln(
    'Usage: dart run tool/preload_google_places_seed.dart [options]',
  );
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln(
    '  --api-key=KEY        Google Maps Places API key (optional if env var is set)',
  );
  stdout.writeln('  --max-results=NUM    Max places to request (default: 20)');
  stdout.writeln(
    '  --out=PATH           Output file path (default: $_defaultOutputPath)',
  );
  stdout.writeln('  --help, -h           Show this help text');
  stdout.writeln('');
  stdout.writeln('Environment fallback: GOOGLE_MAPS_API_KEY');
}

String _buildSeedFileContent(List<ImportedRestaurantRecord> places) {
  final buffer = StringBuffer()
    ..writeln('// GENERATED FILE - DO NOT EDIT BY HAND.')
    ..writeln(
      '// Regenerate with: dart run tool/preload_google_places_seed.dart',
    )
    ..writeln("import 'package:foodie/core/models.dart';")
    ..writeln('')
    ..writeln('const generatedGooglePlacesRestaurants = <Restaurant>[');

  for (final place in places) {
    final id = _stableIntId(place.externalPlaceId);
    buffer
      ..writeln('  Restaurant(')
      ..writeln('    id: $id,')
      ..writeln("    name: '${_escapeDartString(place.name)}',")
      ..writeln("    category: '${_escapeDartString(place.category)}',")
      ..writeln('    distanceMiles: ${place.distanceMiles.toStringAsFixed(3)},')
      ..writeln('    rating: ${place.rating.toStringAsFixed(1)},')
      ..writeln(
        "    buildingImageAsset: 'assets/images/restaurant_building.png',",
      )
      ..writeln(
        "    foodImageAssets: ['assets/images/food_1.png', 'assets/images/food_2.png', 'assets/images/food_3.png'],",
      )
      ..writeln('  ),');
  }

  buffer
    ..writeln('];')
    ..writeln('');

  return buffer.toString();
}

String _escapeDartString(String input) {
  return input.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
}

int _stableIntId(String value) {
  var hash = 0;
  for (final codeUnit in value.codeUnits) {
    hash = ((hash * 31) + codeUnit) & 0x7fffffff;
  }
  return hash;
}
