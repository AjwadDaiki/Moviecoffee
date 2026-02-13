import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Partage sur mobile (iOS/Android) via share_plus
Future<void> shareOrDownload(Uint8List bytes, String fileName, String shareText) async {
  // Obtenir le répertoire temporaire
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/$fileName';

  // Écrire le fichier
  final file = File(filePath);
  await file.writeAsBytes(bytes);

  // Partager via le share sheet natif
  await Share.shareXFiles(
    [XFile(filePath)],
    text: shareText,
  );

  // Nettoyer le fichier temporaire après un délai
  Future.delayed(const Duration(seconds: 5), () async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  });
}
