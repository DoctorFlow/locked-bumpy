import 'package:flutter/material.dart';
import 'pause_button.dart';

import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/need.dart';
import '../../domain/models/visit_question.dart';
import '../screens/visit_screen.dart';

/// A parent's private agenda. Selecting a topic never records a care action.
class VisitTopics extends StatelessWidget {
  const VisitTopics({super.key, required this.state});
  final AppState state;

  /// Opens the visit list editor: every question in words, a field for
  /// another one, and the topics.
  static Future<void> edit(
    BuildContext context,
    AppState state, {
    MaternalNeed? include,
  }) {
    final palette = AppPalette.of(context);
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 440),
      backgroundColor: palette.paper,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (sheet) => _VisitEditor(state: state, include: include),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final topics = state.visitTopics;
    final questions = state.visitQuestions;
    final empty = topics.isEmpty && questions.isEmpty;
    return Material(
      color: palette.paperRaised,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                'For my next visit',
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (empty)
              Text(
                'Keep a list of questions and topics for your doctor or midwife.',
                style: TextStyle(color: palette.inkSoft),
              ),
            for (final question in questions)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  question.text,
                  style: TextStyle(color: palette.ink),
                ),
              ),
            for (final need in MaternalNeed.values.where(topics.contains))
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  children: [
                    Image.asset(
                      need.iconPath,
                      width: 22,
                      height: 22,
                      excludeFromSemantics: true,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        need.label,
                        style: TextStyle(color: palette.ink),
                      ),
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onFocusChange: (focused) {
                if (!focused ||
                    FocusManager.instance.highlightMode !=
                        FocusHighlightMode.traditional) {
                  return;
                }
                final target = FocusManager.instance.primaryFocus?.context;
                if (target == null) return;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (target.mounted &&
                      FocusManager.instance.primaryFocus?.context == target) {
                    Scrollable.ensureVisible(target, alignment: .5);
                  }
                });
              },
              style: TextButton.styleFrom(foregroundColor: palette.ink),
              onPressed: () => edit(context, state),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(
                questions.isNotEmpty
                    ? 'Open my visit list'
                    : topics.isEmpty
                    ? 'Choose topics'
                    : 'Edit visit list',
              ),
            ),
            if (!empty)
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: palette.ink),
                onPressed: () => VisitScreen.open(context, state),
                icon: const Icon(Icons.fullscreen, size: 18),
                label: const Text('Show at my visit'),
              ),
          ],
        ),
      ),
    );
  }
}

class _VisitEditor extends StatefulWidget {
  const _VisitEditor({required this.state, this.include});

  final AppState state;
  final MaternalNeed? include;

  @override
  State<_VisitEditor> createState() => _VisitEditorState();
}

class _VisitEditorState extends State<_VisitEditor> {
  late final Set<MaternalNeed> _selected = {
    ...widget.state.visitTopics,
    ?widget.include,
  };
  final _field = TextEditingController();
  bool _saving = false;
  bool _saveFailed = false;

  /// A calm line about the last add or remove, read out by screen readers.
  String? _note;

  AppState get _state => widget.state;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  /// Adds the typed words. Returns false only when the save did not land;
  /// the words then stay in the field so nothing typed is lost.
  Future<bool> _addTyped() async {
    final text = _field.text.trim();
    if (text.isEmpty) return true;
    if (_state.hasVisitQuestion(text)) {
      _field.clear();
      setState(() => _note = 'That question is already on your list.');
      return true;
    }
    var ok = false;
    try {
      ok = await _state.addVisitQuestion(text);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return ok;
    setState(() {
      if (ok) {
        _field.clear();
        _note = null;
      } else {
        _note =
            'This question couldn’t be saved on this device. '
            'It’s still in the box, so you can try again.';
      }
    });
    return ok;
  }

  Future<void> _add() async {
    if (_saving || _field.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await _addTyped();
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _remove(VisitQuestion question) async {
    if (_saving) return;
    setState(() => _saving = true);
    var ok = false;
    try {
      ok = await _state.removeVisitQuestion(question.text);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _note = ok
          ? null
          : 'This question couldn’t be removed on this device. '
                'You can try again.';
    });
  }

  Future<void> _save() async {
    if (_saving || _state.isPaused || _state.isFirstRun) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    if (!await _addTyped()) {
      if (mounted) setState(() => _saving = false);
      return;
    }
    try {
      await _state.saveVisitTopics(_selected);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveFailed = true;
        });
      }
      return;
    }
    if (mounted && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final questions = _state.visitQuestions;
    // The title, Pause and close stay in view while the list scrolls.
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 6, 0),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'For my next visit',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: palette.ink,
                      ),
                    ),
                  ),
                ),
                PauseButton(onPressed: _state.pause, color: palette.ink),
                IconButton(
                  tooltip: 'Close visit list',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: palette.ink),
                ),
              ],
            ),
          ),
          Flexible(child: _scrollingBody(palette, questions)),
        ],
      ),
    );
  }

  Widget _scrollingBody(AppPalette palette, List<VisitQuestion> questions) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        18,
        0,
        18,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What would you like to ask your doctor or midwife?',
            style: TextStyle(color: palette.inkSoft),
          ),
          const SizedBox(height: 8),
          for (final question in questions)
            Padding(
              key: ValueKey('visit-question-${question.text}'),
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question.text,
                      style: TextStyle(fontSize: 16, color: palette.ink),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove this question',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: _saving ? null : () => _remove(question),
                    icon: Icon(Icons.remove_circle_outline, color: palette.ink),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          TextFormField(
            key: const ValueKey('visit-question-field'),
            controller: _field,
            enabled: !_saving,
            minLines: 1,
            maxLines: 3,
            enableSuggestions: false,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: questions.isEmpty
                  ? 'My question, in my own words'
                  : 'Another question, in my own words',
              border: const OutlineInputBorder(),
            ),
            onFieldSubmitted: (_) => _add(),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: palette.ink,
                minimumSize: const Size(48, 48),
              ),
              onPressed: _saving ? null : _add,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add question'),
            ),
          ),
          if (_note != null)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_note!, style: TextStyle(color: palette.ink)),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'Topics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: palette.ink,
            ),
          ),
          for (final need in MaternalNeed.values)
            CheckboxListTile(
              key: ValueKey('visit-topic-${need.name}'),
              contentPadding: EdgeInsets.zero,
              secondary: Image.asset(
                need.iconPath,
                width: 34,
                height: 34,
                excludeFromSemantics: true,
              ),
              activeColor: palette.accent,
              checkColor: palette.accentText,
              title: Text(need.label, style: TextStyle(color: palette.ink)),
              value: _selected.contains(need),
              onChanged: _saving
                  ? null
                  : (value) => setState(() {
                      if (value == true) {
                        _selected.add(need);
                      } else {
                        _selected.remove(need);
                      }
                    }),
            ),
          const SizedBox(height: 10),
          if (_saveFailed)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Your visit list couldn’t be saved on this device.',
                  style: TextStyle(color: palette.ink),
                ),
              ),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: palette.ink,
              foregroundColor: palette.paper,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _saving ? null : _save,
            child: Text(
              _saving
                  ? 'Saving…'
                  : _saveFailed
                  ? 'Retry save'
                  : 'Save visit list',
            ),
          ),
        ],
      ),
    );
  }
}
