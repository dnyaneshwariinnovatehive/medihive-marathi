import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../../theme/app_theme.dart';
import '../../providers/appointment_provider.dart';
import '../../models/patient_model.dart';
import '../../widgets/section_card.dart';
import '../../utils/constants.dart';

import 'package:flutter/rendering.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;
  late AnimationController _fadeController;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.position.userScrollDirection == ScrollDirection.forward;
      if (show != _showFab) {
        setState(() => _showFab = show);
      }
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Set<String> get _registeredPatientNames {
    try {
      return Hive.box<PatientModel>('patients').values.map((p) => p.name.toLowerCase()).toSet();
    } catch (_) {
      return {};
    }
  }

  bool _isPatientRegistered(String name) {
    return _registeredPatientNames.contains(name.trim().toLowerCase());
  }

  void _confirmDeleteAppointment(BuildContext context, AppointmentProvider apt, String id, String patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Appointment', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
        content: Text('Remove appointment for $patient?', style: AppTheme.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              apt.removeAppointment(id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Appointment for $patient removed'),
                  backgroundColor: AppTheme.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  void _showAddAppointmentDialog(BuildContext context, AppointmentProvider apt) {
    final patientController = TextEditingController();
    String selectedType = 'Consultation';
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: AppTheme.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, color: AppTheme.primary, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Book Appointment',
                                style: AppTheme.subHeading.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        'Patient Name',
                        style: AppTheme.label.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: patientController,
                        style: AppTheme.body,
                        decoration: InputDecoration(
                          hintText: 'Enter patient name',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Appointment Type',
                        style: AppTheme.label.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Consultation')),
                              selected: selectedType == 'Consultation',
                              selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                              labelStyle: AppTheme.label.copyWith(
                                color: selectedType == 'Consultation' ? AppTheme.primary : AppTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (val) {
                                if (val) setStateDialog(() => selectedType = 'Consultation');
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Follow-up')),
                              selected: selectedType == 'Follow-up',
                              selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                              labelStyle: AppTheme.label.copyWith(
                                color: selectedType == 'Follow-up' ? AppTheme.primary : AppTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (val) {
                                if (val) setStateDialog(() => selectedType = 'Follow-up');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Time',
                        style: AppTheme.label.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(45),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setStateDialog(() => selectedTime = time);
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(selectedTime.format(context)),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                if (patientController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Please enter patient name'),
                                      backgroundColor: AppTheme.danger,
                                    ),
                                  );
                                  return;
                                }
                                apt.addAppointment(
                                  dateTime: DateTime(apt.currentDate.year, apt.currentDate.month, apt.selectedDay),
                                  type: selectedType,
                                  patient: patientController.text.trim(),
                                  time: selectedTime.format(context),
                                );
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Appointment scheduled for ${patientController.text.trim()}!'),
                                    backgroundColor: AppTheme.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final apt = context.watch<AppointmentProvider>();
    
    if (_notesController.text != apt.notes) {
      _notesController.text = apt.notes;
    }

    final daysInMonth = DateTime(apt.currentDate.year, apt.currentDate.month + 1, 0).day;
    final firstDay = DateTime(apt.currentDate.year, apt.currentDate.month, 1).weekday % 7;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ═══════════════════════════════════════════════════
          // PREMIUM GRADIENT SLIVER APP BAR (180px)
          // ═══════════════════════════════════════════════════
          SliverAppBar(
            expandedHeight: 180,
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
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Calendar & Scheduler',
                      style: AppTheme.heading.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage daily clinic bookings & patient visits',
                      style: AppTheme.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FadeTransition(
                opacity: _fadeController,
                child: Column(
                  children: [
                    // Calendar monthly control Card
                    SectionCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: apt.previousMonth,
                                icon: const Icon(Icons.chevron_left, color: AppTheme.primary, size: 28),
                              ),
                              Text(
                                '${AppConstants.monthNames[apt.currentDate.month - 1]} ${apt.currentDate.year}',
                                style: AppTheme.subHeading.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              IconButton(
                                onPressed: apt.nextMonth,
                                icon: const Icon(Icons.chevron_right, color: AppTheme.primary, size: 28),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Day headers uppercase styled
                          Row(
                            children: AppConstants.dayAbbreviations.map((d) {
                              return Expanded(
                                child: Center(
                                  child: Text(
                                    d.toUpperCase(),
                                    style: AppTheme.caption.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          // Day grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: firstDay + daysInMonth,
                            itemBuilder: (context, index) {
                              if (index < firstDay) return const SizedBox.shrink();
                              final day = index - firstDay + 1;

                              final now = DateTime.now();
                              final cellDate = DateTime(apt.currentDate.year, apt.currentDate.month, day);
                              final today = DateTime(now.year, now.month, now.day);
                              final isPastDate = cellDate.isBefore(today);
                              final isToday = cellDate.isAtSameMomentAs(today);

                              final isSelected = day == apt.selectedDay;
                              final dayApts = apt.appointments.where((a) => a.date == day && _isPatientRegistered(a.patient)).toList();
                              final aptCount = dayApts.length;

                              final cell = Container(
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : isToday
                                          ? AppTheme.primary.withValues(alpha: 0.12)
                                          : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: isToday
                                      ? Border.all(color: AppTheme.primary, width: 1.5)
                                      : null,
                                  boxShadow: isSelected ? AppTheme.cardShadow : null,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Positioned(
                                      top: 8,
                                      child: Text(
                                        '$day',
                                        style: AppTheme.body.copyWith(
                                          fontSize: 14,
                                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : isToday
                                                  ? AppTheme.primary
                                                  : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (aptCount > 0)
                                      Positioned(
                                        bottom: 6,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: List.generate(
                                            aptCount.clamp(1, 3),
                                            (idx) => Container(
                                              width: 4,
                                              height: 4,
                                              margin: const EdgeInsets.symmetric(horizontal: 1),
                                              decoration: BoxDecoration(
                                                color: isSelected ? Colors.white : AppTheme.primaryLight,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );

                              if (isPastDate) {
                                return IgnorePointer(
                                  ignoring: true,
                                  child: Opacity(
                                    opacity: 0.25,
                                    child: cell,
                                  ),
                                );
                              }

                              return GestureDetector(
                                onTap: () => apt.setSelectedDay(day),
                                child: cell,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Appointments for selected day list card
                    Builder(
                      builder: (context) {
                        final selectedCellDate = DateTime(apt.currentDate.year, apt.currentDate.month, apt.selectedDay);
                        final isPastDateSelected = selectedCellDate.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
                        return SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Appointments for ${apt.selectedDay} ${AppConstants.monthNames[apt.currentDate.month - 1]}',
                                    style: AppTheme.subHeading.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: isPastDateSelected
                                        ? () {
                                            ScaffoldMessenger.of(context).clearSnackBars();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: const Text('Cannot schedule appointments for past dates'),
                                                backgroundColor: AppTheme.danger,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            );
                                          }
                                        : () => _showAddAppointmentDialog(context, apt),
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: isPastDateSelected ? Colors.transparent : AppTheme.primary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        color: isPastDateSelected ? AppTheme.textHint : AppTheme.primary,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (apt.selectedDayAppointments.where((a) => _isPatientRegistered(a.patient)).isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 36),
                                  child: Center(
                                    child: Text(
                                      'No appointments scheduled',
                                      style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
                                    ),
                                  ),
                                )
                              else
                                ...apt.selectedDayAppointments.where((a) => _isPatientRegistered(a.patient)).map((a) => Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: const Border(
                                          left: BorderSide(color: AppTheme.primary, width: 4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.person_outline, color: AppTheme.primary, size: 18),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    a.patient,
                                                    style: AppTheme.body.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: a.type == 'Follow-up'
                                                          ? AppTheme.success.withValues(alpha: 0.15)
                                                          : AppTheme.primary.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      a.type,
                                                      style: AppTheme.caption.copyWith(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: a.type == 'Follow-up' ? AppTheme.success : AppTheme.primaryLight,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                                              const SizedBox(width: 4),
                                              Text(
                                                a.time,
                                                style: AppTheme.caption.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              GestureDetector(
                                                onTap: () => _confirmDeleteAppointment(context, apt, a.id, a.patient),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.danger.withValues(alpha: 0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(Icons.delete_outline, color: AppTheme.danger, size: 18),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Notes for day
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Day Notes',
                                style: AppTheme.subHeading.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const Icon(Icons.edit_note, color: AppTheme.primary, size: 24),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            onChanged: apt.addNote,
                            maxLines: 3,
                            style: AppTheme.body,
                            decoration: InputDecoration(
                              hintText: 'Add clinical reminders, doctor schedule notes for this day...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.border),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Upcoming Follow-ups beautiful gradient card
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final followUps = apt.upcomingFollowUps;
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: AppTheme.background,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                            builder: (context) => Container(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Upcoming Follow-ups', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                  const SizedBox(height: 16),
                                  if (followUps.isEmpty)
                                    const Text('No upcoming follow-ups.')
                                  else
                                    ...followUps.map((f) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(backgroundColor: AppTheme.primary.withValues(alpha: 0.1), child: const Icon(Icons.person, color: AppTheme.primary)),
                                      title: Text(f.patient, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Text('Date: ${f.dateTime.day}/${f.dateTime.month}/${f.dateTime.year} | Time: ${f.time}'),
                                    )),
                                ],
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppTheme.heavyShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upcoming Follow-ups',
                                style: AppTheme.caption.copyWith(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                              ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  '${apt.upcomingFollowUps.length} Scheduled',
                                style: AppTheme.display.copyWith(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
