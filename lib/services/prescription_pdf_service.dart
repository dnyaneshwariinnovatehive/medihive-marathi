import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/prescription.dart';

class PrescriptionPdfService {
  static Future<Uint8List> generatePdf(Prescription rx, {bool includePatientDetails = true}) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header (Clinic details)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(color: PdfColors.blueGrey800),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(rx.clinicName, style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(rx.clinicAddress, style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Phone: ${rx.clinicPhone}', style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                        pw.Text('Lic: ${rx.licenseNo}', style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Doctor & Date
              pw.Padding(
                padding: const pw.EdgeInsets.all(16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(rx.doctorName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        pw.Text(rx.date, style: const pw.TextStyle(fontSize: 14)),
                      ],
                    ),
                    pw.SizedBox(height: 16),
                    
                    // Patient Info
                    if (includePatientDetails)
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                _infoBlock('Patient Name', rx.patientName),
                                _infoBlock('Patient ID', rx.patientId),
                              ],
                            ),
                            pw.SizedBox(height: 8),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                _infoBlock('Age / Gender', '${rx.age} / ${rx.gender}'),
                                _infoBlock('Diagnosis', rx.diagnosis),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (includePatientDetails) pw.SizedBox(height: 24),
                    
                    // Medicines
                    pw.Text('Medicines Prescribed', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Divider(),
                    pw.SizedBox(height: 8),
                    ...rx.medicines.asMap().entries.map((e) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('${e.key + 1}. '),
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(e.value.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                  pw.Text('Dosage: ${e.value.dosage}', style: const pw.TextStyle(color: PdfColors.grey700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    
                    pw.SizedBox(height: 24),
                    
                    // Notes
                    pw.Text('Instructions', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Divider(),
                    pw.SizedBox(height: 8),
                    pw.Text(rx.notes),
                    pw.SizedBox(height: 16),
                    pw.Text('Panchakarma Notes', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Divider(),
                    pw.SizedBox(height: 8),
                    pw.Text(rx.panchakarmaNotes.isNotEmpty ? rx.panchakarmaNotes : 'None'),
                    pw.SizedBox(height: 24),
                    
                    pw.Text('Next Visit: ${rx.nextVisit}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _infoBlock(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
