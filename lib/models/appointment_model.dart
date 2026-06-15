import 'package:hive/hive.dart';

part 'appointment_model.g.dart';

@HiveType(typeId: 2)
class AppointmentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String patientId;

  @HiveField(2)
  final DateTime dateTime;

  @HiveField(3)
  final String notes;

  @HiveField(4)
  final bool isSynced;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.dateTime,
    required this.notes,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
  });

  AppointmentModel copyWith({
    String? id,
    String? patientId,
    DateTime? dateTime,
    String? notes,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
