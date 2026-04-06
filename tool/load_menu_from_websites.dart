import 'dart:convert';
import 'dart:io';

import 'package:foodie/data/seed/generated_google_places_seed.dart';
import 'package:http/http.dart' as http;

import 'menu_seed_filters.dart';

const _defaultInputPath = 'data/menu_sources.json';
const _defaultOutputPath = 'data/menu_seed.json';
const _defaultMaxItems = 40;

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final inputPath = _readStringArg(args, '--input') ?? _defaultInputPath;
  final outputPath = _readStringArg(args, '--out') ?? _defaultOutputPath;
  final maxItems =
      int.tryParse(_readStringArg(args, '--max-items') ?? '') ??
      _defaultMaxItems;
  if (maxItems <= 0) {
    stderr.writeln('--max-items must be a positive integer.');
    exitCode = 64;
    return;
  }

  final inputFile = File(inputPath);
  if (!await inputFile.exists()) {
    stderr.writeln('Input file not found: $inputPath');
    stderr.writeln('Create it from data/menu_sources.example.json.');
    exitCode = 64;
    return;
  }

  final raw = await inputFile.readAsString();
  final decoded = jsonDecode(raw);
  if (decoded is! List<dynamic>) {
    stderr.writeln('Invalid input JSON. Root must be an array.');
    exitCode = 64;
    return;
  }

  final namesInScope = generatedGooglePlacesRestaurants
      .map((r) => r.name)
      .toList(growable: false);
  final seedByRestaurant = <String, List<Map<String, dynamic>>>{
    for (final name in namesInScope) name: <Map<String, dynamic>>[],
  };

  final client = http.Client();
  try {
    for (final entry in decoded.whereType<Map<String, dynamic>>()) {
      final restaurantName = (entry['restaurantName'] as String?)?.trim() ?? '';
      final menuUrl = (entry['menuUrl'] as String?)?.trim() ?? '';
      if (restaurantName.isEmpty || menuUrl.isEmpty) {
        continue;
      }
      if (!seedByRestaurant.containsKey(restaurantName)) {
        stderr.writeln('Skipping unknown restaurant: $restaurantName');
        continue;
      }

      final items = await _fetchMenuItemsFromWebsite(
        client: client,
        url: menuUrl,
        maxItems: maxItems,
      );
      seedByRestaurant[restaurantName] = items;
      stdout.writeln('Loaded ${items.length} menu items for $restaurantName');
    }
  } finally {
    client.close();
  }

  final outputPayload = seedByRestaurant.entries
      .map(
        (entry) => <String, dynamic>{
          'restaurantName': entry.key,
          'items': entry.value,
        },
      )
      .toList(growable: false);

  final outputFile = File(outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(outputPayload),
    flush: true,
  );
  stdout.writeln('Wrote website-loaded menu seed to ${outputFile.path}.');
}

Future<List<Map<String, dynamic>>> _fetchMenuItemsFromWebsite({
  required http.Client client,
  required String url,
  required int maxItems,
}) async {
  Uri uri;
  try {
    uri = Uri.parse(url);
  } catch (_) {
    return const [];
  }

  List<Map<String, dynamic>> best = const [];
  for (final candidate in _candidateMenuUris(uri)) {
    final response = await client.get(
      candidate,
      headers: const {
        'User-Agent': 'BiteMatchMenuLoader/1.0',
        'Accept': 'text/html,application/xhtml+xml',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      continue;
    }

    final html = response.body;
    final fromJsonLd = _extractFromJsonLd(html, maxItems: maxItems);
    final fromLooseHtml = _extractFromLooseHtml(html, maxItems: maxItems);
    final candidateItems =
        fromJsonLd.length >= fromLooseHtml.length ? fromJsonLd : fromLooseHtml;
    if (candidateItems.length > best.length) {
      best = candidateItems;
    }
    if (best.length >= maxItems) {
      break;
    }
  }

  return best;
}

List<Uri> _candidateMenuUris(Uri base) {
  final candidates = <Uri>[base];
  final normalizedPath = base.path.toLowerCase();
  if (normalizedPath.contains('menu')) {
    return candidates;
  }

  const menuPaths = <String>[
    '/menu',
    '/menu/',
    '/menus',
    '/menus/',
    '/food-menu',
    '/food-menu/',
    '/our-menu',
    '/our-menu/',
  ];
  for (final path in menuPaths) {
    candidates.add(
      base.replace(
        path: path,
        query: '',
        fragment: '',
      ),
    );
  }
  return candidates;
}

List<Map<String, dynamic>> _extractFromJsonLd(
  String html, {
  required int maxItems,
}) {
  final scriptRegex = RegExp(
    "<script[^>]*type=[\"']application/ld\\+json[\"'][^>]*>([\\s\\S]*?)</script>",
    caseSensitive: false,
  );
  final matches = scriptRegex.allMatches(html);
  final found = <_RawMenuItem>[];
  for (final match in matches) {
    final block = (match.group(1) ?? '').trim();
    if (block.isEmpty) continue;
    final parsed = _safeJsonDecode(block);
    if (parsed == null) continue;
    _collectMenuItemsRecursively(parsed, found);
    if (found.length >= maxItems) break;
  }
  return _normalizeRawItems(found, maxItems: maxItems);
}

List<Map<String, dynamic>> _extractFromLooseHtml(
  String html, {
  required int maxItems,
}) {
  final sanitizedHtml = html
      .replaceAll(
        RegExp(
          r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>',
          caseSensitive: false,
        ),
        ' ',
      )
      .replaceAll(
        RegExp(
          r'<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>',
          caseSensitive: false,
        ),
        ' ',
      );
  final withBreaks = sanitizedHtml
      .replaceAll(RegExp("<br\\s*/?>", caseSensitive: false), '\n')
      .replaceAll(RegExp("</(p|li|div|h[1-6])>", caseSensitive: false), '\n');
  final text = withBreaks.replaceAll(RegExp(r'<[^>]+>'), ' ');
  final lines = text
      .split(RegExp(r'[\r\n]+'))
      .map(cleanMenuItemText)
      .where((line) => line.isNotEmpty)
      .toList(growable: false);

  final found = <_RawMenuItem>[];
  for (final line in lines) {
    if (found.length >= maxItems) break;
    if (line.length < 4 || line.length > 120) continue;
    if (looksLikeJunk(line)) continue;
    final parsed = _parseLooseHtmlLine(line);
    if (parsed == null) continue;
    final price = parsed.price;
    final name = parsed.name;
    if (!looksLikeMenuItemName(name)) continue;
    found.add(
      _RawMenuItem(
        name: name,
        price: price,
        description: 'Imported from restaurant website.',
      ),
    );
  }
  return _normalizeRawItems(found, maxItems: maxItems);
}

_ParsedLooseLine? _parseLooseHtmlLine(String line) {
  // Prefer explicit dollar amounts and choose the right-most one, since
  // quantities like "6pc" are often at the beginning of menu lines.
  final dollarMatches = RegExp(r'\$\s*(\d{1,3}(?:\.\d{2})?)').allMatches(line).toList();
  if (dollarMatches.isNotEmpty) {
    final match = dollarMatches.last;
    final price = double.tryParse(match.group(1) ?? '');
    if (price != null && looksLikeReasonablePrice(price)) {
      final name = cleanMenuItemText(
        line.substring(0, match.start) + line.substring(match.end),
      );
      if (name.isNotEmpty) {
        return _ParsedLooseLine(name: name, price: price);
      }
    }
  }

  // Fallback: trailing numeric token (e.g., "... 12.99"), but not numbers
  // embedded in words.
  final trailing = RegExp(r'(?:^|\s)(\d{1,3}(?:\.\d{2})?)\s*$').firstMatch(line);
  if (trailing != null) {
    final price = double.tryParse(trailing.group(1) ?? '');
    if (price != null && looksLikeReasonablePrice(price)) {
      final name = cleanMenuItemText(line.substring(0, trailing.start));
      if (name.isNotEmpty) {
        return _ParsedLooseLine(name: name, price: price);
      }
    }
  }

  return null;
}

void _collectMenuItemsRecursively(Object? node, List<_RawMenuItem> out) {
  if (node is List) {
    for (final child in node) {
      _collectMenuItemsRecursively(child, out);
    }
    return;
  }
  if (node is! Map) {
    return;
  }

  final name = _asCleanString(node['name']);
  final description = _asCleanString(node['description']);
  final directPrice = _priceFromDynamic(node['price']);

  double? price = directPrice;
  if (price == null) {
    final offers = node['offers'];
    price = _extractPriceFromOffers(offers);
  }

  if (name != null && price != null && price > 0) {
    if (looksLikeReasonablePrice(price) && looksLikeMenuItemName(name)) {
      out.add(
        _RawMenuItem(
          name: name,
          price: price,
          description: description ?? 'Imported from restaurant structured data.',
        ),
      );
    }
  }

  for (final value in node.values) {
    if (value is Map || value is List) {
      _collectMenuItemsRecursively(value, out);
    }
  }
}

double? _extractPriceFromOffers(Object? offers) {
  if (offers is Map) {
    final direct = _priceFromDynamic(offers['price']);
    if (direct != null) return direct;
    for (final value in offers.values) {
      final nested = _extractPriceFromOffers(value);
      if (nested != null) return nested;
    }
    return null;
  }
  if (offers is List) {
    for (final value in offers) {
      final nested = _extractPriceFromOffers(value);
      if (nested != null) return nested;
    }
  }
  return null;
}

double? _priceFromDynamic(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final match = RegExp(r'(\d{1,3}(?:\.\d{2})?)').firstMatch(value);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }
  return null;
}

List<Map<String, dynamic>> _normalizeRawItems(
  List<_RawMenuItem> raw, {
  required int maxItems,
}) {
  final byName = <String, _RawMenuItem>{};
  for (final item in raw) {
    final key = item.name.toLowerCase();
    byName.putIfAbsent(key, () => item);
  }
  return byName.values
      .take(maxItems)
      .map(
        (item) => <String, dynamic>{
          'name': item.name,
          'price': double.parse(item.price.toStringAsFixed(2)),
          'description': item.description,
        },
      )
      .toList(growable: false);
}

Object? _safeJsonDecode(String input) {
  try {
    return jsonDecode(input);
  } catch (_) {
    return null;
  }
}

String? _asCleanString(Object? value) {
  if (value is! String) return null;
  final cleaned = cleanMenuItemText(value);
  if (cleaned.isEmpty) return null;
  return cleaned;
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
  stdout.writeln('Usage: dart run tool/load_menu_from_websites.dart [options]');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln(
    '  --input=PATH         Restaurant source JSON (default: $_defaultInputPath)',
  );
  stdout.writeln(
    '  --out=PATH           Menu seed JSON output (default: $_defaultOutputPath)',
  );
  stdout.writeln(
    '  --max-items=NUM      Max items per restaurant (default: $_defaultMaxItems)',
  );
  stdout.writeln('  --help, -h           Show this help text');
  stdout.writeln('');
  stdout.writeln('Input format:');
  stdout.writeln(
    '[{"restaurantName":"Barcelona Wine Bar","menuUrl":"https://example.com/menu"}]',
  );
}

class _RawMenuItem {
  const _RawMenuItem({
    required this.name,
    required this.price,
    required this.description,
  });

  final String name;
  final double price;
  final String description;
}

class _ParsedLooseLine {
  const _ParsedLooseLine({
    required this.name,
    required this.price,
  });

  final String name;
  final double price;
}
