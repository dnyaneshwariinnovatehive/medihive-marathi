import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  static NotificationProvider? _instance;

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _instance = this;
    loadNotifications();
  }

  static Future<void> addNotificationSilently(String title, String body) async {
    final newNotification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList = prefs.getStringList('medi_notifications') ?? [];
      jsonList.insert(0, newNotification.toJson());
      await prefs.setStringList('medi_notifications', jsonList);
    } catch (e) {
      debugPrint('Error adding notification silently: $e');
    }
    
    // If instance is active, refresh UI immediately
    if (_instance != null) {
      await _instance!.loadNotifications();
    }
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList = prefs.getStringList('medi_notifications');
      if (jsonList != null) {
        _notifications = jsonList
            .map((item) => NotificationModel.fromJson(item))
            .toList();
        // Sort by timestamp descending
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      } else {
        _notifications = [];
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNotification(String title, String body) async {
    final newNotification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
    );

    _notifications.insert(0, newNotification);
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      await _saveToPrefs();
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> clearNotifications() async {
    _notifications.clear();
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList =
          _notifications.map((n) => n.toJson()).toList();
      await prefs.setStringList('medi_notifications', jsonList);
    } catch (e) {
      debugPrint('Error saving notifications to SharedPreferences: $e');
    }
  }
}
