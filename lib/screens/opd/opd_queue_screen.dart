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
import '../../widgets/standard_header.dart';

class OpdQueueScreen extends StatefulWidget {
  const OpdQueueScreen({super.key});

  @override
  State<OpdQueueScreen> createState() => _OpdQueueScreenState();
}

class _OpdQueueScreenState extends State<OpdQueueScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  Widget _buildTypeCapsule(OPDRecordModel record) {
    final isFollowUp = record.type == 'follow_up' ||
        record.followUpReason.isNotEmpty;
    final label = isFollowUp ? 'FOLLOW-UP' : 'CONSULTATION';
    final color = isFollowUp ? AppTheme.warning : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTheme.overline.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
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
          const StandardHeader(title: 'OPD Queue'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, d MMMM yyyy').format(
                                _selectedDate,
                              ),
                              style: AppTheme.body.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _isToday ? 'Today' : 'Selected date',
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
              child: ValueListenableBuilder(
                valueListenable: Hive.box<OPDRecordModel>(
                  'opd_records',
                ).listenable(),
                builder: (context, Box<OPDRecordModel> box, _) {
                  final records =
                      box.values
                          .where(
                            (r) =>
                                r.visitDate.year == _selectedDate.year &&
                                r.visitDate.month == _selectedDate.month &&
                                r.visitDate.day == _selectedDate.day,
                          )
                          .toList()
                        ..sort(
                          (a, b) => b.visitDate.compareTo(a.visitDate),
                        );

                  if (records.isEmpty) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.35,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.calendar_month_outlined,
                                size: 40,
                                color: AppTheme.primary.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isToday
                                  ? 'No patients in the queue today'
                                  : 'No appointments scheduled for this day.',
                              style: AppTheme.body.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isToday
                                  ? 'New registrations will appear here'
                                  : 'Select a different date to view records',
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.textHint,
                              ),
                            ),
                            if (_isToday) ...[
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Register Patient'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => context.go('/app/opd/new'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '${records.length} patient${records.length == 1 ? '' : 's'}',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          final patientBox =
                              Hive.box<PatientModel>('patients');
                          final patient = patientBox.get(record.patientId);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PressableCard(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBg,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Hero(
                                        tag: 'queue_avatar_${record.patientId}',
                                        child: CircleAvatar(
                                          radius: 24,
                                          backgroundColor: AppTheme.primary
                                              .withValues(alpha: 0.10),
                                          child: Text(
                                            patient?.name.isNotEmpty == true
                                                ? patient!.name[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    patient?.name ?? 'Unknown',
                                                    style: AppTheme.body.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                _buildTypeCapsule(record),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  'ID: ${record.patientId}',
                                                  style: AppTheme.caption.copyWith(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                                Container(
                                                  margin: const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                                  width: 3,
                                                  height: 3,
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.textHint,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                Text(
                                                  '${patient?.age ?? 0} Years',
                                                  style: AppTheme.caption.copyWith(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                                Container(
                                                  margin: const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                                  width: 3,
                                                  height: 3,
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.textHint,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                Text(
                                                  patient?.gender ?? 'Not Specified',
                                                  style: AppTheme.caption.copyWith(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    record.diagnosis.isNotEmpty
                                                        ? record.diagnosis
                                                        : 'No diagnosis',
                                                    style: AppTheme.caption.copyWith(
                                                      color: AppTheme.textSecondary,
                                                      fontSize: 12,
                                                      height: 1.4,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                GestureDetector(
                                                  onTap: () => context.push(
                                                    '/app/prescription/${record.patientId}',
                                                  ),
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.only(left: 2),
                                                    child: Icon(
                                                      Icons.visibility_outlined,
                                                      size: 18,
                                                      color: AppTheme.primary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isToday
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              elevation: 4,
              onPressed: () {
                context.read<OpdProvider>().reset();
                context.go('/app/opd/new');
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'New OPD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            )
          : null,
    );
  }
}
