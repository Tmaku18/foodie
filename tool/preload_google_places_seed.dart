import 'dart:io';

import 'package:foodie/data/import/google_places_import_service.dart';
import 'package:http/http.dart' as http;

const _defaultOutputPath = 'lib/data/seed/generated_google_places_seed.dart';
const _defaultImagesDirectory = 'assets/images';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final apiKeyArg = _readStringArg(args, '--api-key');
  final outputPath = _readStringArg(args, '--out') ?? _defaultOutputPath;
  final imagesDirectoryPath =
      _readStringArg(args, '--images-dir') ?? _defaultImagesDirectory;
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

  final imageResolver = _PlacePhotoAssetResolver(
    apiKey: apiKey,
    imagesDirectoryPath: imagesDirectoryPath,
  );
  await imageResolver.prepare();

  final outputFile = File(outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(
    await _buildSeedFileContent(places, imageResolver),
    flush: true,
  );

  stdout.writeln(
    'Wrote ${places.length} generated Google Places restaurants to ${outputFile.path} '
    'with downloaded image assets in ${imageResolver.imagesDirectory.path}.',
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
  stdout.writeln(
    '  --images-dir=PATH    Image output directory (default: $_defaultImagesDirectory)',
  );
  stdout.writeln('  --help, -h           Show this help text');
  stdout.writeln('');
  stdout.writeln('Environment fallback: GOOGLE_MAPS_API_KEY');
}

Future<String> _buildSeedFileContent(
  List<ImportedRestaurantRecord> places,
  _PlacePhotoAssetResolver imageResolver,
) async {
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
    final assets = await imageResolver.resolveAssetsForPlace(place);
    final foodImageAssetsCsv = assets.foodImageAssets
        .map((asset) => "'${_escapeDartString(asset)}'")
        .join(', ');
    buffer
      ..writeln('  Restaurant(')
      ..writeln('    id: $id,')
      ..writeln("    name: '${_escapeDartString(place.name)}',")
      ..writeln("    category: '${_escapeDartString(place.category)}',")
      ..writeln('    distanceMiles: ${place.distanceMiles.toStringAsFixed(3)},')
      ..writeln('    rating: ${place.rating.toStringAsFixed(1)},')
      ..writeln(
        "    buildingImageAsset: '${_escapeDartString(assets.buildingImageAsset)}',",
      )
      ..writeln('    foodImageAssets: [$foodImageAssetsCsv],')
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

class _ResolvedImageAssets {
  const _ResolvedImageAssets({
    required this.buildingImageAsset,
    required this.foodImageAssets,
  });

  final String buildingImageAsset;
  final List<String> foodImageAssets;
}

class _PlacePhotoAssetResolver {
  _PlacePhotoAssetResolver({
    required this.apiKey,
    required String imagesDirectoryPath,
  }) : imagesDirectory = Directory(imagesDirectoryPath);

  final String apiKey;
  final Directory imagesDirectory;
  final http.Client _client = http.Client();
  final Map<String, String> _downloadedPhotoAssetByName = <String, String>{};

  Future<void> prepare() async {
    await imagesDirectory.create(recursive: true);
    final staleGenerated = imagesDirectory.listSync().whereType<File>().where(
      (file) => file.uri.pathSegments.last.startsWith('gp_'),
    );
    for (final file in staleGenerated) {
      await file.delete();
    }
  }

  Future<_ResolvedImageAssets> resolveAssetsForPlace(
    ImportedRestaurantRecord place,
  ) async {
    final photoNames = place.photoNames.take(3).toList(growable: false);
    if (photoNames.isEmpty) {
      const fallback = 'assets/images/restaurant_building.png';
      return const _ResolvedImageAssets(
        buildingImageAsset: fallback,
        foodImageAssets: <String>[fallback, fallback, fallback],
      );
    }

    final downloadedAssets = <String>[];
    for (var i = 0; i < photoNames.length; i++) {
      final assetPath = await _downloadPhotoAsset(
        photoName: photoNames[i],
        placeExternalId: place.externalPlaceId,
        slot: i,
      );
      if (assetPath != null) {
        downloadedAssets.add(assetPath);
      }
    }

    if (downloadedAssets.isEmpty) {
      const fallback = 'assets/images/restaurant_building.png';
      return const _ResolvedImageAssets(
        buildingImageAsset: fallback,
        foodImageAssets: <String>[fallback, fallback, fallback],
      );
    }

    final buildingImageAsset = downloadedAssets.first;
    final foodImageAssets = <String>[
      ...downloadedAssets,
      for (var i = downloadedAssets.length; i < 3; i++) buildingImageAsset,
    ].take(3).toList(growable: false);

    return _ResolvedImageAssets(
      buildingImageAsset: buildingImageAsset,
      foodImageAssets: foodImageAssets,
    );
  }

  Future<String?> _downloadPhotoAsset({
    required String photoName,
    required String placeExternalId,
    required int slot,
  }) async {
    final cached = _downloadedPhotoAssetByName[photoName];
    if (cached != null) return cached;

    final uri = Uri.https(
      'places.googleapis.com',
      '/v1/$photoName/media',
      <String, String>{
        'maxWidthPx': '960',
        'maxHeightPx': '720',
        'key': apiKey,
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final contentType = response.headers['content-type'] ?? '';
    final extension = _fileExtensionFromContentType(contentType);
    final fileName = 'gp_${_stableIntId(placeExternalId)}_$slot.$extension';
    final outputPath = '${imagesDirectory.path}/$fileName';
    final imageFile = File(outputPath);
    await imageFile.writeAsBytes(response.bodyBytes, flush: true);

    final assetPath = outputPath.replaceAll(r'\', '/');
    _downloadedPhotoAssetByName[photoName] = assetPath;
    return assetPath;
  }

  String _fileExtensionFromContentType(String contentType) {
    if (contentType.contains('image/png')) return 'png';
    if (contentType.contains('image/webp')) return 'webp';
    return 'jpg';
  }
}
