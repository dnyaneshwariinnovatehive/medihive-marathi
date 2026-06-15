import 'package:hive/hive.dart';

part 'patient_model.g.dart';

@HiveType(typeId: 0)
class PatientModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String dob;

  @HiveField(3)
  final int age;

  @HiveField(4)
  final String mobile;

  @HiveField(5)
  final String address;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8)
  final bool isSynced;

  @HiveField(9)
  final String gender;

  @HiveField(10)
  final String bloodGroup;

  PatientModel({
    required this.id,
    required this.name,
    required this.dob,
    required this.age,
    required this.mobile,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.gender = 'Not Specified',
    this.bloodGroup = 'Not Specified',
  });

  PatientModel copyWith({
    String? id,
    String? name,
    String? dob,
    int? age,
    String? mobile,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? gender,
    String? bloodGroup,
  }) {
    return PatientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      age: age ?? this.age,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
    );
  }
}
