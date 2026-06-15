import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:medihive/main.dart';
import 'package:medihive/models/patient_model.dart';
import 'package:medihive/models/opd_record_model.dart';
import 'package:medihive/models/appointment_model.dart';

void main() {
  setUp(() async {
    Hive.init('test/.temp_hive');
    Hive.registerAdapter(PatientModelAdapter());
    Hive.registerAdapter(OPDRecordModelAdapter());
    Hive.registerAdapter(AppointmentModelAdapter());
    await Hive.openBox<PatientModel>('patients');
    await Hive.openBox<OPDRecordModel>('opd_records');
    await Hive.openBox<AppointmentModel>('appointments');
    await Hive.openBox('drafts');
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('patients');
    await Hive.deleteBoxFromDisk('opd_records');
    await Hive.deleteBoxFromDisk('appointments');
    await Hive.deleteBoxFromDisk('drafts');
  });

  testWidgets('MediHive app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MediHiveApp());
    await tester.pump();
    expect(find.byType(MediHiveApp), findsOneWidget);
  });
}
