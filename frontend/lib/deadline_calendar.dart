import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'deadline_provider.dart';
import 'app_colors.dart';

class DeadlineCalendar extends StatefulWidget {
  const DeadlineCalendar({super.key});

  @override
  State<DeadlineCalendar> createState() => _DeadlineCalendarState();
}

class _DeadlineCalendarState extends State<DeadlineCalendar> {
  DateTime _currentDate = DateTime.now();
  String? _selectedDate;
  String? _deleteConfirm;

  String _toDateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Color _getDeadlineColor(Deadline deadline) {
    if (deadline.status == 'completed') return AppColors.completed;
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final deadlineDate = DateTime.parse(deadline.date);
    final deadlineNorm = DateTime(
      deadlineDate.year,
      deadlineDate.month,
      deadlineDate.day,
    );
    if (deadlineNorm.isBefore(todayNorm)) return AppColors.overdue;
    if (deadlineNorm == todayNorm) return AppColors.today;
    return AppColors.upcoming;
  }

  void _handleStatusChange(BuildContext context, String id, String status) {
    final newStatus = status == 'pending' ? 'completed' : 'pending';
    context.read<DeadlineProvider>().updateDeadlineStatus(id, newStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text(
          newStatus == 'completed' ? 'Completed! ✓' : 'Marked as Pending',
          style: const TextStyle(color: AppColors.white),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleDelete(BuildContext context, String id) {
    context.read<DeadlineProvider>().deleteDeadline(id);
    setState(() => _deleteConfirm = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.overdue,
        content: const Text(
          'Deleted ✓',
          style: TextStyle(color: AppColors.white),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeadlineProvider>();
    final deadlines = provider.deadlines;

    final year = _currentDate.year;
    final month = _currentDate.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstDay = DateTime(year, month, 1).weekday % 7; // 0=Sun

    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final monthName = '${months[month - 1]} $year';

    final today = DateTime.now();
    final todayStr = _toDateStr(today);

    final selectedDateStr = _selectedDate ?? _toDateStr(_currentDate);
    final selectedDeadlines = deadlines
        .where((d) => d.date == selectedDateStr)
        .toList();

    // Format selected date label
    String selectedLabel = 'Select a Date';
    if (_selectedDate != null) {
      final d = DateTime.parse(_selectedDate!);
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final mons = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      selectedLabel =
          '${weekdays[d.weekday - 1]}, ${mons[d.month - 1]} ${d.day}';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        final calendarWidget = Container(
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
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month nav
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    monthName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    children: [
                      _NavButton(
                        label: '← Prev',
                        onPressed: () => setState(() {
                          _currentDate = DateTime(year, month - 1);
                          _selectedDate = null;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _NavButton(
                        label: 'Next →',
                        onPressed: () => setState(() {
                          _currentDate = DateTime(year, month + 1);
                          _selectedDate = null;
                        }),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Weekday headers
              Row(
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),

              // Days grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.1,
                ),
                itemCount: firstDay + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < firstDay) return const SizedBox();
                  final day = index - firstDay + 1;
                  final date = DateTime(year, month, day);
                  final dateStr = _toDateStr(date);
                  final dayDeadlines = deadlines
                      .where((d) => d.date == dateStr)
                      .toList();
                  final isSelected = _selectedDate == dateStr;
                  final isToday = dateStr == todayStr;

                  Color bgColor;
                  Color borderColor;
                  Color textColor;
                  if (isSelected) {
                    bgColor = AppColors.primary;
                    borderColor = AppColors.primary;
                    textColor = AppColors.white;
                  } else if (isToday) {
                    bgColor = AppColors.todayLight;
                    borderColor = AppColors.todayBorder;
                    textColor = AppColors.primary;
                  } else {
                    bgColor = AppColors.white;
                    borderColor = AppColors.secondary.withOpacity(0.2);
                    textColor = AppColors.foreground;
                  }

                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedDate = isSelected ? null : dateStr;
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          if (dayDeadlines.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ...dayDeadlines
                                    .take(3)
                                    .map(
                                      (d) => Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getDeadlineColor(d),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                if (dayDeadlines.length > 3)
                                  Text(
                                    '+${dayDeadlines.length - 3}',
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Legend
              const SizedBox(height: 16),
              const Divider(color: Color(0x33379392)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: const [
                  _LegendItem(color: AppColors.today, label: 'Today'),
                  _LegendItem(color: AppColors.upcoming, label: 'Upcoming'),
                  _LegendItem(color: AppColors.overdue, label: 'Overdue'),
                  _LegendItem(color: AppColors.completed, label: 'Completed'),
                ],
              ),
            ],
          ),
        );

        // Sidebar
        final sidebarWidget = Container(
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
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              if (selectedDeadlines.isEmpty)
                const Text(
                  'No deadlines on this date',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 14,
                  ),
                )
              else
                ...selectedDeadlines.map(
                  (deadline) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.muted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deadline.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: deadline.status == 'completed'
                                ? AppColors.mutedForeground
                                : AppColors.primary,
                            decoration: deadline.status == 'completed'
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${deadline.status}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _SidebarButton(
                                label: deadline.status == 'completed'
                                    ? 'Undo'
                                    : 'Done',
                                onPressed: () => _handleStatusChange(
                                  context,
                                  deadline.id,
                                  deadline.status,
                                ),
                                filled: false,
                                textColor: AppColors.secondary,
                                borderColor: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (_deleteConfirm == deadline.id)
                              Expanded(
                                child: _SidebarButton(
                                  label: 'Sure?',
                                  onPressed: () =>
                                      _handleDelete(context, deadline.id),
                                  filled: true,
                                  fillColor: const Color(0xFFDC2626),
                                  textColor: AppColors.white,
                                  borderColor: const Color(0xFFDC2626),
                                ),
                              )
                            else
                              Expanded(
                                child: _SidebarButton(
                                  label: 'Delete',
                                  onPressed: () => setState(
                                    () => _deleteConfirm = deadline.id,
                                  ),
                                  filled: false,
                                  textColor: AppColors.overdue,
                                  borderColor: AppColors.overdueBorder,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: calendarWidget),
              const SizedBox(width: 20),
              Expanded(flex: 1, child: sidebarWidget),
            ],
          );
        } else {
          return Column(
            children: [
              calendarWidget,
              const SizedBox(height: 20),
              sidebarWidget,
            ],
          );
        }
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _NavButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _SidebarButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final Color? fillColor;
  final Color textColor;
  final Color borderColor;

  const _SidebarButton({
    required this.label,
    required this.onPressed,
    required this.filled,
    this.fillColor,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: filled ? fillColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
