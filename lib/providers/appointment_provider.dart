import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/appointment.dart';
import '../models/appointment_model.dart';
import 'notification_provider.dart';
import '../services/local_notification_service.dart';

class AppointmentProvider extends ChangeNotifier {
  DateTime _currentDate = DateTime.now();
  int _selectedDay = DateTime.now().day;
  final Map<String, List<String>> _dayNotes = {};

  DateTime get currentDate => _currentDate;
  int get selectedDay => _selectedDay;

  List<String> get dayNotes {
    final key = _noteKeyFor(_currentDate.year, _currentDate.month, _selectedDay);
    return _dayNotes[key] ?? [];
  }

  bool hasNotesForDay(int day) {
    final key = _noteKeyFor(_currentDate.year, _currentDate.month, day);
    return _dayNotes[key]?.isNotEmpty == true;
  }

  String _noteKeyFor(int year, int month, int day) => '$year-$month-$day';

  void loadNotesFromHive() {
    try {
      final box = Hive.box('day_notes');
      _dayNotes.clear();
      for (final key in box.keys) {
        final val = box.get(key);
        if (val is String) {
          _dayNotes[key.toString()] = [val];
        } else if (val is List) {
          _dayNotes[key.toString()] = val.cast<String>();
        }
      }
    } catch (_) {}
  }

  int _nextId = 0;

  final List<Appointment> _appointments = [];
  StreamSubscription? _apptSubscription;

  AppointmentProvider() {
    _loadFromHive();
    loadNotesFromHive();
    _apptSubscription = Hive.box<AppointmentModel>('appointments').watch().listen((_) {
      _loadFromHive();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rescheduleNotifications();
    });
  }

  Future<void> _rescheduleNotifications() async {
    final now = DateTime.now();
    for (final apt in _appointments) {
      final remindAt = apt.dateTime.subtract(const Duration(minutes: 10));
      if (remindAt.isAfter(now)) {
        try {
          await LocalNotificationService().scheduleAppointmentReminder(
            id: apt.id,
            patientName: apt.patient,
            appointmentTime: apt.dateTime,
          );
        } catch (e) {
          debugPrint('Notification reschedule error for ${apt.id}: $e');
        }
      }
    }
  }

  void _loadFromHive() {
    try {
      final box = Hive.box<AppointmentModel>('appointments');
      _appointments.clear();
      for (final m in box.values) {
        _appointments.add(Appointment(
          id: m.id,
          dateTime: m.dateTime,
          type: m.notes == 'Follow-up' ? 'Follow-up' : 'Consultation',
          patient: _patientNameFromId(m.patientId),
          time: '${m.dateTime.hour.toString().padLeft(2, '0')}:${m.dateTime.minute.toString().padLeft(2, '0')}',
        ));
      }
      final maxId = box.values.fold<int>(0, (max, m) {
        final numId = int.tryParse(m.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return numId > max ? numId : max;
      });
      _nextId = maxId;
      notifyListeners();
    } catch (_) {}
  }

  String _patientNameFromId(String patientId) {
    try {
      final patientBox = Hive.box('patients');
      final patient = patientBox.get(patientId);
      if (patient != null) {
        return (patient as dynamic).name ?? patientId;
      }
    } catch (_) {}
    return patientId;
  }

  List<Appointment> get appointments => _appointments;

  List<Appointment> get selectedDayAppointments =>
      _appointments.where((a) =>
          a.dateTime.day == _selectedDay &&
          a.dateTime.month == _currentDate.month &&
          a.dateTime.year == _currentDate.year,
      ).toList();

  bool get _hasRealData {
    try {
      return Hive.box('opd_records').isNotEmpty ||
          Hive.box<AppointmentModel>('appointments').isNotEmpty ||
          Hive.box('patients').isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  List<Appointment> get upcomingFollowUps {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _appointments.where((a) {
      if (a.type != 'Follow-up') return false;
      final aptDate = DateTime(a.dateTime.year, a.dateTime.month, a.dateTime.day);
      return !aptDate.isBefore(today);
    }).toList();
  }

  final Map<String, List<String>> _dayReminders = {};

  List<String> get dayReminders {
    final key = '${_currentDate.year}-${_currentDate.month}-$_selectedDay';
    return _dayReminders[key] ?? [];
  }

  void addReminder(String value) {
    if (value.trim().isEmpty) return;
    final key = '${_currentDate.year}-${_currentDate.month}-$_selectedDay';
    _dayReminders.putIfAbsent(key, () => []);
    _dayReminders[key]!.add(value.trim());
    NotificationProvider.addNotificationSilently(
      'Reminder: $_selectedDay ${_currentDate.month}/${_currentDate.year}',
      value.trim(),
    );
    notifyListeners();
  }

  void removeReminderAt(int index) {
    final key = '${_currentDate.year}-${_currentDate.month}-$_selectedDay';
    final reminders = _dayReminders[key];
    if (reminders != null && index < reminders.length) {
      reminders.removeAt(index);
      if (reminders.isEmpty) _dayReminders.remove(key);
      notifyListeners();
    }
  }

  void setSelectedDay(int day) {
    _selectedDay = day;
    notifyListeners();
  }

  void addNote(String value) {
    if (value.trim().isEmpty) return;
    final key = _noteKeyFor(_currentDate.year, _currentDate.month, _selectedDay);
    _dayNotes.putIfAbsent(key, () => []);
    _dayNotes[key]!.add(value.trim());
    try {
      final box = Hive.box('day_notes');
      box.put(key, _dayNotes[key]);
    } catch (_) {}
    notifyListeners();
  }

  void removeNoteAt(int index) {
    final key = _noteKeyFor(_currentDate.year, _currentDate.month, _selectedDay);
    final notes = _dayNotes[key];
    if (notes != null && index < notes.length) {
      notes.removeAt(index);
      if (notes.isEmpty) {
        _dayNotes.remove(key);
        try {
          Hive.box('day_notes').delete(key);
        } catch (_) {}
      } else {
        try {
          Hive.box('day_notes').put(key, notes);
        } catch (_) {}
      }
      notifyListeners();
    }
  }

  void removeNoteForDay(int day) {
    final key = _noteKeyFor(_currentDate.year, _currentDate.month, day);
    _dayNotes.remove(key);
    try {
      Hive.box('day_notes').delete(key);
    } catch (_) {}
    notifyListeners();
  }

  void previousMonth() {
    _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
    final daysInNewMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;
    if (_selectedDay > daysInNewMonth) _selectedDay = daysInNewMonth;
    notifyListeners();
  }

  void nextMonth() {
    _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
    final daysInNewMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;
    if (_selectedDay > daysInNewMonth) _selectedDay = daysInNewMonth;
    notifyListeners();
  }

  bool hasAppointment(int day) {
    return _appointments.any((a) =>
        a.dateTime.day == day &&
        a.dateTime.month == _currentDate.month &&
        a.dateTime.year == _currentDate.year);
  }

  List<Appointment> appointmentsForDay(int day) {
    return _appointments.where((a) =>
        a.dateTime.day == day &&
        a.dateTime.month == _currentDate.month &&
        a.dateTime.year == _currentDate.year).toList();
  }

  void addAppointment({
    required DateTime dateTime,
    required String type,
    required String patient,
    required String time,
    String? patientId,
  }) {
    _nextId++;
    final id = 'apt_$_nextId';
    _appointments.add(Appointment(
      id: id,
      dateTime: dateTime,
      type: type,
      patient: patient,
      time: time,
    ));
    try {
      final box = Hive.box<AppointmentModel>('appointments');
      if (patientId == null || patientId.isEmpty) {
        final patientBox = Hive.box('patients');
        for (final p in patientBox.values) {
          if ((p as dynamic).name == patient) {
            patientId = (p as dynamic).id ?? '';
            break;
          }
        }
      }
      box.put(id, AppointmentModel(
        id: id,
        patientId: patientId ?? '',
        dateTime: dateTime,
        notes: type == 'Follow-up' ? 'Follow-up' : '',
        isSynced: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    } catch (_) {}
    LocalNotificationService().scheduleAppointmentReminder(
      id: id,
      patientName: patient,
      appointmentTime: dateTime,
    );
    notifyListeners();
  }

  void removeAppointment(String id) {
    _appointments.removeWhere((a) => a.id == id);
    try {
      final box = Hive.box<AppointmentModel>('appointments');
      box.delete(id);
    } catch (_) {}
    LocalNotificationService().cancelAppointmentReminder(id);
    notifyListeners();
  }

  @override
  void dispose() {
    _apptSubscription?.cancel();
    super.dispose();
  }
}
