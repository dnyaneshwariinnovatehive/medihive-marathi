import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/opd_record_model.dart';
import '../../models/patient_model.dart';
import '../../providers/opd_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/pressable_card.dart';

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
        return const Color(0xFFF0A500);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        controller: ScrollController(),
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: AppTheme.primary,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 14),
              expandedTitleScale: 1.0,
              title: Row(
                children: [
                  GestureDetector(
                    onTap: () => StatefulNavigationShell.of(context).goBranch(0),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'OPD Queue',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.only(top: 50, left: 8, right: 16, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => StatefulNavigationShell.of(context).goBranch(0),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'OPD Queue',
                          style: AppTheme.heading.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'Today\'s patient queue',
                        style: AppTheme.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
              child: ValueListenableBuilder(
                valueListenable: Hive.box<OPDRecordModel>('opd_records').listenable(),
                builder: (context, Box<OPDRecordModel> box, _) {
                  final today = DateTime.now();
                  final records = box.values.where((r) =>
                      r.visitDate.year == today.year &&
                      r.visitDate.month == today.month &&
                      r.visitDate.day == today.day).toList()
                    ..sort((a, b) => b.visitDate.compareTo(a.visitDate));

                  if (records.isEmpty) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.people_outline, size: 48, color: AppTheme.primary.withValues(alpha: 0.5)),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No patients in the queue today',
                              style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'New registrations will appear here',
                              style: AppTheme.caption.copyWith(color: AppTheme.textHint),
                            ),
                            const SizedBox(height: 28),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Register Patient'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => context.go('/app/opd/new'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final patientBox = Hive.box<PatientModel>('patients');
                      final patient = patientBox.get(record.patientId);

                      final status = record.type.isEmpty ? 'waiting' : record.type;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Dismissible(
                          key: Key(record.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppTheme.danger,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: const Text('Confirm'),
                                  content: const Text('Remove this record from the queue?'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('CANCEL'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: Text('REMOVE', style: TextStyle(color: AppTheme.danger)),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) {
                            record.delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Record removed'), duration: Duration(seconds: 2)),
                            );
                          },
                          child: PressableCard(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Hero(
                                      tag: 'queue_avatar_${record.patientId}',
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                                        child: Text(
                                          patient?.name.isNotEmpty == true ? patient!.name[0].toUpperCase() : '?',
                                          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            patient?.name ?? 'Unknown',
                                            style: AppTheme.subHeading.copyWith(fontSize: 15),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.folder_outlined, size: 12, color: AppTheme.textHint),
                                              const SizedBox(width: 4),
                                              Text(
                                                'ID: ${record.patientId}',
                                                style: AppTheme.caption.copyWith(color: AppTheme.textSecondary, fontSize: 11),
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(Icons.access_time, size: 12, color: AppTheme.textHint),
                                              const SizedBox(width: 4),
                                              Text(
                                                DateFormat.jm().format(record.visitDate),
                                                style: AppTheme.caption.copyWith(color: AppTheme.textSecondary, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status).withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: AppTheme.overline.copyWith(
                                          color: _getStatusColor(status),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        elevation: 4,
        onPressed: () {
          context.read<OpdProvider>().reset();
          context.go('/app/opd/new');
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New OPD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
