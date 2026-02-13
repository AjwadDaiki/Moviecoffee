import 'package:flutter/foundation.dart';

/// Service global pour notifier les changements de collection
/// Les écrans peuvent écouter ce notifier pour se rafraîchir automatiquement
class CollectionNotifier extends ChangeNotifier {
  static final CollectionNotifier _instance = CollectionNotifier._internal();
  factory CollectionNotifier() => _instance;
  CollectionNotifier._internal();

  /// Appelé après une action (LIKE, SEEN, RATE, etc.)
  void notifyCollectionChanged() {
    notifyListeners();
  }
}

/// Instance globale
final collectionNotifier = CollectionNotifier();
