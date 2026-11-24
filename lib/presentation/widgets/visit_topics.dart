import 'package:flutter/material.dart';
import 'app_nav_bar.dart';
import 'pause_button.dart';

import '../../core/theme/app_text.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/paper.dart';
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
    // The hint under the title: what the list is for, or what the row does.
    final hint = empty
        ? 'Keep a list of questions and topics for your doctor or midwife.'
        : questions.isNotEmpty
        ? 'Open my visit list'
        : 'Edit visit list';
    // The same row as "When to get help right away": one tappable paper row
    // with a leading tile and a chevron. No underlined link.
    final row = Semantics(
      button: true,
      label: 'For my next visit. $hint',
      excludeSemantics: true,
      // The InkWell's own tap is excluded with its text, so the node
      // carries the tap for screen readers and the web.
      onTap: () => edit(context, state),
      child: InkWell(
        key: const ValueKey('visit-topics-row'),
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
        onTap: () => edit(context, state),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              AppSpace.m,
              AppSpace.s,
              AppSpace.m,
            ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.paperRaised,
                    borderRadius: AppRadii.tag,
                    border: Border.all(color: palette.edge),
                  ),
                  child: SizedBox.square(
                    dimension: AppSpace.target,
                    child: Icon(Icons.edit_note, color: palette.ink, size: 28),
                  ),
                ),
                const SizedBox(width: AppSpace.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'For my next visit',
                          style: AppText.bodyStrong.copyWith(
                            color: palette.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        hint,
                        style: AppText.small.copyWith(color: palette.inkSoft),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: palette.ink, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row,
          if (!empty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                0,
                AppSpace.l,
                AppSpace.l,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Divider(height: 1, thickness: 1, color: palette.rule),
                  for (final question in questions)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.s),
                      child: Text(
                        question.text,
                        style: AppText.body.copyWith(color: palette.ink),
                      ),
                    ),
                  for (final need in MaternalNeed.values.where(topics.contains))
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.s),
                      child: Row(
                        children: [
                          Image.asset(
                            need.iconPath,
                            width: 24,
                            height: 24,
                            excludeFromSemantics: true,
                          ),
                          const SizedBox(width: AppSpace.s),
                          Expanded(
                            child: Text(
                              needWord(need),
                              style: AppText.body.copyWith(color: palette.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpace.m),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: OutlinedButton.icon(
                      onPressed: () => VisitScreen.open(context, state),
                      icon: const Icon(Icons.fullscreen),
                      label: const Text('Show at my visit'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// How far above the bottom of the screen the tab bar's top edge sits; 0
/// when there is no tab bar (first run, Paused).
double _tabBarClearance(BuildContext context) {
  final screen = MediaQuery.sizeOf(context).height;
  double found = 0;
  void visit(Element element) {
    if (found > 0) return;
    if (element.widget is AppNavBar) {
      final box = element.renderObject;
      if (box is RenderBox && box.hasSize && box.attached) {
        // Over a page pushed above the shell this only lifts the note a
        // little higher than it needs; it never covers the tabs.
        final top = box.localToGlobal(Offset.zero).dy;
        found = screen - top;
      }
      return;
    }
    element.visitChildren(visit);
  }

  final root = WidgetsBinding.instance.rootElement;
  root?.visitChildren(visit);
  return found.clamp(0, screen / 2);
}

/// Sentence-case need word ("Prenatal vitamin"), as on Today and Guides.
String needWord(MaternalNeed need) =>
    need == MaternalNeed.vitamin ? 'Prenatal vitamin' : need.label;

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
      // Back to where the list was opened from, with a calm word that it
      // landed. A snack bar is a live region, so screen readers say it too.
      // It floats above the tab bar for 2 seconds, so it never covers or
      // takes a tap meant for the tabs.
      final messenger = ScaffoldMessenger.maybeOf(context);
      final clearance = _tabBarClearance(context);
      Navigator.pop(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            key: const ValueKey('visit-saved'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            margin: EdgeInsets.fromLTRB(
              AppSpace.page,
              0,
              AppSpace.page,
              clearance + AppSpace.s,
            ),
            content: const Text('Your visit list is saved.'),
          ),
        );
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
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              AppSpace.s,
              AppSpace.s,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'For my next visit',
                      style: AppText.title.copyWith(color: palette.ink),
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
        AppSpace.l,
        0,
        AppSpace.l,
        AppSpace.l + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What would you like to ask your doctor or midwife?',
            style: AppText.body.copyWith(color: palette.inkSoft),
          ),
          const SizedBox(height: AppSpace.m),
          for (final question in questions)
            Padding(
              key: ValueKey('visit-question-${question.text}'),
              padding: const EdgeInsets.only(bottom: AppSpace.s),
              child: PaperCard(
                raised: true,
                padding: const EdgeInsets.only(left: AppSpace.m),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        question.text,
                        style: AppText.body.copyWith(color: palette.ink),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove from visit list: ${question.text}',
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: _saving ? null : () => _remove(question),
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: palette.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpace.xs),
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
            ),
            onFieldSubmitted: (_) => _add(),
          ),
          const SizedBox(height: AppSpace.s),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _add,
              icon: const Icon(Icons.add),
              label: const Text('Add question'),
            ),
          ),
          const SizedBox(height: AppSpace.s),
          if (_note != null)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s),
                child: Text(
                  _note!,
                  style: AppText.body.copyWith(color: palette.ink),
                ),
              ),
            ),
          const SizedBox(height: AppSpace.m),
          Semantics(
            header: true,
            child: Text(
              'Topics',
              style: AppText.heading.copyWith(color: palette.ink),
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
              title: Text(
                needWord(need),
                style: AppText.body.copyWith(color: palette.ink),
              ),
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
          const SizedBox(height: AppSpace.l),
          if (_saveFailed)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s),
                child: Text(
                  'Your visit list couldn’t be saved on this device.',
                  style: AppText.body.copyWith(color: palette.ink),
                ),
              ),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpace.target),
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
