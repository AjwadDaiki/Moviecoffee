// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Téléchargement sur Web via dart:html
Future<void> shareOrDownload(Uint8List bytes, String fileName, String shareText) async {
  // Créer un Blob avec les bytes PNG
  final blob = html.Blob([bytes], 'image/png');

  // Créer une URL temporaire pour le blob
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Créer un élément <a> pour déclencher le téléchargement
  final anchor = html.AnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';

  // Ajouter au DOM, cliquer, puis nettoyer
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  // Libérer l'URL
  html.Url.revokeObjectUrl(url);
}
