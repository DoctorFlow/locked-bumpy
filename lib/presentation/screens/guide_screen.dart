import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../content/content_loader.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/guide.dart';
import '../../domain/models/need.dart';
import '../widgets/bumpy_avatar.dart';
import '../widgets/draft_tag.dart';
import '../widgets/visit_topics.dart';

/// One need's guide as a full page: five paper cards, then sources and the
/// "Last checked" date. It sits on the app's route stack, so Pause and Erase
/// (which rebuild the whole app) close it at once.
class GuideScreen extends StatelessWidget {
  const GuideScreen({
    super.key,
    required this.state,
    required this.need,
    required this.guide,
  });

  final AppState state;
  final MaternalNeed need;

  /// Null when the gate hides this need's guide.
  final Guide? guide;

  /// Opens [need]'s guide. The one entry point other screens call.
  static Future<void> open(
    BuildContext context,
    AppState state,
    MaternalNeed need,
  ) async {
    final guides = await ContentLoader.loadGuides();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            GuideScreen(state: state, need: need, guide: guides[need]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final copy = guide;
    return Scaffold(
      backgroundColor: palette.skyBottom,
      appBar: AppBar(
        backgroundColor: palette.skyTop,
        foregroundColor: palette.moonlight,
        surfaceTintColor: Colors.transparent,
        title: Text('${need.label} guide'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.skyTop, palette.skyBottom],
          ),
        ),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, bounds) {
              final side = math.max(16.0, (bounds.maxWidth - 560) / 2);
              return ListenableBuilder(
                listenable: state,
                builder: (context, _) => ListView(
                  padding: EdgeInsets.fromLTRB(side, 16, side, 24),
                  children: copy == null
                      ? _notReady(context, palette)
                      : _cards(copy, palette),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _notReady(BuildContext context, AppPalette palette) => [
    _PaperCard(
      palette: palette,
      title: need.label,
      isDraft: false,
      children: [
        Center(
          child: BumpyAvatar(
            need: need,
            palette: palette,
            happy: false,
            skinTone: state.skinTone,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This guide is still being checked. You can still add '
          '${need.label} to your visit list.',
          style: _body(palette),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => VisitTopics.edit(context, state, include: need),
          style: OutlinedButton.styleFrom(
            foregroundColor: palette.ink,
            minimumSize: const Size.fromHeight(48),
          ),
          icon: Icon(
            state.visitTopics.contains(need)
                ? Icons.bookmark
                : Icons.bookmark_outline,
          ),
          label: Text(
            state.visitTopics.contains(need)
                ? 'On my visit list'
                : 'Add to my visit list',
          ),
        ),
      ],
    ),
  ];

  List<Widget> _cards(Guide g, AppPalette palette) {
    const gap = SizedBox(height: 14);
    final draft = g.isDraft;
    return [
      // 1. The point
      _PaperCard(
        key: const ValueKey('guide-card-point'),
        palette: palette,
        title: need.label,
        subtitle: palette.isHalloween ? need.costume : null,
        isDraft: draft,
        children: [
          Center(
            child: BumpyAvatar(
              need: need,
              palette: palette,
              happy: false,
              skinTone: state.skinTone,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Bumpy says: ${g.costumeLine}',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bumpy says',
                  style: TextStyle(
                    color: palette.inkSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  g.costumeLine,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(g.point, style: _body(palette)),
        ],
      ),
      gap,
      // 2. Good to know, and Try this
      _PaperCard(
        key: const ValueKey('guide-card-facts'),
        palette: palette,
        title: 'Good to know',
        isDraft: draft,
        children: [
          for (final fact in g.facts)
            _Bullet(
              palette: palette,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fact.text, style: _body(palette)),
                  Text(
                    fact.sourceOrg,
                    style: TextStyle(color: palette.inkSoft, fontSize: 14),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          _SubHeading('Try this', palette: palette),
          for (final idea in g.tryThis)
            _Bullet(
              palette: palette,
              child: Text(idea, style: _body(palette)),
            ),
        ],
      ),
      gap,
      // 3. If it is hard
      _PaperCard(
        key: const ValueKey('guide-card-hard'),
        palette: palette,
        title: 'If it is hard',
        isDraft: draft,
        children: [Text(g.ifHard, style: _body(palette))],
      ),
      gap,
      // 4. Ask your doctor or midwife
      _PaperCard(
        key: const ValueKey('guide-card-ask'),
        palette: palette,
        title: 'Ask your doctor or midwife',
        isDraft: draft,
        children: [
          for (final (i, question) in g.questions.indexed)
            _QuestionRow(
              key: ValueKey('guide-question-$i'),
              state: state,
              need: need,
              question: question,
              palette: palette,
              first: i == 0,
            ),
        ],
      ),
      gap,
      // 5. When to call: never collapsed, never in Bumpy's voice.
      _PaperCard(
        key: const ValueKey('guide-card-call'),
        palette: palette,
        title: 'When to call',
        icon: Icons.call_outlined,
        accentEdge: true,
        isDraft: draft,
        children: [
          Text(g.callToday, style: _body(palette)),
          if (g.callNow.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              g.callNow,
              style: _body(palette).copyWith(fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 10),
          Text(g.closing, style: _body(palette)),
        ],
      ),
      const SizedBox(height: 22),
      // Sources and date, on the sky.
      Semantics(
        header: true,
        child: Text(
          'Sources',
          style: TextStyle(
            color: palette.moonlight,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 6),
      for (final source in g.sources)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '${source.org}: ${source.title}',
            style: TextStyle(
              color: palette.moonlightSoft,
              fontSize: 16,
              height: 1.35,
            ),
          ),
        ),
      const SizedBox(height: 6),
      Text(
        'Last checked ${readableDate(g.lastChecked)}',
        style: TextStyle(color: palette.moonlight, fontSize: 16),
      ),
      if (draft) ...[
        const SizedBox(height: 10),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: DraftTag(palette: palette),
        ),
      ],
      const SizedBox(height: 18),
      Text(
        AppConstants.disclaimer,
        textAlign: TextAlign.center,
        style: TextStyle(color: palette.moonlightSoft, fontSize: 14),
      ),
    ];
  }

  /// `2026-11-24` → `24 November 2026`.
  static String readableDate(String iso) {
    const months = [
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
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

TextStyle _body(AppPalette palette) =>
    TextStyle(color: palette.ink, fontSize: 16, height: 1.45);

/// A cut-paper card with a heading, and a Draft tag in a review build.
class _PaperCard extends StatelessWidget {
  const _PaperCard({
    super.key,
    required this.palette,
    required this.title,
    required this.isDraft,
    required this.children,
    this.subtitle,
    this.icon,
    this.accentEdge = false,
  });

  final AppPalette palette;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool isDraft;
  final bool accentEdge;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Material(
      color: palette.paper,
      borderRadius: radius,
      elevation: 1,
      shadowColor: palette.skyBottom,
      clipBehavior: Clip.antiAlias,
      child: Container(
        // A strip of accent paper along the top marks the card to keep.
        decoration: accentEdge
            ? BoxDecoration(
                border: Border(
                  top: BorderSide(color: palette.accent, width: 6),
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (icon != null) Icon(icon, color: palette.accent, size: 22),
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isDraft) DraftTag(palette: palette),
                ],
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: palette.inkSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _SubHeading extends StatelessWidget {
  const _SubHeading(this.text, {required this.palette});
  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: TextStyle(
          color: palette.ink,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.palette, required this.child});
  final AppPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: 8, end: 10),
            child: SizedBox.square(
              dimension: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    ),
  );
}

/// One guide question with its visit-list control.
class _QuestionRow extends StatefulWidget {
  const _QuestionRow({
    super.key,
    required this.state,
    required this.need,
    required this.question,
    required this.palette,
    required this.first,
  });

  final AppState state;
  final MaternalNeed need;
  final String question;
  final AppPalette palette;
  final bool first;

  @override
  State<_QuestionRow> createState() => _QuestionRowState();
}

class _QuestionRowState extends State<_QuestionRow> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _change({required bool add}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    var ok = false;
    try {
      ok = add
          ? await widget.state.addVisitQuestion(
              widget.question,
              need: widget.need,
            )
          : await widget.state.removeVisitQuestion(widget.question);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failed = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final saved = widget.state.hasVisitQuestion(widget.question);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.first)
          Divider(height: 22, color: palette.inkSoft.withValues(alpha: .28)),
        Text(widget.question, style: _body(palette)),
        const SizedBox(height: 6),
        if (saved)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                liveRegion: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: palette.accent, size: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'On your visit list',
                        style: TextStyle(
                          color: palette.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _busy ? null : () => _change(add: false),
                style: TextButton.styleFrom(
                  foregroundColor: palette.inkSoft,
                  minimumSize: const Size(48, 48),
                ),
                child: Text(
                  'Remove',
                  semanticsLabel: 'Remove from visit list: ${widget.question}',
                ),
              ),
            ],
          )
        else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : () => _change(add: true),
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.ink,
                side: BorderSide(color: palette.inkSoft),
                minimumSize: const Size(48, 48),
              ),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: Text(
                'Add to visit list',
                semanticsLabel: 'Add to visit list: ${widget.question}',
              ),
            ),
          ),
        if (_failed)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'That did not save. Please try again.',
                style: TextStyle(color: palette.inkSoft, fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }
}
