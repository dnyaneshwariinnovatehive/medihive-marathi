import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/patient.dart';
import '../../models/patient_model.dart';
import '../../models/opd_record_model.dart';
import '../../widgets/section_card.dart';
import '../../widgets/visit_timeline_item.dart';

class PatientDetailsScreen extends StatelessWidget {
  final String patientId;
  const PatientDetailsScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<PatientModel>('patients');
    final pModel = box.values.cast<PatientModel?>().firstWhere(
      (p) => p?.id == patientId,
      orElse: () => null,
    );

    if (pModel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Details')),
        body: const Center(child: Text('Patient not found')),
      );
    }

    final patient = PatientDetail(
      id: pModel.id,
      name: pModel.name,
      age: pModel.age,
      gender: pModel.gender.isNotEmpty ? pModel.gender : 'Unknown',
      mobile: pModel.mobile,
      dob: pModel.dob,
      bloodGroup: pModel.bloodGroup.isNotEmpty ? pModel.bloodGroup : 'Unknown',
      address: pModel.address,
    );

    final opdBox = Hive.box<OPDRecordModel>('opd_records');
    final records = opdBox.values.where((r) => r.patientId == patientId).toList();
    records.sort((a, b) => b.visitDate.compareTo(a.visitDate));
    
    final visits = records.map((r) => VisitRecord(
      date: DateFormat('dd MMM yyyy').format(r.visitDate),
      type: r.type.isNotEmpty ? r.type : 'Consultation',
      diagnosis: r.diagnosis.isNotEmpty ? r.diagnosis : 'No diagnosis',
      notes: r.symptoms.isNotEmpty ? r.symptoms : 'No notes',
      fees: 0,
    )).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with patient profile
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Color(0x30000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    children: [
                      Row(children: [
                        GestureDetector(
                          onTap: () => context.go('/app/patients'),
                          child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        ),
                        SizedBox(width: 12),
                        Text('Patient Details', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                      ]),
                      SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(children: [
                              CircleAvatar(radius: 36, backgroundColor: Colors.white,
                                child: Text(patient.initial, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primary))),
                              SizedBox(width: 16),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(patient.name, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                Text('${patient.id} • ${patient.gender}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                              ]),
                            ]),
                            SizedBox(height: 12),
                            Row(children: [
                              _glassTile('Age', '${patient.age} years'),
                              SizedBox(width: 12),
                              _glassTile('Blood Group', patient.bloodGroup),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Contact Info
                  SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Contact Information', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary)),
                    SizedBox(height: 16),
                    _contactRow(Icons.phone, 'Mobile Number', patient.mobile),
                    SizedBox(height: 12),
                    _contactRow(Icons.location_on, 'Address', patient.address),
                    SizedBox(height: 12),
                    _contactRow(Icons.calendar_today, 'Date of Birth', patient.dob),
                  ])),
                  SizedBox(height: 16),
                  // Visit History
                  SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Visit History', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary)),
                    SizedBox(height: 16),
                    ...visits.asMap().entries.map((e) =>
                      VisitTimelineItem(visit: e.value, isLast: e.key == visits.length - 1)),
                  ])),
                  SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: ElevatedButton.icon(
                      onPressed: () => context.go('/app/prescription/$patientId'),
                      icon: Icon(Icons.description, size: 20),
                      label: Text('View Prescription'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )),
                    SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white, border: Border.all(color: AppTheme.border, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.share, size: 20, color: AppTheme.textPrimary),
                    ),
                  ]),
                  SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: AppTheme.primary, size: 20),
      SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
      ])),
    ]);
  }
}


