import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DeadlineStatus { pending, near, completed, missed }

class Deadline {
  String id;
  String title;
  DateTime dateTime;
  DeadlineStatus status;

  Deadline({
    required this.id,
    required this.title,
    required this.dateTime,
    this.status = DeadlineStatus.pending,
  });

  // Convert Deadline to Map for SharedPreferences
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'dateTime': dateTime.toIso8601String(),
        'status': status.index,
      };

  // Convert Map back to Deadline
  factory Deadline.fromMap(Map<String, dynamic> map) => Deadline(
        id: map['id'],
        title: map['title'],
        dateTime: DateTime.parse(map['dateTime']),
        status: DeadlineStatus.values[map['status']],
      );
}

class DeadlineTrackerPage extends StatefulWidget {
  const DeadlineTrackerPage({super.key});

  @override
  State<DeadlineTrackerPage> createState() => _DeadlineTrackerPageState();
}

class _DeadlineTrackerPageState extends State<DeadlineTrackerPage> {
  DateTime currentMonth = DateTime.now();
  DateTime? selectedDate;

  final List<Deadline> deadlines = [];
  final TextEditingController titleController = TextEditingController();
  TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    loadCurrentMonth().then((_) => loadDeadlines());
  }

  // ---------------- SharedPreferences ----------------
  Future<void> saveDeadlines() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = deadlines.map((d) => jsonEncode(d.toMap())).toList();
    await prefs.setStringList('deadlines', encoded);
  }

  Future<void> loadDeadlines() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('deadlines') ?? [];
    setState(() {
      deadlines.clear();
      for (var d in stored) {
        deadlines.add(Deadline.fromMap(jsonDecode(d)));
      }
    });
  }

  Future<void> saveCurrentMonth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentMonth', currentMonth.toIso8601String());
  }

  Future<void> loadCurrentMonth() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('currentMonth');
    if (stored != null) {
      setState(() {
        currentMonth = DateTime.parse(stored);
      });
    }
  }

  // ---------------- Helpers ----------------
  int daysInMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0).day;

  int firstWeekday(DateTime date) => DateTime(date.year, date.month, 1).weekday % 7;

  List<Deadline> deadlinesForDate(DateTime date) {
    return deadlines
        .where((d) =>
            d.dateTime.year == date.year &&
            d.dateTime.month == date.month &&
            d.dateTime.day == date.day)
        .toList();
  }

  void updateDeadlineStatuses() {
    final now = DateTime.now();

    for (final d in deadlines) {
      if (d.status == DeadlineStatus.completed) continue;

      if (now.isAfter(d.dateTime)) {
        d.status = DeadlineStatus.missed;
      } else if (d.dateTime.difference(now).inMinutes <= 10) {
        d.status = DeadlineStatus.near;
      } else {
        d.status = DeadlineStatus.pending;
      }
    }
  }

  // ---------------- Add / Edit ----------------
  void addOrEditDeadline({Deadline? editing}) {
    titleController.text = editing?.title ?? '';
    selectedTime = editing != null
        ? TimeOfDay.fromDateTime(editing.dateTime)
        : const TimeOfDay(hour: 9, minute: 0);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(editing == null ? "Add Deadline" : "Edit Deadline"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: Text("Time: ${selectedTime.format(context)}"),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isEmpty ||
                      selectedDate == null) return;

                  final dateTime = DateTime(
                    selectedDate!.year,
                    selectedDate!.month,
                    selectedDate!.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  if (dateTime.isBefore(DateTime.now())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text("❌ Cannot add deadline for past time"),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    if (editing == null) {
                      deadlines.add(Deadline(
                          id: DateTime.now().toString(),
                          title: titleController.text,
                          dateTime: dateTime));
                    } else {
                      editing.title = titleController.text;
                      editing.dateTime = dateTime;
                    }
                  });

                  saveDeadlines();
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------- Month Navigation ----------------
  void changeMonth(int offset) {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + offset);
      selectedDate = null;
    });
    saveCurrentMonth();
  }

  @override
  Widget build(BuildContext context) {
    updateDeadlineStatuses();

    final days = daysInMonth(currentMonth);
    final start = firstWeekday(currentMonth);

    // Only show deadlines of current month in sidebar
    final monthDeadlines = deadlines
        .where((d) =>
            d.dateTime.year == currentMonth.year &&
            d.dateTime.month == currentMonth.month)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Deadline Tracker"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            selectedDate == null ? null : () => addOrEditDeadline(),
        child: const Icon(Icons.add),
      ),
      body: Row(
        children: [
          // -------- Calendar --------
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Month navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => changeMonth(-1),
                    ),
                    Text(
                      "${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () => changeMonth(1),
                    ),
                  ],
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: days + start,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemBuilder: (_, index) {
                      if (index < start) return const SizedBox();

                      final day = index - start + 1;
                      final date =
                          DateTime(currentMonth.year, currentMonth.month, day);

                      final hasDeadlines = deadlinesForDate(date).isNotEmpty;

                      final selected = selectedDate != null &&
                          date.year == selectedDate!.year &&
                          date.month == selectedDate!.month &&
                          date.day == selectedDate!.day;

                      return GestureDetector(
                        onTap: () {
                          if (date.isBefore(DateTime.now()
                              .subtract(const Duration(days: 1)))) return;

                          setState(() => selectedDate = date);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.teal
                                : hasDeadlines
                                    ? Colors.orange.shade100
                                    : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              "$day",
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // -------- Sidebar --------
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: monthDeadlines.map((d) {
                Color color;
                String label;

                switch (d.status) {
                  case DeadlineStatus.near:
                    color = Colors.orange;
                    label = "⏰ Near Deadline";
                    break;
                  case DeadlineStatus.missed:
                    color = Colors.red;
                    label = "❌ Missed";
                    break;
                  case DeadlineStatus.completed:
                    color = Colors.green;
                    label = "✅ Completed";
                    break;
                  default:
                    color = Colors.teal;
                    label = "Pending";
                }

                return Card(
                  child: ListTile(
                    leading: Icon(Icons.flag, color: color),
                    title: Text(d.title),
                    subtitle: Text(label),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // EDIT
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: d.status == DeadlineStatus.missed
                              ? null
                              : () => addOrEditDeadline(editing: d),
                        ),
                        // COMPLETE
                        IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: d.status == DeadlineStatus.missed
                              ? null
                              : () {
                                  setState(() =>
                                      d.status = DeadlineStatus.completed);
                                  saveDeadlines();
                                },
                        ),
                        // DELETE
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Delete Deadline?"),
                                content: const Text(
                                    "Are you sure you want to delete this deadline?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    child: const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        deadlines.remove(d);
                                      });
                                      saveDeadlines();
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Delete"),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
