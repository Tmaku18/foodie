import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'package:foodie/core/config/places_import_config.dart';

class ImportedRestaurantRecord {
  const ImportedRestaurantRecord({
    required this.externalPlaceId,
    required this.name,
    required this.category,
    required this.distanceMiles,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.addressText,
    required this.source,
  });

  final String externalPlaceId;
  final String name;
  final String category;
  final double distanceMiles;
  final double rating;
  final double latitude;
  final double longitude;
  final String addressText;
  final String source;
}

class GooglePlacesImportService {
  GooglePlacesImportService({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _apiKey = apiKey;

  final http.Client _client;
  final String? _apiKey;

  static const _nearbySearchUrl = 'https://places.googleapis.com/v1/places:searchNearby';

  Future<List<ImportedRestaurantRecord>> fetchNearbyRestaurants({
    int maxResultCount = 20,
  }) async {
    final apiKey = _apiKey ?? const String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (apiKey.isEmpty) {
      throw StateError('Missing GOOGLE_MAPS_API_KEY. Pass --dart-define=GOOGLE_MAPS_API_KEY=your_key');
    }

    final requestBody = jsonEncode({
      'includedTypes': ['restaurant'],
      'maxResultCount': maxResultCount,
      'locationRestriction': {
        'circle': {
          'center': {
            'latitude': PlacesImportConfig.gsuStudentCenterEastLat,
            'longitude': PlacesImportConfig.gsuStudentCenterEastLng,
          },
          'radius': PlacesImportConfig.twoMilesInMeters,
        },
      },
    });

    final response = await _client.post(
      Uri.parse(_nearbySearchUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask':
            'places.id,places.displayName,places.types,places.rating,places.location,places.formattedAddress',
      },
      body: requestBody,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Google Places request failed (${response.statusCode}): ${response.body}');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final places = (payload['places'] as List<dynamic>? ?? const <dynamic>[]);
    return places
        .whereType<Map<String, dynamic>>()
        .map(_mapPlaceToRecord)
        .where((item) => item.distanceMiles <= 2.0)
        .toList(growable: false);
  }

  ImportedRestaurantRecord _mapPlaceToRecord(Map<String, dynamic> place) {
    final location = (place['location'] as Map<String, dynamic>? ?? const <String, dynamic>{});
    final lat = (location['latitude'] as num?)?.toDouble() ?? PlacesImportConfig.gsuStudentCenterEastLat;
    final lng = (location['longitude'] as num?)?.toDouble() ?? PlacesImportConfig.gsuStudentCenterEastLng;
    final types = (place['types'] as List<dynamic>? ?? const <dynamic>[]).whereType<String>().toList(growable: false);
    final rating = (place['rating'] as num?)?.toDouble() ?? 4.0;
    final displayName = (place['displayName'] as Map<String, dynamic>? ?? const <String, dynamic>{});
    final name = (displayName['text'] as String?)?.trim();
    final externalId = (place['id'] as String?)?.trim();
    if (name == null || name.isEmpty || externalId == null || externalId.isEmpty) {
      throw StateError('Invalid place payload: missing display name or id.');
    }

    return ImportedRestaurantRecord(
      externalPlaceId: externalId,
      name: name,
      category: _resolveCategory(types),
      distanceMiles: _distanceMilesFromCenter(lat: lat, lng: lng),
      rating: rating,
      latitude: lat,
      longitude: lng,
      addressText: (place['formattedAddress'] as String?)?.trim() ?? '',
      source: PlacesImportConfig.sourceGooglePlaces,
    );
  }

  String _resolveCategory(List<String> types) {
    if (types.isEmpty) return 'Restaurant';
    final primary = types.first;
    return primary
        .split('_')
        .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  double _distanceMilesFromCenter({required double lat, required double lng}) {
    const earthRadiusMiles = 3958.8;
    final dLat = _degToRad(lat - PlacesImportConfig.gsuStudentCenterEastLat);
    final dLng = _degToRad(lng - PlacesImportConfig.gsuStudentCenterEastLng);
    final startLat = _degToRad(PlacesImportConfig.gsuStudentCenterEastLat);
    final endLat = _degToRad(lat);

    final a = pow(sin(dLat / 2), 2) + cos(startLat) * cos(endLat) * pow(sin(dLng / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMiles * c;
  }

  double _degToRad(double deg) => deg * (pi / 180.0);
}
