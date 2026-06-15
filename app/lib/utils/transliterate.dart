/// Lightweight English → Telugu transliteration + phonetic normalization.
///
/// Primary use: English name search against Telugu voter records.
///
/// The DB stores a `name_roman_norm` column which is the phonetic skeleton of
/// each Telugu voter name (e.g. ఫైజుల్లా → "fjl"). When the user types English,
/// we apply the same normalization to their query and search that column.
///
/// Normalization rules (identical in Python extractor and here):
///   ph→f  sh→x  th→t  dh→d  bh→b  gh→g  ch→c  ng→n
///   z→j  w→v  y→i  q→k
///   strip vowels (aeiou)
///   collapse duplicate letters (ll→l)
///   strip trailing silent h

class Transliterator {
  Transliterator._();

  /// Returns true if [input] is entirely ASCII (English input, not Telugu).
  static bool isEnglish(String input) {
    return RegExp(r'^[a-zA-Z0-9 \-\.]+$').hasMatch(input.trim());
  }

  /// Normalize an English name to a phonetic skeleton for DB lookup.
  ///
  /// "faizullah" → "fjl"   matches DB "fjl" (from ఫైజుల్లా)
  /// "krishna"   → "krxn"  matches DB "krxn" (from కృష్ణా)
  /// "reddy"     → "rd"    matches DB "rd" (from రెడ్డి)
  static String normalizeForSearch(String s) {
    s = s.toLowerCase();
    // Multi-char substitutions (order matters — longest first)
    const multi = [
      ('ph', 'f'), ('sh', 'x'), ('th', 't'), ('dh', 'd'),
      ('bh', 'b'), ('gh', 'g'), ('ch', 'c'), ('ng', 'n'),
    ];
    for (final (from, to) in multi) {
      s = s.replaceAll(from, to);
    }
    // Single-char substitutions
    s = s.replaceAll('z', 'j');
    s = s.replaceAll('w', 'v');
    s = s.replaceAll('y', 'i');
    s = s.replaceAll('q', 'k');
    // Strip vowels
    s = s.replaceAll(RegExp(r'[aeiou]'), '');
    // Collapse consecutive identical chars (ll→l, tt→t, etc.)
    s = s.replaceAllMapped(RegExp(r'(.)\1+'), (m) => m.group(1)!);
    // Strip trailing silent h
    if (s.endsWith('h')) s = s.substring(0, s.length - 1);
    return s;
  }

  /// For a multi-word English query, normalize each word separately.
  /// Returns a list of patterns to LIKE-search (one per word).
  ///
  /// "faiz ullah" → ["fjl"] … actually joined as single norm per word
  static List<String> wordsNormalized(String query) {
    return query
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map(normalizeForSearch)
        .where((w) => w.isNotEmpty)
        .toList();
  }
}

