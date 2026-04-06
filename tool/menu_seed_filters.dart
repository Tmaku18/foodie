// Shared validation for scraped/packaged menu rows (website loader + clean pass).

String cleanMenuItemText(String value) {
  return value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&nbsp;', ' ')
      .trim();
}

bool looksLikeJunk(String line) {
  final lower = line.toLowerCase();
  return lower.contains('cookie') ||
      lower.contains('privacy') ||
      lower.contains('javascript') ||
      lower.contains('terms') ||
      lower.contains('sign in') ||
      lower.contains('login') ||
      lower.contains('gtm-') ||
      lower.contains('datalayer') ||
      lower.contains('shopify') ||
      lower.contains('window.') ||
      lower.contains('document.') ||
      lower.contains('var ') ||
      lower.contains('const ') ||
      lower.contains('function ') ||
      lower.contains('settimeout') ||
      lower.contains('src: url') ||
      lower.contains('font-weight') ||
      lower.contains('background:') ||
      lower.contains('transform:') ||
      lower.contains('translatex') ||
      lower.contains('animation:') ||
      lower.contains('transition:') ||
      lower.contains('width:') ||
      lower.contains('height:') ||
      lower.contains('z-index') ||
      lower.contains('@media') ||
      lower.contains('!important') ||
      lower.contains('keyframes') ||
      lower.contains('contain-intrinsic-size') ||
      lower.contains('postalcode') ||
      lower.contains('streetaddress');
}

bool looksLikeMenuItemName(String name) {
  final cleaned = cleanMenuItemText(name);
  final lower = cleaned.toLowerCase();
  if (cleaned.length < 3 || cleaned.length > 80) return false;
  if (looksLikeJunk(cleaned)) return false;
  if (lower == 'for' || lower == 'from' || lower == 'with') return false;
  if (RegExp(r'^(for|from|only|just)\s+\$?\d').hasMatch(lower)) return false;
  if (RegExp(r'^\d+\s+for$').hasMatch(lower)) return false;
  if (!RegExp(r'[A-Za-z]').hasMatch(cleaned)) return false;
  if (RegExp(r'[{}<>]').hasMatch(cleaned)) return false;
  if (cleaned.contains('http') || cleaned.contains('//')) return false;
  if (cleaned.contains('=') || cleaned.contains(';')) return false;
  if (RegExp(r'["\\]').hasMatch(cleaned)) return false;
  if (RegExp(r'\d{3,}').hasMatch(cleaned)) return false;
  if (RegExp(r'[#%]{1,}').hasMatch(cleaned)) return false;
  final alphaChars = RegExp(r'[A-Za-z]').allMatches(cleaned).length;
  if (alphaChars < 3) return false;
  return true;
}

bool looksLikeReasonablePrice(double price) {
  return price >= 1 && price <= 120;
}

bool isValidMenuSeedItem(Map<String, dynamic> raw) {
  final name = raw['name'];
  if (name is! String) return false;
  final priceVal = raw['price'];
  final price = priceVal is num
      ? priceVal.toDouble()
      : double.tryParse(priceVal?.toString() ?? '');
  if (price == null) return false;
  return looksLikeMenuItemName(name) && looksLikeReasonablePrice(price);
}
