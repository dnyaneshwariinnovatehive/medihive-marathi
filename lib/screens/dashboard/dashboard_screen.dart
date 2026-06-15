import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../models/patient.dart';
import '../../widgets/section_card.dart';

import 'package:flutter/rendering.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;
  
  late AnimationController _headerAnim;
  late AnimationController _statsAnim;
  late AnimationController _chartAnim;
  late AnimationController _listAnim;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.position.userScrollDirection == ScrollDirection.forward ||
          _scrollController.position.pixels < 50;
      if (show != _showFab) {
        setState(() => _showFab = show);
      }
    });

    _headerAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600)
    )..forward();

    _statsAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700)
    );

    _chartAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800)
    );

    _listAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600)
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _statsAnim.forward();
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _chartAnim.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _listAnim.forward();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerAnim.dispose();
    _statsAnim.dispose();
    _chartAnim.dispose();
    _listAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final settings = context.watch<SettingsProvider>();
    final notifications = context.watch<NotificationProvider>();
    final appointments = context.watch<AppointmentProvider>();

    // Dynamic greeting based on time of day
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    // Dynamic date formatting
    final now = DateTime.now();
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final formattedDate = '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';

    // Calculate upcoming follow-ups from calendar appointments
    final upcomingFollowUps = appointments.upcomingFollowUps.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dashboard.setFollowUpsDue(upcomingFollowUps);
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: AnimatedSlide(
        offset: _showFab ? Offset.zero : const Offset(0, 2.5),
        duration: const Duration(milliseconds: 300),
        curve: _showFab ? Curves.easeOutCubic : Curves.easeInCubic,
        child: AnimatedOpacity(
          opacity: _showFab ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF1A506C),
            onPressed: () => context.push('/app/opd/new'),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF1A506C),
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        displacement: 60,
        onRefresh: () async {
          await dashboard.loadDashboardData();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ═══════════════════════════════════════════════════
          // PREMIUM CLINICAL GRADIENT HEADER (200px)
          // ═══════════════════════════════════════════════════
          SliverAppBar(
            expandedHeight: 275,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primary,
            automaticallyImplyLeading: false,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: FadeTransition(
                opacity: _headerAnim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.15),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _headerAnim,
                    curve: Curves.easeOutCubic,
                  )),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 12),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                if (settings.doctorProfileImage.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: CircleAvatar(
                                      radius: 24,
                                      backgroundImage: MemoryImage(base64Decode(settings.doctorProfileImage)),
                                    ),
                                  ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$greeting, 👋',
                                      style: AppTheme.caption.copyWith(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      settings.doctorName,
                                      style: AppTheme.heading.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formattedDate,
                                      style: AppTheme.caption.copyWith(
                                        color: Colors.white.withValues(alpha: 0.65),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => context.push('/app/settings/notifications'),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                                  if (notifications.unreadCount > 0)
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.danger,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${notifications.unreadCount}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 2x2 Grid of stat cards inside header
                        Row(
                          children: [
                            Expanded(child: _headerStatCard('Today\'s OPD', dashboard.todaysOpd.toString(), Icons.medical_services_outlined)),
                            const SizedBox(width: 8),
                            Expanded(child: _headerStatCard('Today\'s Revenue', dashboard.todaysRevenue, Icons.currency_rupee)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(child: _headerStatCard('Overview', dashboard.totalVisits.toString(), Icons.people_outline)),
                            const SizedBox(width: 8),
                            Expanded(child: _headerStatCard('Follow-ups Due', dashboard.followUpsDue.toString(), Icons.calendar_today_outlined)),
                          ],
                        ),
                      ],
                    ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════
          // BODY SECTIONS (Scrollable)
          // ═══════════════════════════════════════════════════
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => context.go('/app/opd/new'),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.primary, AppTheme.primaryLight],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'New OPD',
                                    style: AppTheme.label.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => context.go('/app/chatbot'),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 52,
                            width: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.border),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: const Center(
                              child: Icon(Icons.chat_bubble_outline, color: AppTheme.primary, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // STAT CARDS ROW (3 cards in a Row — Total Visits, Follow-ups, Revenue)
                    Row(
                      children: [
                        Expanded(
                          child: _buildPremiumStatCard(
                            icon: Icons.people_outline,
                            value: dashboard.totalVisits.toString(),
                            label: 'Total Visits',
                            index: 0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPremiumStatCard(
                            icon: Icons.repeat,
                            value: dashboard.newPatients.toString(), // or followUps count
                            label: 'New Patients',
                            index: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPremiumStatCard(
                            icon: Icons.currency_rupee,
                            value: dashboard.todaysRevenue.replaceAll('₹', '').replaceAll(',', ''),
                            label: 'Today Revenue',
                            index: 2,
                            isRevenue: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // CLINIC OVERVIEW SECTION
                    _buildClinicOverview(context, dashboard),
                    const SizedBox(height: 24),

                    // REVENUE SPLIT
                    _buildRevenueSplit(dashboard),
                    const SizedBox(height: 24),

                    // TODAY'S COLLECTION
                    _buildTodaysCollection(dashboard),
                    const SizedBox(height: 24),

                    // RECENT PATIENTS
                    _buildRecentPatients(context, dashboard.recentPatients),
                    const SizedBox(height: 24),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Premium stat card generator with stagger animation and number counter
  Widget _buildPremiumStatCard({
    required IconData icon,
    required String value,
    required String label,
    required int index,
    bool isRevenue = false,
  }) {
    final double targetValue = double.tryParse(value) ?? 0.0;

    return AnimatedBuilder(
      animation: _statsAnim,
      builder: (context, child) {
        final delay = index * 0.2;
        final progress = ((_statsAnim.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final curve = Curves.easeOutCubic.transform(progress);
        return Opacity(
          opacity: curve,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - curve)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: targetValue),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, val, _) {
                final displayValue = isRevenue
                    ? '₹${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'
                    : val.toInt().toString();
                return Text(
                  displayValue,
                  style: AppTheme.display.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTheme.caption.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Clinic Overview Line Chart with Curved lines and grid
  Widget _buildClinicOverview(BuildContext context, DashboardProvider dashboard) {
    double maxCount = dashboard.opdTrendData
        .map((e) => e.count.toDouble())
        .fold(0.0, (max, count) => count > max ? count : max);

    double calculatedMaxY = maxCount > 0 ? (maxCount * 1.15).ceilToDouble() : 5.0;
    if (calculatedMaxY < 5) calculatedMaxY = 5;

    double yInterval = (calculatedMaxY / 4).ceilToDouble();
    if (yInterval < 1) yInterval = 1;
    calculatedMaxY = yInterval * 4;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Clinic Overview',
                style: AppTheme.subHeading.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              // Segmented control style — 3 small pill buttons
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: ['7 Days', '30 Days', '6 Months'].map((range) {
                    final isActive = dashboard.selectedRange == range;
                    return GestureDetector(
                      onTap: () => dashboard.setSelectedRange(range),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          range,
                          style: AppTheme.caption.copyWith(
                            color: isActive ? Colors.white : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 3-column stats
          Row(
            children: [
              _overviewStat(dashboard.totalVisits.toString(), 'Total Visits'),
              Container(width: 1, height: 32, color: AppTheme.border),
              _overviewStat(dashboard.newPatients.toString(), 'New Patients'),
              Container(width: 1, height: 32, color: AppTheme.border),
              _overviewStat(
                dashboard.followUpRate,
                'Follow-up Rate',
                valueColor: AppTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Line Chart
          SizedBox(
            height: 180,
            child: AnimatedBuilder(
              animation: _chartAnim,
              builder: (context, child) {
                return ClipRect(
                  clipper: _ChartClipper(
                    Curves.easeOutCubic.transform(_chartAnim.value)
                  ),
                  child: child,
                );
              },
              child: LineChart(
                LineChartData(
                  lineTouchData: const LineTouchData(enabled: true),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.divider,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            value.toInt().toString(),
                            style: AppTheme.caption.copyWith(
                              fontSize: 10,
                              color: AppTheme.textHint,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < dashboard.opdTrendData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                dashboard.opdTrendData[index].day,
                                style: AppTheme.caption.copyWith(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dashboard.opdTrendData
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
                          .toList(),
                      isCurved: true,
                      color: AppTheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 3,
                          color: AppTheme.primary,
                          strokeWidth: 0,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withValues(alpha: 0.15),
                            AppTheme.primary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: calculatedMaxY,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewStat(String value, String label, {Color? valueColor}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.heading.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // Revenue split card
  Widget _buildRevenueSplit(DashboardProvider dashboard) {
    const colors = [AppTheme.primary, AppTheme.success];
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue Split',
                style: AppTheme.subHeading.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: ['Weekly', 'Monthly', 'Yearly'].map((period) {
                    final isActive = dashboard.revenuePeriod == period;
                    return GestureDetector(
                      onTap: () => dashboard.setRevenuePeriod(period),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          period,
                          style: AppTheme.caption.copyWith(
                            color: isActive ? Colors.white : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 28,
                    sections: dashboard.revenueSplit.asMap().entries.map((e) {
                      return PieChartSectionData(
                        value: e.value.value,
                        color: colors[e.key % colors.length],
                        radius: 18,
                        showTitle: false,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    ...dashboard.revenueSplit.asMap().entries.map((e) {
                      final val = e.value.value;
                      final formatted = val >= 100000
                          ? '₹${(val / 100000).toStringAsFixed(1)}L'
                          : val >= 1000
                              ? '₹${(val / 1000).toStringAsFixed(1)}K'
                              : '₹${val.toInt()}';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: colors[e.key % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(e.value.name,
                                    style: AppTheme.caption.copyWith(color: AppTheme.textSecondary)),
                              ],
                            ),
                            Text(formatted,
                                style: AppTheme.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary)),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: AppTheme.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary)),
                        Text(dashboard.formattedRevenuePeriodTotal,
                            style: AppTheme.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Today's Collection
  Widget _buildTodaysCollection(DashboardProvider dashboard) {
    final totalCollection = dashboard.todaysCollection.fold<int>(0, (sum, item) => sum + item.amount);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Collection",
                style: AppTheme.subHeading.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '₹$totalCollection',
                style: AppTheme.subHeading.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (dashboard.todaysCollection.isEmpty)
            _buildEmptyState('No collections yet today', Icons.receipt_long_outlined),
          if (dashboard.todaysCollection.isNotEmpty)
            ...dashboard.todaysCollection.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTheme.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.mode,
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${item.amount}',
                    style: AppTheme.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Recent Patients list with dividers
  Widget _buildRecentPatients(BuildContext context, List<Patient> recentPatientsList) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent OPD Activity',
                style: AppTheme.subHeading.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/app/patients'),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 14, color: AppTheme.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentPatientsList.isEmpty)
            _buildEmptyState('No recent patients found', Icons.people_outline),
          if (recentPatientsList.isNotEmpty)
            ...recentPatientsList.asMap().entries.map((entry) {
            final index = entry.key;
            final patient = entry.value;
            final isLast = index == recentPatientsList.length - 1;

            final delay = (index * 0.1).clamp(0.0, 0.5);

            return AnimatedBuilder(
              animation: _listAnim,
              builder: (context, child) {
                final progress = ((_listAnim.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
                final curve = Curves.easeOutCubic.transform(progress);
                return Opacity(
                  opacity: curve,
                  child: SlideTransition(
                    position: AlwaysStoppedAnimation(Offset(0, 0.25 * (1 - curve))),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/app/patients/${patient.id}'),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                            child: Text(
                              patient.initial,
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient.name,
                                  style: AppTheme.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ID: ${patient.id} • Age ${patient.age}',
                                  style: AppTheme.caption.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(patient.gender).withValues(alpha: 0.1), // gender was hacked to store status
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  patient.gender.toUpperCase(),
                                  style: AppTheme.caption.copyWith(
                                    color: _getStatusColor(patient.gender),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Time: ${patient.lastVisit}',
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast) const Divider(height: 1, thickness: 0.8),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _headerStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 12),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: AppTheme.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTheme.heading.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  // Generic empty state for lists
  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppTheme.primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTheme.body.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
}

class _ChartClipper extends CustomClipper<Rect> {
  final double progress;
  _ChartClipper(this.progress);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * progress, size.height);
  }

  @override
  bool shouldReclip(_ChartClipper old) => old.progress != progress;
}
