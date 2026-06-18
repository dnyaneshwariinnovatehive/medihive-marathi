import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/patient.dart';
import '../../models/patient_model.dart';
import '../../models/opd_record_model.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/section_card.dart';
import '../../widgets/visit_timeline_item.dart';

List<Map<String, String?>> _decodeMedicinesFromJson(String json) {
  final decoded = jsonDecode(json);
  if (decoded is List) {
    return decoded.map((e) => {
      'name': e['name']?.toString(),
      'dosage': e['dosage']?.toString(),
      'duration': e['duration']?.toString(),
    }).toList();
  }
  return [];
}

class PatientDetailsScreen extends StatelessWidget {
  final String patientId;
  const PatientDetailsScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
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
    
    final visits = records.map((r) {
      final consultation = int.tryParse(r.consultationFee) ?? 0;
      final medicine = int.tryParse(r.medicineFee) ?? 0;
      final disc = int.tryParse(r.discount) ?? 0;
      final totalFee = consultation + medicine - disc;
      return VisitRecord(
        date: DateFormat('dd MMM yyyy').format(r.visitDate),
        type: r.type.isNotEmpty ? r.type : 'Consultation',
        diagnosis: r.diagnosis.isNotEmpty ? r.diagnosis : 'No diagnosis',
        notes: r.symptoms.isNotEmpty ? r.symptoms : 'No notes',
        fees: totalFee > 0 ? totalFee : 0,
      );
    }).toList();

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
                  bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Color(0x30000000), blurRadius: 16, offset: Offset(0, 6)),
                  BoxShadow(color: Color(0x18000000), blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  child: Column(
                    children: [
                      Row(children: [
                        GestureDetector(
                          onTap: () => context.go('/app/patients'),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Patient Details', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                      ]),
                      SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                            child: Column(
                              children: [
                                Row(children: [
                              Hero(tag: 'patient_avatar_${patient.id}', child: CircleAvatar(radius: 40, backgroundColor: Colors.white,
                                child: Text(patient.initial, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary)))),
                              SizedBox(width: 16),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(patient.name, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
                                SizedBox(height: 4),
                                Text('${patient.id} • ${patient.gender}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                              ]),
                            ]),
                            SizedBox(height: 16),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    )),
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final opdBox = Hive.box<OPDRecordModel>('opd_records');
                        final records = opdBox.values.where((r) => r.patientId == patientId).toList();
                        records.sort((a, b) => b.visitDate.compareTo(a.visitDate));
                        final latest = records.isNotEmpty ? records.first : null;

                        final settings = context.read<SettingsProvider>();
                        final buffer = StringBuffer()
                          ..writeln(settings.clinicName)
                          ..writeln(settings.clinicAddress)
                          ..writeln('Phone: ${settings.clinicPhone}')
                          ..writeln('License: ${settings.doctorLicense}')
                          ..writeln('')
                          ..writeln('Patient: ${patient.name} (${patient.id})')
                          ..writeln('Age: ${patient.age} yrs | Gender: ${patient.gender}')
                          ..writeln('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}')
                          ..writeln('');

                        if (latest != null) {
                          if (latest.diagnosis.isNotEmpty) {
                            buffer.writeln('Diagnosis: ${latest.diagnosis}');
                          }
                          if (latest.symptoms.isNotEmpty) {
                            buffer.writeln('Symptoms: ${latest.symptoms}');
                          }
                          if (latest.medicines.isNotEmpty) {
                            buffer.writeln('');
                            buffer.writeln('Medicines:');
                            try {
                              final decoded = _decodeMedicinesFromJson(latest.medicines);
                              if (decoded.isNotEmpty) {
                                for (final m in decoded) {
                                  buffer.writeln('- ${m['name']} (${m['dosage'] ?? ''}${m['dosage'] != null && m['dosage']!.isNotEmpty ? ', ' : ''}${m['duration'] ?? ''})');
                                }
                              } else {
                                for (final m in latest.medicines.split(',')) {
                                  if (m.trim().isNotEmpty) buffer.writeln('- ${m.trim()}');
                                }
                              }
                            } catch (_) {
                              for (final m in latest.medicines.split(',')) {
                                if (m.trim().isNotEmpty) buffer.writeln('- ${m.trim()}');
                              }
                            }
                          }
                          if (latest.clinicalNotes.isNotEmpty) {
                            buffer.writeln('');
                            buffer.writeln('Notes: ${latest.clinicalNotes}');
                          }
                          if (latest.nextVisit.isNotEmpty) {
                            buffer.writeln('');
                            buffer.writeln('Next Visit: ${latest.nextVisit}');
                          }
                        }
                        buffer.writeln('Doctor: ${settings.doctorName}');

                        final mob = patient.mobile.replaceAll(RegExp(r'[^0-9]'), '');
                        if (mob.length == 10) {
                          final waUri = Uri.parse('https://wa.me/91$mob?text=${Uri.encodeComponent(buffer.toString())}');
                          try {
                            await launchUrl(waUri, mode: LaunchMode.externalApplication);
                            return;
                          } catch (_) {
                          }
                        }
                        Share.share(buffer.toString());
                      },
                      icon: Icon(Icons.share, size: 20),
                      label: Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, foregroundColor: AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: AppTheme.border, width: 2),
                        elevation: 0,
                      ),
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


