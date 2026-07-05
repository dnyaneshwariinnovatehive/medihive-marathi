class OpdFormData {
  String patientId;
  String name;
  String dob;
  String age;
  String gender;
  String mobile;
  String address;
  String bloodGroup;
  String diagnosis;
  String symptoms;
  String opdType;
  String chargeType;
  String medicines;
  String clinicalNotes;
  String panchakarmaNotes;
  String nextVisit;
  String consultationFee;
  String medicineFee;
  String discount;
  String paymentMode;
  String previousVisitDate;
  String followUpReason;

  OpdFormData({
    this.patientId = '',
    this.name = '',
    this.dob = '',
    this.age = '',
    this.gender = 'Male',
    this.mobile = '',
    this.address = '',
    this.bloodGroup = 'O+',
    this.diagnosis = '',
    this.symptoms = '',
    this.opdType = 'Consultation',
    this.chargeType = 'Cash',
    this.medicines = '',
    this.clinicalNotes = '',
    this.panchakarmaNotes = '',
    this.nextVisit = '',
    this.consultationFee = '500',
    this.medicineFee = '0',
    this.discount = '0',
    this.paymentMode = 'Cash',
    this.previousVisitDate = '',
    this.followUpReason = '',
  });

  int get totalFee =>
      (int.tryParse(consultationFee) ?? 0) +
      (int.tryParse(medicineFee) ?? 0) -
      (int.tryParse(discount) ?? 0);

  void reset() {
    patientId = '';
    name = '';
    dob = '';
    age = '';
    gender = 'Male';
    mobile = '';
    address = '';
    bloodGroup = 'O+';
    diagnosis = '';
    symptoms = '';
    opdType = 'Consultation';
    chargeType = 'Cash';
    medicines = '';
    clinicalNotes = '';
    panchakarmaNotes = '';
    nextVisit = '';
    consultationFee = '500';
    medicineFee = '0';
    discount = '0';
    paymentMode = 'Cash';
    previousVisitDate = '';
    followUpReason = '';
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'name': name,
      'dob': dob,
      'age': age,
      'gender': gender,
      'mobile': mobile,
      'address': address,
      'bloodGroup': bloodGroup,
      'diagnosis': diagnosis,
      'symptoms': symptoms,
      'opdType': opdType,
      'chargeType': chargeType,
      'medicines': medicines,
      'clinicalNotes': clinicalNotes,
      'panchakarmaNotes': panchakarmaNotes,
      'nextVisit': nextVisit,
      'consultationFee': consultationFee,
      'medicineFee': medicineFee,
      'discount': discount,
      'paymentMode': paymentMode,
      'previousVisitDate': previousVisitDate,
      'followUpReason': followUpReason,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    patientId = json['patientId'] ?? '';
    name = json['name'] ?? '';
    dob = json['dob'] ?? '';
    age = json['age'] ?? '';
    gender = json['gender'] ?? 'Male';
    mobile = json['mobile'] ?? '';
    address = json['address'] ?? '';
    bloodGroup = json['bloodGroup'] ?? 'O+';
    diagnosis = json['diagnosis'] ?? '';
    symptoms = json['symptoms'] ?? '';
    opdType = json['opdType'] ?? 'Consultation';
    chargeType = json['chargeType'] ?? 'Cash';
    medicines = json['medicines'] ?? '';
    clinicalNotes = json['clinicalNotes'] ?? '';
    panchakarmaNotes = json['panchakarmaNotes'] ?? '';
    nextVisit = json['nextVisit'] ?? '';
    consultationFee = json['consultationFee'] ?? '500';
    medicineFee = json['medicineFee'] ?? '0';
    discount = json['discount'] ?? '0';
    paymentMode = json['paymentMode'] ?? 'Cash';
    previousVisitDate = json['previousVisitDate'] ?? '';
    followUpReason = json['followUpReason'] ?? '';
  }
}
