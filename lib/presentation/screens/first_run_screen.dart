import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';

/// First-run onboarding: collects due date or LMP, persists locally, shows
/// the medical disclaimer.  No network calls; no accounts.
class FirstRunScreen extends StatefulWidget {
  const FirstRunScreen({super.key, required this.state});

  final AppState state;

  @override
  State<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends State<FirstRunScreen> {
  /// Whether the user is entering a due date (true) or LMP (false).
  bool _useDueDate = true;

  DateTime? _pickedDate;
  bool _saving = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = _useDueDate
        ? now.subtract(const Duration(days: 7))
        : now.subtract(const Duration(days: 294)); // ~42 wks back
    final lastDate = _useDueDate
        ? now.add(const Duration(days: 294)) // up to 42 wks ahead
        : now;

    final picked = await showDatePicker(
      context: context,
      initialDate:
          _pickedDate ??
          (_useDueDate
              ? now.add(const Duration(days: 140))
              : now.subtract(const Duration(days: 140))),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: _useDueDate
          ? 'Pick your due date'
          : 'Pick your last period start',
    );
    if (picked != null) {
      setState(() => _pickedDate = picked);
    }
  }

  Future<void> _confirm() async {
    if (_pickedDate == null || _saving) return;
    setState(() => _saving = true);

    final dueDate = _useDueDate
        ? _pickedDate!
        : _pickedDate!.add(const Duration(days: AppConstants.fullTermDays));

    await widget.state.saveDueDate(dueDate);
    // AppState.isFirstRun will now be false → parent rebuilds to main shell.
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.skyBottom,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.skyTop, palette.skyBottom],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Moon / logo mark
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.moon,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Hello, Little Bumpy.',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: palette.moonlight,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tell me when to expect you.',
                      style: TextStyle(
                        fontSize: 15,
                        color: palette.moonlightSoft,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // Input mode toggle
                    Container(
                      decoration: BoxDecoration(
                        color: palette.paperRaised.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: palette.moonlight.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          _modeTab(
                            'Due Date',
                            selected: _useDueDate,
                            onTap: () {
                              setState(() {
                                _useDueDate = true;
                                _pickedDate = null;
                              });
                            },
                            palette: palette,
                          ),
                          _modeTab(
                            'Last Period',
                            selected: !_useDueDate,
                            onTap: () {
                              setState(() {
                                _useDueDate = false;
                                _pickedDate = null;
                              });
                            },
                            palette: palette,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Date picker trigger
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: palette.paper,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              offset: const Offset(0, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: palette.accent,
                              size: 20,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              _pickedDate == null
                                  ? 'Tap to pick a date'
                                  : _formatDate(_pickedDate!),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: _pickedDate == null
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: _pickedDate == null
                                    ? palette.inkSoft
                                    : palette.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Confirm button
                    ElevatedButton(
                      onPressed: _pickedDate != null && !_saving
                          ? _confirm
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: palette.accentText,
                        disabledBackgroundColor: palette.accent.withValues(
                          alpha: 0.35,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Let's go",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 32),

                    // Medical disclaimer
                    Text(
                      AppConstants.disclaimer,
                      style: TextStyle(
                        fontSize: 11,
                        color: palette.moonlightSoft.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeTab(
    String label, {
    required bool selected,
    required VoidCallback onTap,
    required AppPalette palette,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? palette.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: selected ? palette.accentText : palette.moonlightSoft,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      '',
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
    return '${months[d.month]} ${d.day}, ${d.year}';
  }
}
