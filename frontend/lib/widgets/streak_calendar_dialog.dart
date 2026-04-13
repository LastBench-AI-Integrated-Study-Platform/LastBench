import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StreakCalendarDialog extends StatefulWidget {
  final List<String> studyDates;
  final int currentStreak;

  const StreakCalendarDialog({
    super.key,
    required this.studyDates,
    required this.currentStreak,
  });

  @override
  State<StreakCalendarDialog> createState() => _StreakCalendarDialogState();
}

class _StreakCalendarDialogState extends State<StreakCalendarDialog> {
  late DateTime _focusedMonth;
  final Color navy = const Color(0xFF033F63);
  final Color teal = const Color(0xFF379392);

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  bool _isDateSelected(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return widget.studyDates.contains(dateStr);
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstDayWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    // Offset for GridView (if 1st is Wednesday (3), we skip Mon/Tue)
    // Adjusting to 0-index where 0 = Monday
    final offset = firstDayWeekday - 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Material( // Added Material wrapper for safety
        color: Colors.white,
        child: Container(
          width: 340, // Fixed width for dialog consistency
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevMonth),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy').format(_focusedMonth),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navy),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
                ],
              ),
              const SizedBox(height: 10),

              // Weekday labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .map((d) => SizedBox(
                        width: 40,
                        child: Text(d, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                      ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 10),

              // Calendar Grid
              Container(
                constraints: const BoxConstraints(maxHeight: 280), // Use constraints instead of fixed height
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: 42,
                  itemBuilder: (context, index) {
                    final dayNumber = index - offset + 1;
                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const SizedBox.shrink();
                    }

                    final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
                    final isLogged = _isDateSelected(date);
                    final isToday = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now());

                    return Container(
                      decoration: BoxDecoration(
                        color: isLogged ? teal : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: isToday ? Border.all(color: navy, width: 2) : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        dayNumber.toString(),
                        style: TextStyle(
                          color: isLogged ? Colors.white : Colors.black87,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(height: 1),
              ),

              // Footer info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn("Streak", "${widget.currentStreak} Days"),
                  _buildStatColumn("Total Logs", "${widget.studyDates.length}"),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: teal)),
      ],
    );
  }
}
