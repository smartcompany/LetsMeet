import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  NotificationProvider({required ApiService apiService}) : _apiService = apiService;
  final ApiService _apiService;

  int _unreadCount = 0;
  Map<String, int> _pendingCounts = {};

  int get unreadCount => _unreadCount;
  Map<String, int> get pendingCounts => Map.unmodifiable(_pendingCounts);

  Future<void> loadUnreadCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _unreadCount = 0;
        _pendingCounts = {};
        notifyListeners();
        return;
      }
      final token = await user.getIdToken();
      if (token != null) {
        _apiService.setToken(token);
      }
      final counts = await _apiService.getPendingApplicationCounts();
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
