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

  @HiveField(11)
  final double? weight;

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
    this.weight,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dob': dob,
    'age': age,
    'gender': gender,
    'blood_group': bloodGroup,
    'mobile': mobile,
    'address': address,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_synced': isSynced ? 1 : 0,
    'weight': weight,
  };

  factory PatientModel.fromJson(Map<String, dynamic> json) => PatientModel(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    dob: json['dob']?.toString() ?? '',
    age: int.tryParse(json['age']?.toString() ?? '') ?? 0,
    gender: json['gender']?.toString() ?? 'Not Specified',
    bloodGroup: json['blood_group']?.toString() ?? 'Not Specified',
    mobile: json['mobile']?.toString() ?? '',
    address: json['address']?.toString() ?? '',
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    isSynced: json['is_synced'] == true || json['is_synced'] == 1,
    weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
  );

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
    double? weight,
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
      weight: weight ?? this.weight,
    );
  }
}
