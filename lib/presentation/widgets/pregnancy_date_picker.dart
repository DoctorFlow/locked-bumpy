import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/paper.dart';
import 'pause_button.dart';

/// Line height of a day number: tight, so a row stays short.
const double _dayLineHeight = 1.25;

/// Shown under the picker's buttons when OK is pressed with no day chosen.
const String pickADayFirst = 'Pick a day first';

/// Shown in the picker's header until a day is chosen.
const String noDayChosenYet = 'No day chosen yet';

const List<String> _monthNames = [
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

/// The date step's date style: "15 March 2027", or "15 March" with
/// [withYear] false.
String dayMonthYear(DateTime d, {bool withYear = true}) {
  final dayMonth = '${d.day} ${_monthNames[d.month - 1]}';
  return withYear ? '$dayMonth ${d.year}' : dayMonth;
}

/// The month the picker shows first.
///
/// Not this month: a due date is months away. With no day chosen the picker
/// opens on the month a parent 13 weeks along would be due in (today plus
/// 27 weeks), or for a last period the month 13 weeks back. From there a
/// parent anywhere from week 5 to week 21 is at most two month taps from
/// their month on any day of the year (most days week 4 and 22 too), and
/// the month list reaches any other month in two taps. A chosen day opens
/// on its own month. The result is always a month inside [first] to [last].
DateTime pickerOpeningMonth({
  required DateTime today,
  required bool useDueDate,
  required DateTime first,
  required DateTime last,
  DateTime? selected,
}) {
  final anchor =
      selected ??
      DateTime(
        today.year,
        today.month,
        today.day + (useDueDate ? 7 * 27 : -7 * 13),
      );
  var month = DateTime(anchor.year, anchor.month);
  final firstMonth = DateTime(first.year, first.month);
  final lastMonth = DateTime(last.year, last.month);
  if (month.isBefore(firstMonth)) month = firstMonth;
  if (month.isAfter(lastMonth)) month = lastMonth;
  return month;
}

Future<DateTime?> pickPregnancyDate(
  BuildContext context, {
  required DateTime today,
  required bool useDueDate,
  required VoidCallback onPause,
  DateTime? selected,
}) {
  DateTime offset(int days) =>
      DateTime(today.year, today.month, today.day + days);
  final first = offset(useDueDate ? -7 : -294);
  final last = offset(useDueDate ? 294 : 0);
  // A first choice opens with no day chosen, so OK cannot save a week the
  // parent never picked. Until a day is tapped OK rests on raised paper, and
  // pressing it (by touch, keyboard or a screen reader) keeps the picker
  // open with "Pick a day first" under the buttons.
  // A saved date opens selected; older saves may fall outside the interval
  // offered for a new choice.
  final candidate = selected == null ? null : DateUtils.dateOnly(selected);
  final initial = candidate == null
      ? null
      : candidate.isBefore(first)
      ? first
      : candidate.isAfter(last)
      ? last
      : candidate;
  return showDialog<DateTime>(
    context: context,
    useRootNavigator: true,
    builder: (dialog) {
      final size = MediaQuery.sizeOf(dialog);
      final short = size.width > size.height && size.height < 480;
      final calendar = PregnancyCalendarDialog(
        today: DateUtils.dateOnly(today),
        first: first,
        last: last,
        initial: initial,
        openingMonth: pickerOpeningMonth(
          today: today,
          useDueDate: useDueDate,
          first: first,
          last: last,
          selected: initial,
        ),
        helpText: useDueDate
            ? 'Pick your due date'
            : 'Pick your last period start',
      );
      // Inset like the dialog itself (8 px), so the circle is never cut by
      // the screen edge.
      final pause = Padding(
        key: const ValueKey('picker-pause'),
        padding: short
            ? const EdgeInsets.only(top: 8, right: 8)
            : const EdgeInsets.only(right: 8, bottom: 8),
        child: Material(
          color: Theme.of(dialog).colorScheme.surface,
          shape: const CircleBorder(),
          child: PauseButton(
            onPressed: onPause,
            color: Theme.of(dialog).colorScheme.onSurface,
          ),
        ),
      );
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: short ? 640 : 420),
          child: short
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(child: calendar),
                    pause,
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(alignment: Alignment.centerRight, child: pause),
                    Flexible(child: calendar),
                  ],
                ),
        ),
      );
    },
  );
}

/// The app's own calendar for a due date or a last period: one month of
/// days, Previous and Next month, and a month list that reaches any month
/// in two taps. OK is a real button, so a screen reader's tap, a keyboard
/// and a finger all reach the same check.
class PregnancyCalendarDialog extends StatefulWidget {
  const PregnancyCalendarDialog({
    super.key,
    required this.today,
    required this.first,
    required this.last,
    required this.openingMonth,
    required this.helpText,
    this.initial,
  });

  final DateTime today;
  final DateTime first;
  final DateTime last;
  final DateTime openingMonth;
  final String helpText;
  final DateTime? initial;

  @override
  State<PregnancyCalendarDialog> createState() =>
      _PregnancyCalendarDialogState();
}

class _PregnancyCalendarDialogState extends State<PregnancyCalendarDialog> {
  late DateTime _month = DateTime(
    widget.openingMonth.year,
    widget.openingMonth.month,
  );
  late DateTime? _chosen = widget.initial;
  bool _monthList = false;
  bool _refused = false;

  DateTime get _firstMonth => DateTime(widget.first.year, widget.first.month);
  DateTime get _lastMonth => DateTime(widget.last.year, widget.last.month);
  bool get _hasPrevious => _month.isAfter(_firstMonth);
  bool get _hasNext => _month.isBefore(_lastMonth);

  void _step(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  void _choose(DateTime day) => setState(() {
    _chosen = day;
    _refused = false;
  });

  void _ok() {
    final chosen = _chosen;
    if (chosen == null) {
      setState(() => _refused = true);
      return;
    }
    Navigator.pop(context, chosen);
  }

  bool _selectable(DateTime day) =>
      !day.isBefore(widget.first) && !day.isAfter(widget.last);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final loc = MaterialLocalizations.of(context);
    final chosen = _chosen;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Everything above the buttons scrolls as one, so a short window
          // or large text never squeezes it; OK and Cancel stay in reach.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header: what is being picked, and the day picked so far.
                  Container(
                    color: palette.paperRaised,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.l,
                      AppSpace.m,
                      AppSpace.l,
                      AppSpace.m,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            widget.helpText,
                            style: AppText.heading.copyWith(color: palette.ink),
                          ),
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            chosen == null
                                ? noDayChosenYet
                                : dayMonthYear(chosen),
                            key: const ValueKey('picker-chosen'),
                            style: AppText.body.copyWith(
                              color: palette.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _MonthBar(
                    label: loc.formatMonthYear(_month),
                    listOpen: _monthList,
                    palette: palette,
                    onPrevious: _hasPrevious && !_monthList
                        ? () => _step(-1)
                        : null,
                    onNext: _hasNext && !_monthList ? () => _step(1) : null,
                    onToggleList: () =>
                        setState(() => _monthList = !_monthList),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
                    child: _monthList
                        ? _MonthList(
                            first: _firstMonth,
                            last: _lastMonth,
                            shown: _month,
                            palette: palette,
                            onPick: (m) => setState(() {
                              _month = m;
                              _monthList = false;
                            }),
                          )
                        : _DayGrid(
                            month: _month,
                            today: widget.today,
                            chosen: chosen,
                            selectable: _selectable,
                            palette: palette,
                            onPick: _choose,
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (_refused && chosen == null)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.l,
                  AppSpace.s,
                  AppSpace.l,
                  0,
                ),
                child: Text(
                  pickADayFirst,
                  key: const ValueKey('picker-pick-a-day'),
                  textAlign: TextAlign.center,
                  style: AppText.bodyStrong.copyWith(color: palette.ink),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.s,
              AppSpace.s,
              AppSpace.l,
              AppSpace.m,
            ),
            child: OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: AppSpace.s,
              overflowSpacing: AppSpace.s,
              children: [
                TextButton(
                  key: const ValueKey('picker-cancel'),
                  // Quiet ink, so it never outshines OK.
                  style: TextButton.styleFrom(foregroundColor: palette.ink),
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.cancelButtonLabel),
                ),
                FilledButton(
                  key: const ValueKey('picker-ok'),
                  // Waiting for a day: a resting raised-paper button, still
                  // readable. Once a day is chosen: the accent main button.
                  style: chosen == null
                      ? FilledButton.styleFrom(
                          backgroundColor: palette.paperRaised,
                          foregroundColor: palette.ink.withValues(alpha: 0.6),
                          side: BorderSide(color: palette.outline),
                        )
                      : null,
                  onPressed: _ok,
                  child: Text(loc.okButtonLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Previous month, the month's name (which opens the month list), next month.
class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.label,
    required this.listOpen,
    required this.palette,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleList,
  });

  final String label;
  final bool listOpen;
  final AppPalette palette;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onToggleList;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.xs),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: onPrevious,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: onPrevious == null ? Colors.transparent : palette.ink,
            ),
          ),
          Expanded(
            child: Semantics(
              label: listOpen
                  ? 'Back to the days of $label'
                  : '$label. Choose another month',
              button: true,
              excludeSemantics: true,
              onTap: onToggleList,
              child: FilledButton.tonal(
                key: const ValueKey('picker-month'),
                onPressed: onToggleList,
                style: FilledButton.styleFrom(
                  foregroundColor: palette.ink,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.s,
                    vertical: AppSpace.s,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(label, textAlign: TextAlign.center)),
                    const SizedBox(width: AppSpace.xs),
                    Icon(
                      listOpen
                          ? Icons.arrow_drop_up_rounded
                          : Icons.arrow_drop_down_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: onNext,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: onNext == null ? Colors.transparent : palette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Every month the picker offers, as paper pieces: one tap shows its days.
class _MonthList extends StatelessWidget {
  const _MonthList({
    required this.first,
    required this.last,
    required this.shown,
    required this.palette,
    required this.onPick,
  });

  final DateTime first;
  final DateTime last;
  final DateTime shown;
  final AppPalette palette;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final months = <DateTime>[
      for (var m = first; !m.isAfter(last); m = DateTime(m.year, m.month + 1))
        m,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
      child: Wrap(
        key: const ValueKey('picker-month-list'),
        alignment: WrapAlignment.center,
        spacing: AppSpace.s,
        runSpacing: AppSpace.s,
        children: [
          for (final m in months)
            _MonthPiece(
              month: m,
              label: loc.formatMonthYear(m),
              selected: m == shown,
              palette: palette,
              onTap: () => onPick(m),
            ),
        ],
      ),
    );
  }
}

class _MonthPiece extends StatelessWidget {
  const _MonthPiece({
    required this.month,
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final DateTime month;
  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      child: FilledButton.tonal(
        key: ValueKey('picker-month-${month.year}-${month.month}'),
        onPressed: onTap,
        style: FilledButton.styleFrom(
          minimumSize: const Size(132, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
          foregroundColor: selected ? palette.accentText : palette.ink,
          backgroundColor: selected ? palette.accent : palette.paperRaised,
          side: BorderSide(color: selected ? palette.accent : palette.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 16),
              const SizedBox(width: AppSpace.xs),
            ],
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}

/// One month of days in a 7-column grid, weeks starting on the locale's
/// first day. Days outside the offered range are faint and cannot be chosen.
class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.month,
    required this.today,
    required this.chosen,
    required this.selectable,
    required this.palette,
    required this.onPick,
  });

  final DateTime month;
  final DateTime today;
  final DateTime? chosen;
  final bool Function(DateTime) selectable;
  final AppPalette palette;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final firstDay = loc.firstDayOfWeekIndex; // 0 = Sunday
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final lead = (DateTime(month.year, month.month).weekday % 7 - firstDay) % 7;
    final cells = <DateTime?>[
      for (var i = 0; i < lead; i++) null,
      for (var d = 1; d <= daysInMonth; d++)
        DateTime(month.year, month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    // Large text: each row grows with the day numbers (the dialog scrolls),
    // and a number too wide for its seventh of the width is drawn smaller
    // instead of cut. Nothing is ever clipped.
    final scaler = MediaQuery.textScalerOf(context);
    final cellHeight = math.max(
      AppSpace.target,
      scaler.scale(AppText.body.fontSize!) * _dayLineHeight + 12,
    );
    final weekdayHeight = math.max(
      32.0,
      scaler.scale(AppText.label.fontSize!) * _dayLineHeight + 8,
    );
    return Column(
      key: ValueKey('picker-days-${month.year}-${month.month}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: SizedBox(
                    height: weekdayHeight,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          loc.narrowWeekdays[(firstDay + i) % 7],
                          style: AppText.label.copyWith(
                            color: palette.inkSoft,
                            height: _dayLineHeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (var row = 0; row < cells.length ~/ 7; row++)
          Row(
            children: [
              for (final day in cells.sublist(row * 7, row * 7 + 7))
                Expanded(
                  child: SizedBox(
                    height: cellHeight,
                    child: day == null
                        ? null
                        : _Day(
                            day: day,
                            isToday: DateUtils.isSameDay(day, today),
                            selected: DateUtils.isSameDay(day, chosen),
                            enabled: selectable(day),
                            palette: palette,
                            onPick: onPick,
                          ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.day,
    required this.isToday,
    required this.selected,
    required this.enabled,
    required this.palette,
    required this.onPick,
  });

  final DateTime day;
  final bool isToday;
  final bool selected;
  final bool enabled;
  final AppPalette palette;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    // The words the stock calendar spoke: "15, Monday, March 15, 2027".
    final label =
        '${loc.formatDecimal(day.day)}, ${loc.formatFullDate(day)}'
        '${isToday ? ', ${loc.currentDateLabel}' : ''}';
    final ink = selected
        ? palette.accentText
        : !enabled
        ? palette.inkSoft.withValues(alpha: 0.45)
        : isToday
        ? palette.accent
        : palette.ink;
    void pick() => onPick(day);
    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      selected: selected,
      excludeSemantics: true,
      onTap: enabled ? pick : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
        child: InkWell(
          key: ValueKey('picker-day-${day.year}-${day.month}-${day.day}'),
          onTap: enabled ? pick : null,
          borderRadius: AppRadii.tag,
          child: Ink(
            decoration: BoxDecoration(
              color: selected ? palette.accent : Colors.transparent,
              borderRadius: AppRadii.tag,
              border: isToday && !selected
                  ? Border.all(color: palette.accent, width: 1.5)
                  : null,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${day.day}',
                  key: ValueKey('picker-day-number-${day.day}'),
                  maxLines: 1,
                  softWrap: false,
                  style: (selected ? AppText.bodyStrong : AppText.body)
                      .copyWith(color: ink, height: _dayLineHeight),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
