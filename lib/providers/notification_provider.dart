import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../app_auth_provider.dart';

class NotificationProvider with ChangeNotifier {
  NotificationProvider._();
  static final NotificationProvider shared = NotificationProvider._();

  int _unreadCount = 0;
  Map<String, int> _pendingCounts = {};

  int get unreadCount => _unreadCount;
  Map<String, int> get pendingCounts => Map.unmodifiable(_pendingCounts);

  Future<void> loadUnreadCount() async {
    try {
      if (!AppAuthProvider.shared.isLoggedIn()) {
        _unreadCount = 0;
        _pendingCounts = {};
        notifyListeners();
        return;
      }
      final counts = await ApiService.shared.getPendingApplicationCounts();
      _pendingCounts = counts;
      _unreadCount = counts.values.fold<int>(0, (sum, c) => sum + c);
      notifyListeners();
    } catch (_) {
      _unreadCount = 0;
      _pendingCounts = {};
      notifyListeners();
    }
  }
}
