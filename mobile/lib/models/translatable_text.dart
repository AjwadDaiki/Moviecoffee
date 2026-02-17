import '../services/app_language.dart';

/// Texte traduisible utilise pour titre et synopsis.
class TranslatableText {
  final String fr;
  final String en;
  final Map<String, String> _localized;

  const TranslatableText({
    required this.fr,
    this.en = '',
    Map<String, String> localized = const {},
  }) : _localized = localized;

  factory TranslatableText.fromJson(dynamic json) {
    if (json is String) {
      return TranslatableText(fr: json);
    }
    if (json is Map) {
      final localized = <String, String>{};
      json.forEach((key, value) {
        final lang = key.toString().trim().toLowerCase();
        final text = (value ?? '').toString().trim();
        if (lang.isEmpty || text.isEmpty) return;
        localized[lang] = text;
      });

      final fallback = localized.values.firstWhere(
        (value) => value.isNotEmpty,
        orElse: () => '',
      );
      final fr = localized['fr'] ?? localized['en'] ?? fallback;
      final en = localized['en'] ?? localized['fr'] ?? fallback;
      return TranslatableText(fr: fr, en: en, localized: localized);
    }
    return const TranslatableText(fr: '');
  }

  Map<String, dynamic> toJson() {
    if (_localized.isNotEmpty) {
      return _localized;
    }
    return {'fr': fr, 'en': en};
  }

  String resolve([String? languageCode]) {
    final raw = (languageCode ?? '').trim().toLowerCase();
    final shortCode = raw.isEmpty
        ? AppLanguage.currentCode
        : raw.split(RegExp('[-_]')).first;

    final exact = _localized[shortCode];
    if (exact != null && exact.isNotEmpty) {
      return exact;
    }

    if (shortCode != 'fr') {
      final english = _localized['en'];
      if (english != null && english.isNotEmpty) {
        return english;
      }
    }

    final french = _localized['fr'];
    if (french != null && french.isNotEmpty) {
      return french;
    }

    if (fr.isNotEmpty) return fr;
    if (en.isNotEmpty) return en;

    return _localized.values.firstWhere(
      (value) => value.isNotEmpty,
      orElse: () => '',
    );
  }

  /// Retourne le texte dans la langue active.
  String get display => resolve(AppLanguage.currentCode);

  @override
  String toString() => display;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslatableText && fr == other.fr && en == other.en;

  @override
  int get hashCode => fr.hashCode ^ en.hashCode;
}
