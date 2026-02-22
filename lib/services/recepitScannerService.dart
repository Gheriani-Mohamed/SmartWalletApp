import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';

/// Parsed result from a scanned receipt
class ReceiptData {
  final double? totalAmount;
  final DateTime? date;
  final String? merchantName;
  final List<ReceiptLineItem> lineItems;
  final String rawText;

  ReceiptData({
    this.totalAmount,
    this.date,
    this.merchantName,
    this.lineItems = const [],
    required this.rawText,
  });

  @override
  String toString() =>
      'ReceiptData(merchant: $merchantName, total: $totalAmount, date: $date, items: ${lineItems.length})';
}

class ReceiptLineItem {
  final String name;
  final double? amount;

  ReceiptLineItem({required this.name, this.amount});
}

class ReceiptScannerService {
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();

  /// Extracts text and parses receipt data from an image file.
  Future<ReceiptData> scanReceipt(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText =
    await _textRecognizer.processImage(inputImage);

    final rawText = recognizedText.text;
    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    return ReceiptData(
      totalAmount: _extractTotal(lines),
      date: _extractDate(lines),
      merchantName: _extractMerchant(lines),
      lineItems: _extractLineItems(lines),
      rawText: rawText,
    );
  }

  // ─── Parsing Helpers ────────────────────────────────────────────────────────

  /// Looks for lines containing keywords like TOTAL, AMOUNT DUE, etc.
  double? _extractTotal(List<String> lines) {
    // Priority keywords — checked in order
    final patterns = [
      RegExp(r'(total\s*due|amount\s*due|grand\s*total|total\s*amount)', caseSensitive: false),
      RegExp(r'\btotal\b', caseSensitive: false),
      RegExp(r'(balance|due)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      for (final line in lines) {
        if (pattern.hasMatch(line)) {
          final amount = _parseAmount(line);
          if (amount != null) return amount;
        }
      }
    }

    // Fallback: largest amount on the receipt (likely the total)
    double? largest;
    for (final line in lines) {
      final amount = _parseAmount(line);
      if (amount != null && (largest == null || amount > largest)) {
        largest = amount;
      }
    }
    return largest;
  }

  /// Extracts a date from common receipt date formats.
  DateTime? _extractDate(List<String> lines) {
    final datePatterns = [
      // MM/DD/YYYY or MM-DD-YYYY
      RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4})'),
      // YYYY-MM-DD
      RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})'),
      // DD Mon YYYY  e.g. 15 Jan 2024
      RegExp(r'(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+(\d{4})',
          caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in datePatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          try {
            // Pattern 3: DD Mon YYYY
            if (pattern.pattern.contains('jan')) {
              final day = int.parse(match.group(1)!);
              final month = _monthFromAbbr(match.group(2)!);
              final year = int.parse(match.group(3)!);
              return DateTime(year, month, day);
            }
            // Pattern 2: YYYY-MM-DD
            if (match.group(1)!.length == 4) {
              return DateTime(
                int.parse(match.group(1)!),
                int.parse(match.group(2)!),
                int.parse(match.group(3)!),
              );
            }
            // Pattern 1: MM/DD/YYYY
            final year = int.parse(match.group(3)!);
            return DateTime(
              year < 100 ? 2000 + year : year,
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
            );
          } catch (_) {
            continue;
          }
        }
      }
    }
    return null;
  }

  /// Assumes the merchant name is one of the first non-empty, non-numeric lines.
  String? _extractMerchant(List<String> lines) {
    final skipPatterns = RegExp(
        r'^\d|receipt|invoice|tax|tel|phone|www|http|@|address|street|ave|blvd',
        caseSensitive: false);

    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      if (line.length > 3 && !skipPatterns.hasMatch(line)) {
        return _toTitleCase(line);
      }
    }
    return null;
  }

  /// Extracts line items: lines that have a description + price pattern.
  List<ReceiptLineItem> _extractLineItems(List<String> lines) {
    final items = <ReceiptLineItem>[];
    // Skip totals / tax lines
    final skipWords = RegExp(r'\b(total|tax|subtotal|tip|discount|change|cash|card)\b',
        caseSensitive: false);

    for (final line in lines) {
      if (skipWords.hasMatch(line)) continue;
      final amount = _parseAmount(line);
      if (amount != null) {
        // Strip the price portion to get item name
        final name = line
            .replaceAll(RegExp(r'[\$£€]?\s*\d+[.,]\d{2}'), '')
            .replaceAll(RegExp(r'\s{2,}'), ' ')
            .trim();
        if (name.length > 1) {
          items.add(ReceiptLineItem(name: name, amount: amount));
        }
      }
    }
    return items;
  }

  // ─── Utility ────────────────────────────────────────────────────────────────

  double? _parseAmount(String text) {
    // Match currency amounts like $12.99, 12.99, 1,234.56
    final match =
    RegExp(r'[\$£€]?\s*(\d{1,3}(?:[,\s]\d{3})*(?:[.,]\d{2}))').firstMatch(text);
    if (match == null) return null;
    final cleaned = match.group(1)!.replaceAll(RegExp(r'[,\s](?=\d{3})'), '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  int _monthFromAbbr(String abbr) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
      'may': 5, 'jun': 6, 'jul': 7, 'aug': 8,
      'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return months[abbr.toLowerCase().substring(0, 3)] ?? 1;
  }

  String _toTitleCase(String text) => text
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  void dispose() => _textRecognizer.close();
}