import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/patient_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/patient.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/pressable_card.dart';

import 'package:flutter/rendering.dart';

class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({super.key});

  @override
  State<PatientManagementScreen> createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().loadPatients();
    });
    _scrollController.addListener(() {
      final show = _scrollController.position.userScrollDirection == ScrollDirection.forward;
      if (show != _showFab) {
        setState(() => _showFab = show);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTheme.caption.copyWith(
          fontSize: 11,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showSortFilterDialog(BuildContext context, PatientProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 16),
                child: Text('Sort Patients', style: AppTheme.heading),
              ),
              _buildSortOption(provider, 'Recent Visit First', 'recent_visit', Icons.access_time),
              _buildSortOption(provider, 'Oldest Visit First', 'oldest_visit', Icons.history),
              _buildSortOption(provider, 'Name (A-Z)', 'name_asc', Icons.sort_by_alpha),
              _buildSortOption(provider, 'Name (Z-A)', 'name_desc', Icons.sort_by_alpha),
              _buildSortOption(provider, 'Patient ID', 'id_asc', Icons.numbers),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(PatientProvider provider, String title, String value, IconData icon) {
    final isSelected = provider.sortFilter == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primary) : null,
      onTap: () {
        provider.setSortFilter(value);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    final provider = context.watch<PatientProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ═══════════════════════════════════════════════════
          // PREMIUM GRADIENT HEADER WITH SEARCH
          // ═══════════════════════════════════════════════════
          SliverAppBar(
            expandedHeight: 160,
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
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Patient Management',
                          style: AppTheme.heading.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showSortFilterDialog(context, provider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.tune_outlined, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Filter',
                                  style: AppTheme.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${provider.displayedPatients.length} Patients Registered',
                      style: AppTheme.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Embedded search bar just before curve ends
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: TextField(
                        onChanged: provider.onSearchChanged,
                        style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search name, ID, mobile, or diagnosis...',
                          hintStyle: AppTheme.body.copyWith(color: AppTheme.textHint),
                          prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════
          // PATIENTS LIST / EMPTY STATES
          // ═══════════════════════════════════════════════════
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Builder(
                builder: (context) {
                  if (provider.isSearching) {
                    return Column(
                      children: const [
                        ShimmerLoadingCard(),
                        ShimmerLoadingCard(),
                        ShimmerLoadingCard(),
                      ],
                    );
                  } else if (provider.filteredPatients.isEmpty) {
                    // Premium consistent empty state
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.people_outline,
                              size: 48,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No Patients Yet',
                            style: AppTheme.heading.copyWith(color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first patient via OPD Registration',
                            style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/app/opd'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('New OPD'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    final patientList = provider.filteredPatients;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: ListView.builder(
                        key: ValueKey<String>(provider.searchQuery),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: patientList.length,
                        itemBuilder: (context, index) {
                          final Patient patient = patientList[index];
                          final name = patient.name;
                          final id = patient.id;
                          final age = patient.age;
                          final gender = patient.gender;
                          final lastDiagnosis = patient.diagnosis.isNotEmpty ? patient.diagnosis : 'No diagnosis';
                          final lastVisitDate = patient.lastVisit;

                          return AnimatedListItem(
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PressableCard(
                                onTap: () => context.go('/app/patients/$id'),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBg,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: AppTheme.cardShadow,
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Hero(
                                        tag: 'patient_avatar_$id',
                                        child: CircleAvatar(
                                          radius: 24,
                                          backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                                          child: Text(
                                            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P',
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
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: AppTheme.body.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                _buildInfoChip('ID: $id'),
                                                const SizedBox(width: 6),
                                                _buildInfoChip('Age: $age'),
                                                const SizedBox(width: 6),
                                                _buildInfoChip(gender),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              lastDiagnosis,
                                              style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            lastVisitDate,
                                            style: AppTheme.caption.copyWith(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                onTap: () => context.go('/app/patients/$id'),
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(Icons.visibility_outlined, size: 16, color: AppTheme.primary),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              GestureDetector(
                                                onTap: () => context.go('/app/opd/edit/$id'),
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.warning.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(Icons.edit_outlined, size: 16, color: AppTheme.warning),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              GestureDetector(
                                                onTap: () async {
                                                  final confirmed = await showDialog<bool>(
                                                    context: context,
                                                    builder: (ctx) => AlertDialog(
                                                      title: const Text('Delete OPD'),
                                                      content: Text('Delete all OPD records of $name?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(ctx, false),
                                                          child: const Text('Cancel'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(ctx, true),
                                                          style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
                                                          child: const Text('Delete'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirmed == true && context.mounted) {
                                                    await context.read<PatientProvider>().deletePatientAndRecords(id);
                                                  }
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.danger.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(Icons.delete_outline, size: 16, color: AppTheme.danger),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedSlide(
        offset: _showFab ? Offset.zero : const Offset(0, 2.5),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: FloatingActionButton(
          onPressed: () => context.go('/app/opd'),
          backgroundColor: AppTheme.primary,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// ─── SHIMMER LOADING CARD FOR SKELETONS ──────────────────────
class ShimmerLoadingCard extends StatefulWidget {
  const ShimmerLoadingCard({super.key});

  @override
  State<ShimmerLoadingCard> createState() => _ShimmerLoadingCardState();
}

class _ShimmerLoadingCardState extends State<ShimmerLoadingCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 1500),
    vsync: this,
  )..repeat();

  late final Animation<double> _slideAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppTheme.cardShadow,
          ),
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.border.withValues(alpha: 0.3),
                  AppTheme.border.withValues(alpha: 0.8),
                  AppTheme.border.withValues(alpha: 0.3),
                ],
                stops: [
                  _slideAnimation.value - 0.3,
                  _slideAnimation.value,
                  _slideAnimation.value + 0.3,
                ],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcIn,
            child: Row(
              children: [
                CircleAvatar(radius: 24, backgroundColor: Theme.of(context).cardColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 14, width: 140, color: Theme.of(context).cardColor),
                      const SizedBox(height: 6),
                      Container(height: 10, width: 80, color: Theme.of(context).cardColor),
                      const SizedBox(height: 6),
                      Container(height: 10, width: 110, color: Theme.of(context).cardColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
