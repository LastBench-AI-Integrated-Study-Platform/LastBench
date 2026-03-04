import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'deadline_provider.dart';
import 'deadline_form.dart';
import 'deadline_list.dart';
import 'deadline_calendar.dart';
import 'app_colors.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  bool _showForm = false;
  String _activeTab = 'list';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeadlineProvider>();

    // ── Show spinner while SharedPreferences is loading ───────────────────
    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F9FA),
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        ),
      );
    }

    final deadlines = provider.deadlines;
    final totalCount = deadlines.length;
    final completedCount = deadlines.where((d) => d.status == 'completed').length;
    final pendingCount = deadlines.where((d) => d.status == 'pending').length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x0D033F63),
              Color(0x0D379392),
            ],
          ),
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              color: AppColors.white,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0x1A379392), width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    )
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '📋 Deadline Tracker',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage your deadlines efficiently',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Main Content ─────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stats Cards ─────────────────────────────────────────
                    LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 500;
                      final cards = [
                        _StatCard(
                          label: 'Total Deadlines',
                          value: '$totalCount',
                          valueColor: AppColors.primary,
                        ),
                        _StatCard(
                          label: 'Completed',
                          value: '$completedCount',
                          valueColor: AppColors.secondary,
                        ),
                        _StatCard(
                          label: 'Pending',
                          value: '$pendingCount',
                          valueColor: const Color(0xFFEA580C),
                        ),
                      ];
                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: 16),
                            Expanded(child: cards[1]),
                            const SizedBox(width: 16),
                            Expanded(child: cards[2]),
                          ],
                        );
                      } else {
                        return Column(
                          children: cards
                              .map((c) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: c,
                                  ))
                              .toList(),
                        );
                      }
                    }),

                    const SizedBox(height: 24),

                    // ── Add Button ──────────────────────────────────────────
                    GestureDetector(
                      onTap: () => setState(() => _showForm = !_showForm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Text(
                          _showForm ? 'Cancel' : '+ Add Deadline',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    // ── Form ────────────────────────────────────────────────
                    if (_showForm) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.secondary.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: DeadlineForm(
                          onSuccess: () => setState(() => _showForm = false),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Tabs ────────────────────────────────────────────────
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0x33379392), width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          _TabButton(
                            label: 'List View',
                            isActive: _activeTab == 'list',
                            onTap: () => setState(() => _activeTab = 'list'),
                          ),
                          const SizedBox(width: 4),
                          _TabButton(
                            label: 'Calendar View',
                            isActive: _activeTab == 'calendar',
                            onTap: () =>
                                setState(() => _activeTab = 'calendar'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Content ─────────────────────────────────────────────
                    if (_activeTab == 'list') const DeadlineList(),
                    if (_activeTab == 'calendar') const DeadlineCalendar(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.secondary.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab Button ────────────────────────────────────────────────────────────────
class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isActive ? AppColors.primary : AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}