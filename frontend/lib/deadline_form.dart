import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'deadline_provider.dart';
import 'app_colors.dart';

class DeadlineForm extends StatefulWidget {
  final VoidCallback? onSuccess;
  const DeadlineForm({super.key, this.onSuccess});

  @override
  State<DeadlineForm> createState() => _DeadlineFormState();
}

class _DeadlineFormState extends State<DeadlineForm> {
  final _titleController = TextEditingController();
  DateTime? _selectedDate;
  String? _titleError;
  String? _dateError;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: DateTime(today.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.white,
            surface: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateError = null;
      });
    }
  }

  void _handleSubmit() {
    setState(() {
      _titleError = null;
      _dateError = null;
    });

    bool hasError = false;
    if (_titleController.text.trim().isEmpty) {
      setState(() => _titleError = 'Title is required');
      hasError = true;
    }
    if (_selectedDate == null) {
      setState(() => _dateError = 'Date is required');
      hasError = true;
    }

    if (hasError) return;

    final dateStr =
        '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

    context.read<DeadlineProvider>().addDeadline(
          _titleController.text.trim(),
          dateStr,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text(
          'Deadline "${_titleController.text.trim()}" added ✓',
          style: const TextStyle(color: AppColors.white),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    _titleController.clear();
    setState(() => _selectedDate = null);
    widget.onSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _selectedDate != null
        ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
        : 'Select a date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Field
        const Text(
          'Deadline Title',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          onChanged: (_) => setState(() => _titleError = null),
          decoration: InputDecoration(
            hintText: 'Enter deadline title',
            hintStyle: const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _titleError != null
                    ? AppColors.overdue
                    : AppColors.secondary.withOpacity(0.3),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color:
                    _titleError != null ? AppColors.overdue : AppColors.secondary,
                width: 2,
              ),
            ),
            errorText: _titleError,
            errorStyle: const TextStyle(color: AppColors.overdue, fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),

        // Date Field
        const Text(
          'Due Date',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _dateError != null
                    ? AppColors.overdue
                    : AppColors.secondary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: AppColors.mutedForeground),
                const SizedBox(width: 8),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: _selectedDate != null
                        ? AppColors.foreground
                        : AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_dateError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              _dateError!,
              style: const TextStyle(color: AppColors.overdue, fontSize: 12),
            ),
          ),
        const SizedBox(height: 20),

        // Submit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text(
              'Add Deadline',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}