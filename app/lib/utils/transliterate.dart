/// Lightweight English → Telugu transliteration.
///
/// Given an English query like "faizullah" or "raju reddy",
/// produces a list of Telugu phonetic candidates that can be used
/// in SQL LIKE patterns to search the voters table.
///
/// Strategy:
///   1. Normalise the input (lowercase, strip extra spaces).
///   2. Use a greedy, longest-match-first mapping of English phonemes
///      to Telugu aksharas.
///   3. Return ALL plausible Telugu renderings (handles alternate
///      vowel representations, e.g. "a" → both "" and "ా").
///
/// This is intentionally approximate — the goal is recall (find everyone
/// whose name sounds like the input), not precision.

class Transliterator {
  Transliterator._();

  // ── Ordered phoneme map (longest match first) ──────────────────────────
  // Each entry: (english_pattern, telugu_string)
  // Patterns are tried left-to-right; first match wins.
  static const List<(String, String)> _map = [
    // ── Multi-char consonant clusters ──────────────────────────────────────
    ('ksh', 'క్ష'), ('jn',  'జ్ఞ'), ('shr', 'శ్ర'),
    ('thr', 'థ్ర'), ('ndr', 'ంద్ర'),
    // ── Double consonants ──────────────────────────────────────────────────
    ('bb', 'బ్బ'), ('cc', 'క్క'), ('dd', 'డ్డ'), ('ff', 'ఫ్'), ('gg', 'గ్గ'),
    ('hh', 'హ్హ'), ('jj', 'జ్జ'), ('kk', 'క్క'), ('ll', 'ల్ల'), ('mm', 'మ్మ'),
    ('nn', 'న్న'), ('pp', 'ప్ప'), ('rr', 'ర్ర'), ('ss', 'స్స'), ('tt', 'ట్ట'),
    ('vv', 'వ్వ'), ('yy', 'య్య'), ('zz', 'జ్జ'),
    // ── Digraphs ───────────────────────────────────────────────────────────
    ('sh', 'శ'), ('ph', 'ఫ'), ('gh', 'ఘ'), ('ch', 'చ'), ('dh', 'ధ'),
    ('th', 'థ'), ('bh', 'భ'), ('kh', 'ఖ'), ('jh', 'ఝ'), ('nh', 'ణ'),
    ('ng', 'ంగ'), ('nk', 'ంక'), ('ai', 'ై'), ('au', 'ౌ'), ('oo', 'ూ'),
    ('ee', 'ీ'), ('ou', 'ౌ'), ('aa', 'ా'), ('ii', 'ీ'), ('uu', 'ూ'),
    ('ae', 'ై'),
    // ── Vowels ─────────────────────────────────────────────────────────────
    ('a', 'అ'), ('e', 'ె'), ('i', 'ి'), ('o', 'ో'), ('u', 'ు'),
    // ── Single consonants ──────────────────────────────────────────────────
    ('b', 'బ'), ('c', 'క'), ('d', 'డ'), ('f', 'ఫ'), ('g', 'గ'),
    ('h', 'హ'), ('j', 'జ'), ('k', 'క'), ('l', 'ల'), ('m', 'మ'),
    ('n', 'న'), ('p', 'ప'), ('q', 'క'), ('r', 'ర'), ('s', 'స'),
    ('t', 'త'), ('v', 'వ'), ('w', 'వ'), ('x', 'క్స'), ('y', 'య'),
    ('z', 'జ'),
  ];

  // ── Pre-built sorted map (longest key first) ─────────────────────────────
  static final List<(String, String)> _sorted = () {
    final copy = List<(String, String)>.from(_map);
    copy.sort((a, b) => b.$1.length.compareTo(a.$1.length));
    return copy;
  }();

  /// Transliterate [english] text to a Telugu string.
  ///
  /// Example: `transliterate("faizullah")` → `"ఫైజుల్లాహ్"`
  static String transliterate(String english) {
    final src = english.toLowerCase().trim();
    final buf = StringBuffer();
    int i = 0;
    while (i < src.length) {
      bool matched = false;
      for (final (eng, tel) in _sorted) {
        if (src.startsWith(eng, i)) {
          buf.write(tel);
          i += eng.length;
          matched = true;
          break;
        }
      }
      if (!matched) {
        // Keep unknown characters as-is (digits, spaces, hyphens)
        buf.write(src[i]);
        i++;
      }
    }
    return buf.toString();
  }

  /// Returns true if [input] contains only ASCII letters/digits/spaces/hyphens
  /// (i.e. the user typed in English, not Telugu).
  static bool isEnglish(String input) {
    return RegExp(r'^[a-zA-Z0-9 \-\.]+$').hasMatch(input.trim());
  }

  /// Given a raw search query, returns the Telugu string to use in SQL LIKE.
  ///
  /// If [query] is already Telugu → returns it unchanged.
  /// If [query] is English → transliterates it.
  /// Returns empty string if [query] is blank.
  static String toTeluguPattern(String query) {
    final q = query.trim();
    if (q.isEmpty) return '';
    if (!isEnglish(q)) return q; // already Telugu
    return transliterate(q);
  }

  /// Splits a multi-word English query and returns Telugu patterns
  /// for each word (useful for "first last" name searches).
  ///
  /// e.g. "raju reddy" → ["రాజు", "రెడ్డి"]
  static List<String> wordsToTeluguPatterns(String query) {
    return query
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map(transliterate)
        .toList();
  }
}
