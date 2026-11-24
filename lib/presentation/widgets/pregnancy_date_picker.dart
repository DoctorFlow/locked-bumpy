import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_text.dart';
import 'pause_button.dart';

/// Shown under the picker's buttons when OK is pressed with no day chosen.
const String pickADayFirst = 'Pick a day first';

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
  // A first choice opens on this month with no day chosen, so OK cannot save
  // a week the parent never picked. Until a day is tapped OK is dimmed, and
  // pressing it keeps the picker open with "Pick a day first" under the
  // buttons, so a tired parent is never sent back with nothing said.
  // A saved date opens selected; older saves may fall outside the interval
  // offered for a new choice.
  final candidate = selected;
  final initial = candidate == null
      ? null
      : candidate.isBefore(first)
      ? first
      : candidate.isAfter(last)
      ? last
      : candidate;
  final guard = _OkGuard();
  // The same root navigator and themes as `showDialog`.
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = _GuardedDialogRoute<DateTime>(
    context: context,
    guard: guard,
    barrierColor: DialogTheme.of(context).barrierColor ?? Colors.black54,
    themes: InheritedTheme.capture(from: context, to: navigator.context),
    builder: (dialog) {
      final size = MediaQuery.sizeOf(dialog);
      final short = size.width > size.height && size.height < 480;
      final calendar = _GuardedCalendar(
        guard: guard,
        dialog: DatePickerDialog(
          currentDate: today,
          initialDate: initial,
          firstDate: first,
          lastDate: last,
          helpText: useDueDate
              ? 'Pick your due date'
              : 'Pick your last period start',
          insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
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
  return navigator.push(route);
}

/// Shared between the route and the calendar: whether OK may close it.
class _OkGuard {
  /// Set by the calendar: true when OK was the control just used and no day
  /// is chosen.
  bool Function()? emptyOk;

  /// Tells the calendar to show [pickADayFirst].
  VoidCallback? onRefused;
}

/// A dialog route that stays open when OK is pressed with no day chosen.
/// Cancel, the barrier, Escape and Pause still close it.
class _GuardedDialogRoute<T> extends DialogRoute<T> {
  _GuardedDialogRoute({
    required super.context,
    required super.builder,
    required this.guard,
    super.barrierColor,
    super.themes,
  });

  final _OkGuard guard;

  @override
  bool didPop(T? result) {
    if (result == null && (guard.emptyOk?.call() ?? false)) {
      guard.onRefused?.call();
      return false;
    }
    return super.didPop(result);
  }
}

/// Wraps the stock [DatePickerDialog]: dims its OK while no day is chosen
/// and knows whether OK (by touch or by keyboard) was the control used.
class _GuardedCalendar extends StatefulWidget {
  const _GuardedCalendar({required this.guard, required this.dialog});

  final _OkGuard guard;
  final DatePickerDialog dialog;

  @override
  State<_GuardedCalendar> createState() => _GuardedCalendarState();
}

class _GuardedCalendarState extends State<_GuardedCalendar> {
  bool _chosen = false;
  bool _refused = false;
  Offset? _lastDown;
  LogicalKeyboardKey? _lastKey;

  static final _activateKeys = {
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.gameButtonA,
  };

  @override
  void initState() {
    super.initState();
    _chosen = widget.dialog.initialDate != null;
    widget.guard
      ..emptyOk = _emptyOk
      ..onRefused = _showRefused;
    HardwareKeyboard.instance.addHandler(_onKey);
    _watchFrames();
  }

  /// A day can be chosen by touch, keyboard or a screen reader's tap (which
  /// sends no pointer events), so the choice is read again after every frame
  /// while the picker is open. A post-frame callback never asks for a frame
  /// itself, so an idle picker costs nothing.
  void _watchFrames() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncChosen();
      _watchFrames();
    });
  }

  void _syncChosen() {
    final chosen = _dayChosen();
    if (chosen != _chosen) {
      setState(() {
        _chosen = chosen;
        if (chosen) _refused = false;
      });
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    widget.guard
      ..emptyOk = null
      ..onRefused = null;
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      _lastKey = event.logicalKey;
      _lastDown = null;
      _recheckAfterFrame();
    }
    return false;
  }

  void _recheckAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncChosen();
    });
  }

  /// The stock dialog hands its selection to its calendar as `initialDate`
  /// on every rebuild. In typing mode its own form check keeps OK honest.
  bool _dayChosen() {
    var chosen = false;
    var calendarShown = false;
    void visit(Element e) {
      final w = e.widget;
      if (w is CalendarDatePicker) {
        calendarShown = true;
        chosen = w.initialDate != null;
        return;
      }
      e.visitChildElements(visit);
    }

    (context as Element).visitChildElements(visit);
    return chosen || !calendarShown;
  }

  /// The OK button of the stock dialog, found by its label.
  Element? _okButton() {
    final ok = MaterialLocalizations.of(context).okButtonLabel;
    Element? found;
    void visit(Element e) {
      if (found != null) return;
      final w = e.widget;
      if (w is TextButton && w.child is Text && (w.child! as Text).data == ok) {
        found = e;
        return;
      }
      e.visitChildElements(visit);
    }

    (context as Element).visitChildElements(visit);
    return found;
  }

  bool _emptyOk() {
    if (!mounted || _dayChosen()) return false;
    final ok = _okButton();
    if (ok == null) return false;
    final box = ok.renderObject;
    if (box is! RenderBox || !box.hasSize) return false;
    final down = _lastDown;
    if (down != null) {
      final rect = box.localToGlobal(Offset.zero) & box.size;
      return rect.contains(down);
    }
    // By keyboard: OK has the focus and the last key pressed activates it.
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null || !_activateKeys.contains(_lastKey)) return false;
    if (identical(focused, ok)) return true;
    var inside = false;
    focused.visitAncestorElements((a) {
      if (identical(a, ok)) inside = true;
      return !inside;
    });
    return inside;
  }

  void _showRefused() {
    if (mounted) setState(() => _refused = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // While no day is chosen OK rests on raised paper, still readable: a
    // button waiting for a day, not a dead link.
    final dimmedOk = TextButton.styleFrom(
      backgroundColor: scheme.surfaceContainerHighest,
      foregroundColor: scheme.onSurface.withValues(alpha: 0.6),
      minimumSize: const Size(96, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: AppText.button,
    );
    // Once a day is chosen OK is the main action. The app theme says how;
    // under any other theme it is still a filled button. Both states share
    // one text style so the change between them can animate.
    final chosenOk =
        theme.datePickerTheme.confirmButtonStyle ??
        TextButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(96, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: AppText.button,
        );
    final picker = Theme(
      data: theme.copyWith(
        datePickerTheme: theme.datePickerTheme.copyWith(
          confirmButtonStyle: _chosen ? chosenOk : dimmedOk,
        ),
      ),
      child: Listener(
        onPointerDown: (e) {
          _lastDown = e.position;
          _lastKey = null;
        },
        onPointerUp: (_) => _recheckAfterFrame(),
        child: widget.dialog,
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: picker),
        if (_refused && !_chosen)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Material(
                key: const ValueKey('picker-pick-a-day'),
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    pickADayFirst,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
