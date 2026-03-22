import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'deadline_provider.dart';
import 'app_colors.dart';

class DeadlineList extends StatefulWidget {
  const DeadlineList({super.key});

  @override
  State<DeadlineList> createState() => _DeadlineListState();
}

class _DeadlineListState extends State<DeadlineList> {
  String? _deleteConfirm;

  void _handleStatusChange(
    BuildContext context,
    String id,
    String currentStatus,
  ) {
    final newStatus = currentStatus == 'pending' ? 'completed' : 'pending';
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
    final sorted = [...provider.deadlines]
      ..sort((a, b) {
        if (a.status != b.status) return a.status == 'pending' ? -1 : 1;
        return DateTime.parse(a.date).compareTo(DateTime.parse(b.date));
      });

    if (sorted.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('📭', style: TextStyle(fontSize: 48)),
              SizedBox(height: 16),
              Text(
                'No deadlines yet',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Add one to get started!',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final deadline = sorted[index];
        final deadlineDate = DateTime.parse(deadline.date);
        final today = DateTime.now();
        final todayNorm = DateTime(today.year, today.month, today.day);
        final deadlineNorm = DateTime(
          deadlineDate.year,
          deadlineDate.month,
          deadlineDate.day,
        );

        final isOverdue =
            deadlineNorm.isBefore(todayNorm) && deadline.status == 'pending';
        final isToday = deadlineNorm == todayNorm;
        final daysDiff = deadlineNorm.difference(todayNorm).inDays;
        final isSoon =
            !isToday &&
            !isOverdue &&
            daysDiff <= 3 &&
            deadline.status == 'pending';
        final isCompleted = deadline.status == 'completed';

        // Card colors
        Color cardBg, borderColor;
        if (isCompleted) {
          cardBg = AppColors.muted.withOpacity(0.5);
          borderColor = AppColors.muted;
        } else if (isOverdue) {
          cardBg = AppColors.overdueLight;
          borderColor = AppColors.overdueBorder;
        } else if (isToday) {
          cardBg = AppColors.todayLight;
          borderColor = AppColors.todayBorder;
        } else if (isSoon) {
          cardBg = AppColors.upcomingLight;
          borderColor = AppColors.upcomingBorder;
        } else {
          cardBg = AppColors.white;
          borderColor = AppColors.secondary.withOpacity(0.2);
        }

        // Format date
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        final dateLabel =
            '📅 ${weekdays[deadlineDate.weekday - 1]}, ${months[deadlineDate.month - 1]} ${deadlineDate.day}, ${deadlineDate.year}';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              // Left: Title + Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deadline.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? AppColors.mutedForeground
                            : AppColors.primary,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 13,
                          ),
                        ),
                        if (isOverdue) ...[
                          const SizedBox(width: 8),
                          const Text(
                            'OVERDUE',
                            style: TextStyle(
                              color: AppColors.overdue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          const Text(
                            'TODAY',
                            style: TextStyle(
                              color: AppColors.today,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        if (isSoon) ...[
                          const SizedBox(width: 8),
                          const Text(
                            'SOON',
                            style: TextStyle(
                              color: AppColors.upcoming,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Right: Action Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Status toggle button
                  _OutlineButton(
                    label: isCompleted ? 'Mark Pending' : 'Mark Done',
                    onPressed: () => _handleStatusChange(
                      context,
                      deadline.id,
                      deadline.status,
                    ),
                    filled: !isCompleted,
                    fillColor: AppColors.secondary,
                    textColor: isCompleted
                        ? AppColors.secondary
                        : AppColors.white,
                    borderColor: AppColors.secondary,
                  ),
                  const SizedBox(height: 6),

                  // Delete / Confirm
                  if (_deleteConfirm == deadline.id) ...[
                    Row(
                      children: [
                        _OutlineButton(
                          label: 'Confirm',
                          onPressed: () => _handleDelete(context, deadline.id),
                          filled: true,
                          fillColor: AppColors.overdue,
                          textColor: AppColors.white,
                          borderColor: AppColors.overdue,
                        ),
                        const SizedBox(width: 6),
                        _OutlineButton(
                          label: 'Cancel',
                          onPressed: () =>
                              setState(() => _deleteConfirm = null),
                          filled: false,
                          textColor: AppColors.primary,
                          borderColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ] else
                    _OutlineButton(
                      label: 'Delete',
                      onPressed: () =>
                          setState(() => _deleteConfirm = deadline.id),
                      filled: false,
                      textColor: AppColors.overdue,
                      borderColor: AppColors.overdueBorder,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final Color? fillColor;
  final Color textColor;
  final Color borderColor;

  const _OutlineButton({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? fillColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
