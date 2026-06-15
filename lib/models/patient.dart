class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String mobile;
  final String lastVisit;
  final String dob;
  final int visitCount;
  final String diagnosis;

  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.mobile,
    required this.lastVisit,
    required this.dob,
    this.visitCount = 1,
    this.diagnosis = '',
  });

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  Patient copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? mobile,
    String? lastVisit,
    String? dob,
    int? visitCount,
    String? diagnosis,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      mobile: mobile ?? this.mobile,
      lastVisit: lastVisit ?? this.lastVisit,
      dob: dob ?? this.dob,
      visitCount: visitCount ?? this.visitCount,
      diagnosis: diagnosis ?? this.diagnosis,
    );
  }
}

class PatientDetail {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String mobile;
  final String dob;
  final String bloodGroup;
  final String address;

  const PatientDetail({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.mobile,
    required this.dob,
    required this.bloodGroup,
    required this.address,
  });

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}

class VisitRecord {
  final String date;
  final String type;
  final String diagnosis;
  final String notes;
  final int fees;

  const VisitRecord({
    required this.date,
    required this.type,
    required this.diagnosis,
    required this.notes,
    required this.fees,
  });
}
