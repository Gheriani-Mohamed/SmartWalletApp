import 'package:speech_to_text/speech_to_text.dart';
import 'package:smart_wallet_app/models/CategoryModel.dart';

/// Result of parsing a voice command
class VoiceTransactionResult {
  final double? amount;
  final String? description;
  final String? type; // 'expense' or 'income'
  final CategoryModel? matchedCategory;
  final String rawText;

  VoiceTransactionResult({
    this.amount,
    this.description,
    this.type,
    this.matchedCategory,
    required this.rawText,
  });

  bool get isUsable => amount != null && amount! > 0;
}

class VoiceTransactionService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _initialized;
  }

  bool get isListening => _speech.isListening;
  bool get isAvailable => _initialized;

  /// Start listening — calls [onResult] with interim/final results
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    void Function()? onDone,
  }) async {
    if (!_initialized) await initialize();
    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
        if (result.finalResult) onDone?.call();
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
      cancelOnError: true,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> cancel() async {
    await _speech.cancel();
  }

  /// Parse raw speech text into a structured transaction result
  VoiceTransactionResult parse(String text, List<CategoryModel> categories) {
    final lower = text.toLowerCase().trim();

    return VoiceTransactionResult(
      amount: _extractAmount(lower),
      description: _extractDescription(lower),
      type: _extractType(lower),
      matchedCategory: _matchCategory(lower, categories),
      rawText: text,
    );
  }

  // ─── Parsers ────────────────────────────────────────────────────────────────

  double? _extractAmount(String text) {
    // Patterns: "$12", "12 dollars", "12.50", "twelve dollars"
    final numericMatch =
    RegExp(r'\$?\s*(\d+(?:\.\d{1,2})?)(?:\s*dollars?)?').firstMatch(text);
    if (numericMatch != null) {
      return double.tryParse(numericMatch.group(1)!);
    }

    // Word numbers fallback
    const words = {
      'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4,
      'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9,
      'ten': 10, 'eleven': 11, 'twelve': 12, 'thirteen': 13,
      'fourteen': 14, 'fifteen': 15, 'twenty': 20, 'thirty': 30,
      'forty': 40, 'fifty': 50, 'hundred': 100,
    };
    for (final entry in words.entries) {
      if (text.contains(entry.key)) return entry.value.toDouble();
    }
    return null;
  }

  String? _extractDescription(String text) {
    // "for McDonald's", "at Starbucks", "from Amazon"
    final patterns = [
      RegExp(r"(?:for|at|from|called|named)\s+([a-zA-Z0-9\s']+?)(?:\s+(?:in|to|as|on)|$)"),
      RegExp(r"(?:to|in)\s+\w+\s+(?:for|at)\s+([a-zA-Z0-9\s']+?)(?:\s+on|$)"),
    ];

    for (final p in patterns) {
    final match = p.firstMatch(text);
    if (match != null) {
    final desc = match.group(1)!.trim();
    if (desc.length > 1) return _toTitleCase(desc);
    }
    }
    return null;
  }

  String _extractType(String text) {
    if (RegExp(r'\b(income|salary|received|earned|got paid|deposit|refund|freelance|revenue|profit|bonus|wage|stipend)\b')
        .hasMatch(text)) {
      return 'income';
    }
    if (RegExp(r'\b(spent|paid|bought|purchased|expense|bill|fee|subscription|charge)\b')
        .hasMatch(text)) {
      return 'expense';
    }
    return 'expense'; // default
  }

  CategoryModel? _matchCategory(String text, List<CategoryModel> categories) {
    // Direct name match first
    for (final cat in categories) {
      if (text.contains(cat.name.toLowerCase())) return cat;
    }

    // Keyword mapping to common category names
    const keywords = {
      'food': ['food', 'eat', 'restaurant', 'lunch', 'dinner', 'breakfast', 'meal', 'pizza', 'burger'],
      'groceries': ['grocery', 'groceries', 'supermarket', 'market', 'store'],
      'transport': ['uber', 'taxi', 'bus', 'train', 'fuel', 'gas', 'transport', 'metro', 'ride'],
      'shopping': ['shop', 'shopping', 'amazon', 'mall', 'clothes', 'clothing'],
      'health': ['doctor', 'pharmacy', 'medicine', 'health', 'hospital', 'clinic'],
      'entertainment': ['movie', 'cinema', 'netflix', 'game', 'entertainment', 'sport'],
      'utilities': ['electric', 'water', 'internet', 'wifi', 'bill', 'utility'],
      'education': ['school', 'course', 'book', 'education', 'tuition'],
    };

    for (final entry in keywords.entries) {
      for (final kw in entry.value) {
        if (text.contains(kw)) {
          // Try to find a matching category by name
          final found = categories.where((c) =>
          c.name.toLowerCase().contains(entry.key) ||
              entry.key.contains(c.name.toLowerCase())).toList();
          if (found.isNotEmpty) return found.first;
        }
      }
    }
    return null;
  }

  String _toTitleCase(String text) => text
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  void dispose() {
    _speech.cancel();
  }
}