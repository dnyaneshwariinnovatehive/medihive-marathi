import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/opd_record_model.dart';
import '../../models/patient_model.dart';
import '../../providers/opd_provider.dart';
import 'package:intl/intl.dart';

class OpdQueueScreen extends StatelessWidget {
  const OpdQueueScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.success;
      case 'in progress':
        return AppTheme.primary;
      case 'cancelled':
        return AppTheme.danger;
      case 'waiting':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('OPD Queue', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Show history or filters
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<OPDRecordModel>('opd_records').listenable(),
        builder: (context, Box<OPDRecordModel> box, _) {
          final today = DateTime.now();
          final records = box.values.where((r) =>
              r.visitDate.year == today.year &&
              r.visitDate.month == today.month &&
              r.visitDate.day == today.day).toList()
            ..sort((a, b) => b.visitDate.compareTo(a.visitDate));

          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: AppTheme.primary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No patients in the queue today',
                    style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Register Patient'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => context.go('/app/opd/new'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final patientBox = Hive.box<PatientModel>('patients');
              final patient = patientBox.get(record.patientId);
              
              final status = record.type.isEmpty ? 'waiting' : record.type;

              return Dismissible(
                key: Key(record.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm"),
                        content: const Text("Are you sure you want to remove this record?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("CANCEL"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("DELETE", style: TextStyle(color: AppTheme.danger)),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  record.delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Record removed')),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shadowColor: AppTheme.cardShadow.first.color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text(
                        patient?.name.isNotEmpty == true ? patient!.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      patient?.name ?? 'Unknown',
                      style: AppTheme.body.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('ID: ${record.patientId} • ${record.type == 'follow_up' ? 'Follow-up' : 'Consultation'}'),
                        const SizedBox(height: 4),
                        Text('Time: ${DateFormat.jm().format(record.visitDate)}'),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: AppTheme.caption.copyWith(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      // View details
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        onPressed: () {
          context.read<OpdProvider>().reset();
          context.go('/app/opd/new');
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New OPD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
