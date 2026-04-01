import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:foodie/data/import/google_places_import_service.dart';

void main() {
  group('GooglePlacesImportService', () {
    test('maps valid places response into imported records', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), contains('places:searchNearby'));
        final payload = jsonEncode({
          'places': [
            {
              'id': 'abc123',
              'displayName': {'text': 'Peachtree Grill'},
              'types': ['american_restaurant'],
              'rating': 4.6,
              'location': {'latitude': 33.7528, 'longitude': -84.3864},
              'formattedAddress': '123 Peachtree St NE, Atlanta, GA',
            }
          ]
        });
        return http.Response(payload, 200);
      });

      final service = GooglePlacesImportService(client: client, apiKey: 'test-key');
      final results = await service.fetchNearbyRestaurants();

      expect(results, hasLength(1));
      expect(results.first.name, 'Peachtree Grill');
      expect(results.first.externalPlaceId, 'abc123');
      expect(results.first.distanceMiles, lessThanOrEqualTo(2.0));
      expect(results.first.source, 'google_places');
    });

    test('filters out restaurants beyond two-mile radius', () async {
      final client = MockClient((request) async {
        final payload = jsonEncode({
          'places': [
            {
              'id': 'far001',
              'displayName': {'text': 'Far Away Diner'},
              'types': ['restaurant'],
              'rating': 4.1,
              'location': {'latitude': 33.80, 'longitude': -84.45},
              'formattedAddress': 'Far St, Atlanta, GA',
            }
          ]
        });
        return http.Response(payload, 200);
      });

      final service = GooglePlacesImportService(client: client, apiKey: 'test-key');
      final results = await service.fetchNearbyRestaurants();

      expect(results, isEmpty);
    });
  });
}
