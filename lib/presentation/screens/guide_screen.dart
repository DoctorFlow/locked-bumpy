import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../content/content_loader.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/paper.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/guide.dart';
import '../../domain/models/need.dart';
import '../../domain/models/urgent_signs.dart';
import '../widgets/bumpy_avatar.dart';
import '../widgets/draft_tag.dart';
import '../widgets/visit_topics.dart';
import 'guides_screen.dart' show CostumeTag;
import 'urgent_screen.dart';

/// One need's guide as a full page: five numbered paper cards, then sources
/// and the "Last checked" date as quiet text on the page. It sits on the
/// app's route stack, so Pause and Erase (which rebuild the whole app) close
/// it at once.
class GuideScreen extends StatelessWidget {
  const GuideScreen({
    super.key,
    required this.state,
    required this.need,
    required this.guide,
    this.urgent,
    this.urgentFromBundle = false,
  });

  final AppState state;
  final MaternalNeed need;

  /// Null when the gate hides this need's guide.
  final Guide? guide;

  /// The shared urgent list for card 5. Null when the gate hides it: card 5
  /// then shows [UrgentSigns.fallback].
  final UrgentSigns? urgent;

  /// True: ignore [urgent] and use the bundled list ([open] sets this).
  final bool urgentFromBundle;

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
        builder: (_) => GuideScreen(
          state: state,
          need: need,
          guide: guides[need],
          urgentFromBundle: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final copy = guide;
    return PageOnTable(
      title: '${need.label} guide',
      builder: (context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: copy == null
              ? _notReady(context, palette)
              : _cards(copy, palette),
        ),
      ),
    );
  }

  /// Bumpy in this need's costume, in both looks: Bumpy's line is about the
  /// costume, and in the Everyday look Bumpy simply wears it by day.
  Widget _bumpy(AppPalette palette) => Center(
    child: BumpyAvatar(
      need: need,
      palette: palette.copyWith(isHalloween: true) as AppPalette,
      happy: false,
      skinTone: state.skinTone,
    ),
  );

  List<Widget> _notReady(BuildContext context, AppPalette palette) => [
    GuideCard(
      palette: palette,
      marker: null,
      title: need.label,
      costume: need.costume,
      isDraft: false,
      children: [
        _bumpy(palette),
        const SizedBox(height: AppSpace.s),
        Text(
          'This guide is still being checked. You can still add '
          '${need.label} to your visit list.',
          style: _body(palette),
        ),
        const SizedBox(height: AppSpace.l),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            onPressed: () => VisitTopics.edit(context, state, include: need),
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
        ),
      ],
    ),
  ];

  List<Widget> _cards(Guide g, AppPalette palette) {
    const gap = SizedBox(height: AppSpace.l);
    final draft = g.isDraft;
    return [
      // 1. The point
      GuideCard(
        key: const ValueKey('guide-card-point'),
        palette: palette,
        marker: '1',
        title: need.label,
        costume: need.costume,
        isDraft: draft,
        children: [
          _bumpy(palette),
          const SizedBox(height: AppSpace.m),
          Semantics(
            label: 'Bumpy says: ${g.costumeLine}',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bumpy says',
                  style: AppText.label.copyWith(color: palette.inkSoft),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  g.costumeLine,
                  style: AppText.bumpyStory.copyWith(color: palette.ink),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.l),
            child: Divider(height: 1, thickness: 1, color: palette.rule),
          ),
          Text(
            g.point,
            style: AppText.bodyStrong.copyWith(
              color: palette.ink,
              height: 24 / 16,
            ),
          ),
        ],
      ),
      gap,
      // 2. Good to know, and Try this
      GuideCard(
        key: const ValueKey('guide-card-facts'),
        palette: palette,
        marker: '2',
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
                    style: AppText.small.copyWith(color: palette.inkSoft),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.s),
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
      GuideCard(
        key: const ValueKey('guide-card-hard'),
        palette: palette,
        marker: '3',
        title: 'If it is hard',
        isDraft: draft,
        children: [Text(g.ifHard, style: _body(palette))],
      ),
      gap,
      // 4. Ask your doctor or midwife
      GuideCard(
        key: const ValueKey('guide-card-ask'),
        palette: palette,
        marker: '4',
        title: 'Ask your doctor or midwife',
        isDraft: draft,
        children: [
          for (final (i, question) in g.questions.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpace.m),
            _QuestionRow(
              key: ValueKey('guide-question-$i'),
              state: state,
              need: need,
              question: question,
              palette: palette,
            ),
          ],
        ],
      ),
      gap,
      // 5. When to call: never collapsed, never in Bumpy's voice.
      GuideCard(
        key: const ValueKey('guide-card-call'),
        palette: palette,
        marker: '5',
        title: 'When to call',
        icon: Icons.call_outlined,
        // The urgent block inside already carries the 2 px ink edge; a
        // second one round the card read as a box in a box.
        serious: false,
        isDraft: draft,
        children: [
          // This need's own signs, then the shared urgent list in full (or
          // the fixed fallback when it is hidden), then the closing.
          if (g.callToday.isNotEmpty) ...[
            Text(g.callToday, style: _body(palette)),
            const SizedBox(height: AppSpace.l),
          ],
          withUrgentSigns(
            fromBundle: urgentFromBundle,
            given: urgent,
            builder: (list) =>
                UrgentSignsBlock(urgent: list, palette: palette, compact: true),
          ),
          const SizedBox(height: AppSpace.l),
          Text(g.closing, style: _body(palette)),
        ],
      ),
      const SizedBox(height: AppSpace.xl),
      SourcesNote(
        palette: palette,
        sources: [for (final s in g.sources) '${s.org}: ${s.title}'],
        lastChecked: g.lastChecked,
        isDraft: draft,
      ),
      const SizedBox(height: AppSpace.xl),
      Text(
        AppConstants.disclaimer,
        textAlign: TextAlign.center,
        style: AppText.small.copyWith(color: palette.moonlightSoft),
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
    AppText.body.copyWith(color: palette.ink);

/// A page pushed over the app: the table gradient, a top bar whose title may
/// take two lines at large text, and a centred reading column (560 at most).
class PageOnTable extends StatelessWidget {
  const PageOnTable({super.key, required this.title, required this.builder});
  final String title;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final large = MediaQuery.textScalerOf(context).scale(18) > 27;
    return Scaffold(
      backgroundColor: palette.skyBottom,
      appBar: AppBar(
        backgroundColor: palette.skyTop,
        foregroundColor: palette.moonlight,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: large ? 96 : 56,
        titleSpacing: 0,
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.heading.copyWith(color: palette.moonlight),
        ),
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
              final side = math.max(AppSpace.page, (bounds.maxWidth - 560) / 2);
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  side,
                  AppSpace.l,
                  side,
                  AppSpace.xxl,
                ),
                children: [builder(context)],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Sources and the "Last checked" date: quiet text on the page, not a card.
class SourcesNote extends StatelessWidget {
  const SourcesNote({
    super.key,
    required this.palette,
    required this.sources,
    required this.lastChecked,
    this.isDraft = false,
  });
  final AppPalette palette;
  final List<String> sources;
  final String lastChecked;
  final bool isDraft;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Sources',
            style: AppText.label.copyWith(color: palette.moonlightSoft),
          ),
        ),
        const SizedBox(height: AppSpace.s),
        for (final source in sources)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.xs),
            child: Text(
              source,
              style: AppText.small.copyWith(color: palette.moonlightSoft),
            ),
          ),
        const SizedBox(height: AppSpace.s),
        Text(
          'Last checked ${GuideScreen.readableDate(lastChecked)}',
          style: AppText.body.copyWith(color: palette.moonlightSoft),
        ),
        if (isDraft) ...[
          const SizedBox(height: AppSpace.s),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: DraftTag(palette: palette),
          ),
        ],
      ],
    ),
  );
}

/// One card of the guide page: a small numbered paper marker, a heading and
/// a Draft tag in a review build. [serious] gives the card a 2 px ink edge
/// (card 5): calm, never an alarm colour.
class GuideCard extends StatelessWidget {
  const GuideCard({
    super.key,
    required this.palette,
    required this.marker,
    required this.title,
    required this.isDraft,
    required this.children,
    this.costume,
    this.icon,
    this.serious = false,
  });

  final AppPalette palette;

  /// "1" to "5"; null for a page with a single card.
  final String? marker;
  final String title;
  final String? costume;
  final IconData? icon;
  final bool isDraft;
  final bool serious;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final card = PaperCard(
      padding: const EdgeInsets.all(AppSpace.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (marker != null) ...[
                _Marker(marker!, palette: palette),
                const SizedBox(width: AppSpace.m),
              ],
              Expanded(
                child: Wrap(
                  spacing: AppSpace.s,
                  runSpacing: AppSpace.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (icon != null)
                      ExcludeSemantics(
                        child: Icon(icon, color: palette.ink, size: 24),
                      ),
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: AppText.heading.copyWith(color: palette.ink),
                      ),
                    ),
                    if (costume != null)
                      CostumeTag(costume: costume!, palette: palette),
                    if (isDraft) DraftTag(palette: palette),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.l),
          ...children,
        ],
      ),
    );
    if (!serious) return card;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: AppRadii.card,
        border: Border.all(color: palette.ink, width: 2),
      ),
      child: card,
    );
  }
}

/// The card's number on a small accent tag (the accent also marks the week
/// number): the order of the page at a glance. Not spoken.
class _Marker extends StatelessWidget {
  const _Marker(this.text, {required this.palette});
  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.accent,
          borderRadius: AppRadii.tag,
          boxShadow: [
            BoxShadow(color: palette.accentDeep, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s,
            vertical: AppSpace.xs + 2,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppText.label.copyWith(color: palette.accentText),
          ),
        ),
      ),
    ),
  );
}

class _SubHeading extends StatelessWidget {
  const _SubHeading(this.text, {required this.palette});
  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.s),
    child: Semantics(
      header: true,
      child: Text(text, style: AppText.bodyStrong.copyWith(color: palette.ink)),
    ),
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.palette, required this.child});
  final AppPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.m),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              top: AppSpace.s + 1,
              end: AppSpace.m,
            ),
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

/// One guide question on its own raised piece: the question in the parent's
/// voice, then one clear control that becomes "On your visit list".
class _QuestionRow extends StatefulWidget {
  const _QuestionRow({
    super.key,
    required this.state,
    required this.need,
    required this.question,
    required this.palette,
  });

  final AppState state;
  final MaternalNeed need;
  final String question;
  final AppPalette palette;

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
    return PaperCard(
      raised: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.m,
        AppSpace.m,
        AppSpace.m,
        AppSpace.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    top: 2,
                    end: AppSpace.s,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: palette.inkSoft,
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.question,
                  style: AppText.bodyStrong.copyWith(
                    color: palette.ink,
                    height: 24 / 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s),
          if (saved)
            Wrap(
              spacing: AppSpace.s,
              runSpacing: AppSpace.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Semantics(
                  liveRegion: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: palette.accent, size: 24),
                      const SizedBox(width: AppSpace.s),
                      Flexible(
                        child: Text(
                          'On your visit list',
                          style: AppText.bodyStrong.copyWith(
                            color: palette.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _change(add: false),
                  child: Text(
                    'Remove',
                    semanticsLabel:
                        'Remove from visit list: ${widget.question}',
                  ),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.xs),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _change(add: true),
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: Text(
                    'Add to visit list',
                    semanticsLabel: 'Add to visit list: ${widget.question}',
                  ),
                ),
              ),
            ),
          if (_failed)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpace.xs,
                  bottom: AppSpace.xs,
                ),
                child: Text(
                  'That did not save. Please try again.',
                  style: AppText.body.copyWith(color: palette.inkSoft),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
