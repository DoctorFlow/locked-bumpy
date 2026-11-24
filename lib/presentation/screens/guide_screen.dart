import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsService;
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
import '../widgets/need_word.dart';
import '../widgets/visit_topics.dart';
import 'guides_screen.dart' show CostumeTag, VisitListButton;
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
    this.answerFact,
  }) : topic = null;

  /// A topic guide's page: the same cards, with no need and no costume.
  const GuideScreen.topic({
    super.key,
    required this.state,
    required TopicGuideEntry this.topic,
    this.urgent,
    this.urgentFromBundle = false,
  }) : need = null,
       guide = null,
       answerFact = null;

  final AppState state;

  /// Null for a topic guide.
  final MaternalNeed? need;

  /// Set for a topic guide (then [need] and [guide] are null).
  final TopicGuideEntry? topic;

  MaternalNeed get _need => need!;

  /// Null when the gate hides this need's guide.
  final Guide? guide;

  /// The shared urgent list for card 5. Null when the gate hides it: card 5
  /// then shows [UrgentSigns.fallback].
  final UrgentSigns? urgent;

  /// True: ignore [urgent] and use the bundled list ([open] sets this).
  final bool urgentFromBundle;

  /// The id of the fact that answers the question the parent came with (a
  /// chapter's curious question). That fact is scrolled into view, marked
  /// and announced. Null or an unknown id: the guide opens at its top.
  final String? answerFact;

  /// Opens [need]'s guide. The one entry point other screens call. From a
  /// chapter, pass [answerFact]; from the Guides list or Today, leave it out.
  static Future<void> open(
    BuildContext context,
    AppState state,
    MaternalNeed need, {
    String? answerFact,
  }) async {
    final guides = await ContentLoader.loadGuides();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GuideScreen(
          state: state,
          need: need,
          guide: guides[need],
          urgentFromBundle: true,
          answerFact: answerFact,
        ),
      ),
    );
  }

  /// Opens a topic guide's page.
  static Future<void> openTopic(
    BuildContext context,
    AppState state,
    TopicGuideEntry topic,
  ) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          GuideScreen.topic(state: state, topic: topic, urgentFromBundle: true),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final copy = guide;
    final shown = topic;
    return PageOnTable(
      title: shown != null ? shown.title.text : '${needWord(_need)} guide',
      builder: (context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: shown != null
              ? _cards(_GuideBody.ofTopic(shown), palette)
              : copy == null
              ? _notReady(context, palette)
              : _cards(_GuideBody.of(copy), palette),
        ),
      ),
    );
  }

  /// Bumpy in this need's costume, in both looks: Bumpy's line is about the
  /// costume, and in the Everyday look Bumpy simply wears it by day.
  Widget _bumpy(AppPalette palette) => Center(
    child: BumpyAvatar(
      need: _need,
      palette: palette.copyWith(isHalloween: true) as AppPalette,
      happy: false,
      skinTone: state.skinTone,
    ),
  );

  List<Widget> _notReady(BuildContext context, AppPalette palette) => [
    GuideCard(
      palette: palette,
      marker: null,
      title: needWord(_need),
      costume: _need.costume,
      isDraft: false,
      children: [
        _bumpy(palette),
        const SizedBox(height: AppSpace.s),
        Text(
          'This guide is still being checked. You can still add '
          '${_need.label} to your visit list.',
          style: _body(palette),
        ),
        const SizedBox(height: AppSpace.l),
        VisitListButton(
          onPressed: () => VisitTopics.edit(context, state, include: _need),
          saved: state.visitTopics.contains(_need),
          label: state.visitTopics.contains(_need)
              ? 'On my visit list'
              : 'Add to my visit list',
        ),
      ],
    ),
  ];

  List<Widget> _cards(_GuideBody g, AppPalette palette) {
    const gap = SizedBox(height: AppSpace.l);
    final draft = g.isDraft;
    final need = this.need;
    final costumeLine = g.costumeLine;
    return [
      // 1. The point
      GuideCard(
        key: const ValueKey('guide-card-point'),
        palette: palette,
        marker: '1',
        title: g.title ?? needWord(_need),
        costume: need?.costume,
        isDraft: draft,
        children: [
          if (need != null && costumeLine != null) ...[
            _bumpy(palette),
            const SizedBox(height: AppSpace.m),
            Semantics(
              label: 'Bumpy says: $costumeLine',
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
                    costumeLine,
                    style: AppText.bumpyStory.copyWith(color: palette.ink),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.l),
              child: Divider(height: 1, thickness: 1, color: palette.rule),
            ),
          ],
          // The point in a larger reading size, not bold: calm, not shouting.
          Text(
            g.point,
            style: AppText.body.copyWith(
              fontSize: 18,
              height: 28 / 18,
              color: palette.ink,
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
            _markIfAnswer(
              fact,
              palette,
              _Bullet(
                palette: palette,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fact.text, style: _body(palette)),
                    const SizedBox(height: AppSpace.xs),
                    // Every fact shows where it comes from, legibly: `small`
                    // (14 Regular) in inkSoft, the same "Source:" wording as
                    // the chapter page. Quiet, but never a bare 13 px name.
                    Text(
                      'Source: ${fact.sourceOrg}',
                      key: ValueKey('guide-fact-source-${fact.id}'),
                      style: AppText.small.copyWith(color: palette.inkSoft),
                    ),
                  ],
                ),
              ),
            ),
          // "Try this" on its own raised piece, headed by the need's own
          // paper icon: a change of rhythm after the facts. (A 4 px colour
          // strip down the left edge was cut square by the rounded corners
          // and read as a stray line.) Even 16 inside on every side: the
          // last idea's 12 below plus 4.
          if (g.tryThis.isNotEmpty) ...[
            const SizedBox(height: AppSpace.s),
            PaperCard(
              key: const ValueKey('guide-try-this'),
              raised: true,
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                AppSpace.l,
                AppSpace.l,
                AppSpace.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.m),
                    child: Row(
                      children: [
                        if (need != null) ...[
                          ExcludeSemantics(
                            child: Image.asset(
                              need.iconPath,
                              key: const ValueKey('guide-try-this-icon'),
                              width: 28,
                              height: 28,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox(width: 28, height: 28),
                            ),
                          ),
                          const SizedBox(width: AppSpace.s),
                        ],
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              'Try this',
                              style: AppText.heading.copyWith(
                                color: palette.ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final idea in g.tryThis)
                    _Bullet(
                      palette: palette,
                      child: Text(idea, style: _body(palette)),
                    ),
                ],
              ),
            ),
          ],
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
            builder: (list) => UrgentSignsBlock(
              urgent: list,
              palette: palette,
              compact: true,
              week: state.currentWeek,
            ),
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

  /// [bullet], marked when [fact] answers the parent's question.
  Widget _markIfAnswer(GuideFact fact, AppPalette palette, Widget bullet) {
    final id = answerFact;
    if (id == null || id.isEmpty || fact.id != id) return bullet;
    return AnswerMark(
      key: ValueKey('guide-answer-${fact.id}'),
      palette: palette,
      announcement: fact.text,
      child: bullet,
    );
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

/// The fact that answers the question the parent followed from a chapter:
/// a soft tint of the look's accent with a 4 px accent rule at its start
/// edge (the rule is 3:1 or more on paper in both looks; ink stays 4.5:1 or
/// more on the tint). On its first frame it scrolls itself into view, or
/// jumps there when motion is reduced, and screen readers hear it first.
class AnswerMark extends StatefulWidget {
  const AnswerMark({
    super.key,
    required this.palette,
    required this.announcement,
    required this.child,
  });

  final AppPalette palette;

  /// What screen readers announce on arrival: the fact's own text.
  final String announcement;
  final Widget child;

  /// How strongly the accent tints the paper behind the fact.
  static const double tintAlpha = 0.14;

  /// The background behind the marked fact.
  static Color tint(AppPalette p) =>
      Color.alphaBlend(p.accent.withValues(alpha: tintAlpha), p.paper);

  @override
  State<AnswerMark> createState() => _AnswerMarkState();
}

class _AnswerMarkState extends State<AnswerMark> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _arrive());
  }

  void _arrive() {
    if (!mounted) return;
    final still = MediaQuery.disableAnimationsOf(context);
    Scrollable.ensureVisible(
      context,
      alignment: 0.15,
      duration: still ? Duration.zero : const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
    final view = View.maybeOf(context);
    if (view != null) {
      SemanticsService.sendAnnouncement(
        view,
        widget.announcement,
        Directionality.of(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AnswerMark.tint(p),
          border: BorderDirectional(
            start: BorderSide(color: p.accent, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpace.m,
            AppSpace.m,
            AppSpace.m,
            0,
          ),
          child: widget.child,
        ),
      ),
    );
  }
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

  /// Null for a question from a topic guide.
  final MaternalNeed? need;
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
              origin: VisitOrigin.guide,
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
              child: VisitListButton(
                onPressed: _busy ? null : () => _change(add: true),
                label: 'Add to visit list',
                semanticsLabel: 'Add to visit list: ${widget.question}',
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

/// What the guide cards show, from a need's [Guide] or a [TopicGuide].
class _GuideBody {
  const _GuideBody({
    required this.title,
    required this.costumeLine,
    required this.isDraft,
    required this.lastChecked,
    required this.point,
    required this.ifHard,
    required this.callToday,
    required this.closing,
    required this.facts,
    required this.tryThis,
    required this.questions,
    required this.sources,
  });

  factory _GuideBody.of(Guide g) => _GuideBody(
    title: null,
    costumeLine: g.costumeLine,
    isDraft: g.isDraft,
    lastChecked: g.lastChecked,
    point: g.point,
    ifHard: g.ifHard,
    callToday: g.callToday,
    closing: g.closing,
    facts: g.facts,
    tryThis: g.tryThis,
    questions: g.questions,
    sources: g.sources,
  );

  /// A topic guide: its title line heads card 1, and there is no costume
  /// line. Draft when the guide or its title is a draft.
  factory _GuideBody.ofTopic(TopicGuideEntry t) => _GuideBody(
    title: t.title.text,
    costumeLine: null,
    isDraft: t.guide.isDraft || t.title.isDraft,
    lastChecked: t.guide.lastChecked,
    point: t.guide.point,
    ifHard: t.guide.ifHard,
    callToday: t.guide.callToday,
    closing: t.guide.closing,
    facts: t.guide.facts,
    tryThis: t.guide.tryThis,
    questions: t.guide.questions,
    sources: t.guide.sources,
  );

  /// Null for a need's guide (card 1 then shows the need's word).
  final String? title;
  final String? costumeLine;
  final bool isDraft;
  final String lastChecked, point, ifHard, callToday, closing;
  final List<GuideFact> facts;
  final List<String> tryThis, questions;
  final List<GuideSource> sources;
}
