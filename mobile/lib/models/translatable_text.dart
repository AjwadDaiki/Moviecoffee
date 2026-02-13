/// Texte traduisible (fr/en) — utilisé pour titre et synopsis
class TranslatableText {
  final String fr;
  final String en;

  const TranslatableText({required this.fr, this.en = ''});

  factory TranslatableText.fromJson(dynamic json) {
    if (json is String) {
      return TranslatableText(fr: json);
    }
    if (json is Map<String, dynamic>) {
      return TranslatableText(
        fr: json['fr'] as String? ?? json['en'] as String? ?? '',
        en: json['en'] as String? ?? json['fr'] as String? ?? '',
      );
    }
    return const TranslatableText(fr: '');
  }

  Map<String, dynamic> toJson() => {'fr': fr, 'en': en};

  /// Retourne le texte français, ou anglais si vide
  String get display => fr.isNotEmpty ? fr : en;

  @override
  String toString() => display;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslatableText && fr == other.fr && en == other.en;

  @override
  int get hashCode => fr.hashCode ^ en.hashCode;
}
