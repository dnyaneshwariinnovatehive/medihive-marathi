class Appointment {
  final String id;
  final DateTime dateTime;
  final String type;
  final String patient;
  final String time;

  int get date => dateTime.day;

  const Appointment({
    required this.id,
    required this.dateTime,
    required this.type,
    required this.patient,
    required this.time,
  });
}
