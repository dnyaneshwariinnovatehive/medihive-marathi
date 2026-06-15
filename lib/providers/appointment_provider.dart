import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/appointment.dart';
import '../models/appointment_model.dart';

class AppointmentProvider extends ChangeNotifier {
  DateTime _currentDate = DateTime.now();
  int _selectedDay = DateTime.now().day;
  final Map<String, String> _dayNotes = {};

  DateTime get currentDate => _currentDate;
  int get selectedDay => _selectedDay;

  String get notes {
    final key = '${_currentDate.year}-${_currentDate.month}-$_selectedDay';
    return _dayNotes[key] ?? '';
  }

  int _nextId = 4;

  final List<Appointment> _appointments = [
    Appointment(id: 'apt_1', dateTime: DateTime(DateTime.now().year, DateTime.now().month, 17), type: 'Follow-up', patient: 'Aryan Patil', time: '10:00 AM'),
    Appointment(id: 'apt_2', dateTime: DateTime(DateTime.now().year, DateTime.now().month, 19), type: 'Consultation', patient: 'Jiya Sharma', time: '2:00 PM'),
    Appointment(id: 'apt_3', dateTime: DateTime(DateTime.now().year, DateTime.now().month, 21), type: 'Follow-up', patient: 'Nehal P', time: '11:30 AM'),
    Appointment(id: 'apt_4', dateTime: DateTime(DateTime.now().year, DateTime.now().month, 29), type: 'Follow-up', patient: 'Vira', time: '3:00 PM'),
  ];

  AppointmentProvider() {
    _loadFromHive();
  }

  void _loadFromHive() {
    try {
      final box = Hive.box<AppointmentModel>('appointments');
      for (final m in box.values) {
        _appointments.add(Appointment(
          id: m.id,
          dateTime: m.dateTime,
          type: m.notes == 'Follow-up' ? 'Follow-up' : 'Consultation',
          patient: _patientNameFromId(m.patientId),
          time: '${m.dateTime.hour.toString().padLeft(2, '0')}:${m.dateTime.minute.toString().padLeft(2, '0')}',
        ));
      }
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
      _appointments.where((a) => a.dateTime.day == _selectedDay).toList();

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
    if (!_hasRealData) return [];
    final now = DateTime.now();
    return _appointments.where((a) {
      if (a.type != 'Follow-up') return false;
      return a.dateTime.year > now.year ||
          (a.dateTime.year == now.year && a.dateTime.month > now.month) ||
          (a.dateTime.year == now.year && a.dateTime.month == now.month && a.dateTime.day >= now.day);
    }).toList();
  }

  void setSelectedDay(int day) {
    _selectedDay = day;
    notifyListeners();
  }

  void setNotes(String value) {
    final key = '${_currentDate.year}-${_currentDate.month}-$_selectedDay';
    _dayNotes[key] = value;
    notifyListeners();
  }

  void previousMonth() {
    _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
    notifyListeners();
  }

  void nextMonth() {
    _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
    notifyListeners();
  }

  bool hasAppointment(int day) {
    return _appointments.any((a) => a.dateTime.day == day && a.dateTime.month == _currentDate.month && a.dateTime.year == _currentDate.year);
  }

  void addAppointment({
    required DateTime dateTime,
    required String type,
    required String patient,
    required String time,
  }) {
    _nextId++;
    _appointments.add(Appointment(
      id: 'apt_$_nextId',
      dateTime: dateTime,
      type: type,
      patient: patient,
      time: time,
    ));
    notifyListeners();
  }

  void removeAppointment(String id) {
    _appointments.removeWhere((a) => a.id == id);
    try {
      final box = Hive.box<AppointmentModel>('appointments');
      box.delete(id);
    } catch (_) {}
    notifyListeners();
  }
}
