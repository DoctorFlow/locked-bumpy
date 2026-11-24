part of 'this_week_screen.dart';

// A chapter page: one stretch of weeks told as a page of a storybook.
// Order (CHAPTER-CONTRACT.md): picture with title and weeks, Bumpy's line,
// one thing to know, the card for this exact week, one thing to get ready,
// something to look forward to, then the curious question as a way into
// the guide.

/// Opens the guide for [need]. When the gate hides that guide (not approved,
/// and not a draft in a review build), the Guides tab opens instead, where
/// the need's card still offers its visit-list control: never an empty page.
/// [answerFact] is the id of the fact that answers the chapter's question:
/// the guide opens at that fact and marks it.
Future<void> _openGuide(
  BuildContext context,
  AppState state,
  MaternalNeed need, {
  String answerFact = '',
}) async {
  final guides = await ContentLoader.loadGuides();
  if (!context.mounted) return;
  if (guides[need] == null) {
    state.setTab(2);
    return;
  }
  await GuideScreen.open(context, state, need, answerFact: answerFact);
}

/// Width over height of every chapter picture (1200 x 900).
const double chapterPictureAspect = 4 / 3;

const _darkOnAccent = Color(0xFF2E2040);
const _lightOnAccent = Color(0xFFFFF8EE);

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
}

/// Text colour with the stronger contrast on the chapter's accent paper.
Color _onAccent(Color accent) =>
    _contrast(accent, _darkOnAccent) >= _contrast(accent, _lightOnAccent)
    ? _darkOnAccent
    : _lightOnAccent;

/// The chapter's colour as a fill that carries text, and the text on it.
///
/// Most chapter colours are mid tones that reach about 4:1 with both dark and
/// light text. The fill moves the smallest step towards deep plum (light
/// text) or towards cream (dark text) that gives at least 4.5:1, so the hue
/// stays the chapter's own. Used for the title band and the main button.
(Color, Color) _accentPair(Color accent) {
  final text = _onAccent(accent);
  if (_contrast(accent, text) >= 4.5) return (accent, text);
  for (var t = .02; t < 1; t += .02) {
    final deep = Color.lerp(accent, _darkOnAccent, t)!;
    if (_contrast(deep, _lightOnAccent) >= 4.5) return (deep, _lightOnAccent);
    final light = Color.lerp(accent, _lightOnAccent, t)!;
    if (_contrast(light, _darkOnAccent) >= 4.5) return (light, _darkOnAccent);
  }
  return (_darkOnAccent, _lightOnAccent);
}

class _ChapterPage extends StatelessWidget {
  const _ChapterPage({
    required this.chapter,
    required this.week,
    required this.card,
    required this.palette,
    required this.state,
    required this.isCurrentWeek,
    required this.currentWeek,
    required this.onReturn,
    required this.onVisit,
  });

  final Chapter chapter;
  final int week;
  final WeekCard? card;
  final AppPalette palette;
  final AppState state;
  final bool isCurrentWeek;

  /// The parent's own week today, which may sit outside this chapter.
  final int currentWeek;
  final VoidCallback onReturn;
  final VoidCallback onVisit;

  @override
  Widget build(BuildContext context) {
    final (band, onBand) = _accentPair(chapter.accent);
    final body = AppText.body.copyWith(color: palette.ink);
    final onList = chapterQuestionsOnList(
      chapter,
      state.visitQuestions,
      dueDate: state.dueDate,
    );
    final showSuggestion =
        chapter.suggestedQuestion.trim().isNotEmpty &&
        !state.hasVisitQuestion(chapter.suggestedQuestion);
    final bumpy = BumpyAvatar(
      need: state.costumeOverride ?? state.todayNeed,
      palette: palette,
      happy: true,
      skinTone: state.skinTone,
    );
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChapterHeader(
            chapter: chapter,
            palette: palette,
            bumpy: bumpy,
            band: band,
            onBand: onBand,
            shownWeek: week,
            currentWeek: currentWeek,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              AppSpace.l,
              AppSpace.l,
              AppSpace.l,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Opening: Bumpy speaks straight under the picture, so the
                // first screen holds the picture, the line and the start of
                // one thing to know (the strip in the band says where).
                _BumpySays(
                  line: chapter.bumpyLine,
                  nickname: state.nickname,
                  palette: palette,
                  bumpy: bumpy,
                ),
                const SizedBox(height: AppSpace.l),
                // Know: plain text on the card, the calmest section.
                _SectionTitle(
                  'One thing to know',
                  icon: Icons.lightbulb_outline_rounded,
                  marker: band,
                  palette: palette,
                ),
                const SizedBox(height: AppSpace.s),
                Text(chapter.knowText, style: body),
                const SizedBox(height: AppSpace.s),
                // Quiet text only: the app opens no links. Regular 14, and
                // only the page's own title, not the site name the web page
                // adds after " - " (display trimming; the record is kept).
                Text(
                  chapterSourceLine(
                    chapter.knowSourceOrg,
                    chapter.knowSourceTitle,
                  ),
                  key: const ValueKey('chapter-know-source'),
                  style: AppText.small.copyWith(color: palette.inkSoft),
                ),
                const SizedBox(height: AppSpace.xl),
                // The card for this exact week: what makes week 21 its own.
                _ChapterWeekCard(
                  week: week,
                  card: card,
                  palette: palette,
                  band: band,
                  onBand: onBand,
                  isCurrentWeek: isCurrentWeek,
                  onReturn: onReturn,
                ),
                const SizedBox(height: AppSpace.xxl),
                // Get ready: the suggested question is its own piece with
                // its one action; writing your own sits outside it.
                _ReadyFrame(
                  palette: palette,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionTitle(
                        'One thing to get ready',
                        icon: Icons.checklist_rounded,
                        marker: band,
                        palette: palette,
                      ),
                      const SizedBox(height: AppSpace.s),
                      Text(chapter.readyText, style: body),
                      const SizedBox(height: AppSpace.l),
                      // What the parent saved shows back; the chapter's own
                      // suggestion stays on offer until it is on the list
                      // too, so writing your own words never hides it.
                      if (onList.isNotEmpty) ...[
                        _OnYourList(questions: onList, palette: palette),
                        const SizedBox(height: AppSpace.m),
                      ],
                      if (showSuggestion) ...[
                        PaperCard(
                          key: const ValueKey('chapter-question-piece'),
                          raised: true,
                          padding: const EdgeInsets.all(AppSpace.l),
                          child: _AddQuestion(
                            question: chapter.suggestedQuestion,
                            week: week,
                            state: state,
                            palette: palette,
                          ),
                        ),
                        const SizedBox(height: AppSpace.m),
                      ],
                      OutlinedButton.icon(
                        onPressed: onVisit,
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('Write my own question'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xxl),
                // Look forward: a piece washed in the chapter colour, with
                // Bumpy looking forward too.
                _TintedPiece(
                  key: const ValueKey('chapter-look-forward'),
                  tint: band,
                  palette: palette,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _WithBumpy(
                        bumpy: bumpy,
                        child: _SectionTitle(
                          'Something to look forward to',
                          icon: Icons.wb_sunny_rounded,
                          marker: band,
                          palette: palette,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s),
                      Text(chapter.lookForward, style: body),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.l),
                _CuriousLink(
                  question: chapter.curiousQuestion,
                  need: chapter.curiousNeed,
                  palette: palette,
                  band: band,
                  onBand: onBand,
                  onTap: () => _openGuide(
                    context,
                    state,
                    chapter.curiousNeed,
                    answerFact: chapter.curiousAnswerFact,
                  ),
                ),
                _ChapterTopicLinks(
                  chapterId: chapter.id,
                  state: state,
                  palette: palette,
                  band: band,
                  onBand: onBand,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// True when a side-by-side face and bubble would squeeze the words: a
/// narrow column or large system text. Bumpy then stands above instead.
bool _stackBumpy(BuildContext context, double width) =>
    width < 300 || MediaQuery.textScalerOf(context).scale(16) > 24;

/// [child] with a small Bumpy face at its right; no face when narrow.
class _WithBumpy extends StatelessWidget {
  const _WithBumpy({required this.bumpy, required this.child});

  final Widget bumpy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        const size = 48.0;
        // The face is decoration: where it would squeeze the words (a
        // narrow phone or large text), the words keep the whole width.
        if (box.maxWidth < 240 ||
            MediaQuery.textScalerOf(context).scale(16) > 24) {
          return child;
        }
        final face = ExcludeSemantics(
          key: const ValueKey('chapter-look-forward-face'),
          child: SizedBox.square(
            dimension: size,
            child: FittedBox(child: bumpy),
          ),
        );
        return Row(
          children: [
            Expanded(child: child),
            const SizedBox(width: AppSpace.m),
            face,
          ],
        );
      },
    );
  }
}

/// Picture, deckled at the bottom like torn paper, over the band in the
/// chapter's colour that carries the title and weeks.
class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({
    required this.chapter,
    required this.palette,
    required this.bumpy,
    required this.band,
    required this.onBand,
    required this.shownWeek,
    required this.currentWeek,
  });

  final Chapter chapter;
  final AppPalette palette;
  final Widget bumpy;
  final Color band;
  final Color onBand;
  final int shownWeek;
  final int currentWeek;

  @override
  Widget build(BuildContext context) {
    final panel = _AccentPaperPanel(
      accent: chapter.accent,
      palette: palette,
      bumpy: bumpy,
    );
    return ColoredBox(
      color: band,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The review marker is a sticker on the picture's corner, never
          // part of the band: the band lays out the same with or without
          // it, and a release build never has it.
          Stack(
            children: [
              ClipPath(
                clipper: const _DeckledEdge(),
                child: ExcludeSemantics(
                  // The pictures are 4:3 (1200 x 900). Show all of it at every
                  // width; the torn edge trims only its lowest few pixels. The
                  // missing-picture panel takes the same 4:3 box.
                  child: AspectRatio(
                    key: const ValueKey('chapter-picture'),
                    aspectRatio: chapterPictureAspect,
                    child: Image.asset(
                      chapter.illustrationPath(halloween: palette.isHalloween),
                      key: ValueKey(
                        chapter.illustrationPath(
                          halloween: palette.isHalloween,
                        ),
                      ),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      frameBuilder: (context, child, frame, sync) =>
                          frame == null && !sync ? panel : child,
                      errorBuilder: (context, error, stack) => panel,
                    ),
                  ),
                ),
              ),
              if (chapter.review() == Review.draft)
                Positioned(
                  key: const ValueKey('chapter-draft-sticker'),
                  top: AppSpace.m,
                  right: AppSpace.m,
                  child: DraftTag(palette: palette),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              AppSpace.s,
              AppSpace.l,
              AppSpace.l,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    chapter.title,
                    style: AppText.display.copyWith(color: onBand),
                  ),
                ),
                const SizedBox(height: AppSpace.s),
                // A small paper tag, readable on any chapter colour, then
                // the chapter's weeks as a strip with the parent's own week
                // marked: a place on the page, never a count.
                Wrap(
                  spacing: AppSpace.m,
                  runSpacing: AppSpace.s,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _weeksTag(),
                    _WeekStrip(
                      fromWeek: chapter.fromWeek,
                      toWeek: chapter.toWeek,
                      shownWeek: shownWeek,
                      currentWeek: currentWeek,
                      palette: palette,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weeksTag() => DecoratedBox(
    key: const ValueKey('chapter-weeks-tag'),
    decoration: BoxDecoration(
      color: palette.paper,
      borderRadius: AppRadii.tag,
      boxShadow: paperShadows(palette, raised: true),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.m,
        vertical: AppSpace.s,
      ),
      child: Text(
        'Weeks ${chapter.fromWeek} to ${chapter.toWeek}',
        style: AppText.label.copyWith(color: palette.ink),
      ),
    ),
  );
}

/// The chapter's weeks as small paper squares. The parent's own week (when
/// it falls in this chapter) is dark paper with a pin; the week on screen,
/// when it is another one, has a dark edge. Read aloud as one line.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.fromWeek,
    required this.toWeek,
    required this.shownWeek,
    required this.currentWeek,
    required this.palette,
  });

  final int fromWeek;
  final int toWeek;
  final int shownWeek;
  final int currentWeek;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final here = currentWeek >= fromWeek && currentWeek <= toWeek;
    final spoken = here
        ? 'Your week now: week $currentWeek'
        : 'Showing week $shownWeek';
    return Semantics(
      key: const ValueKey('chapter-week-strip'),
      label: spoken,
      excludeSemantics: true,
      child: Wrap(
        spacing: AppSpace.xs,
        runSpacing: AppSpace.xs,
        children: [
          for (var w = fromWeek; w <= toWeek; w++)
            _square(w, mine: w == currentWeek, shown: w == shownWeek),
        ],
      ),
    );
  }

  Widget _square(int w, {required bool mine, required bool shown}) {
    final fill = mine ? palette.ink : palette.paper;
    final ink = mine ? palette.paper : palette.ink;
    return DecoratedBox(
      key: ValueKey(mine ? 'chapter-strip-mine-$w' : 'chapter-strip-$w'),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadii.tag,
        border: Border.all(
          color: shown && !mine ? palette.ink : Colors.transparent,
          width: 2,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s,
            vertical: AppSpace.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (mine) ...[
                Icon(Icons.place_rounded, size: 14, color: ink),
                const SizedBox(width: 2),
              ],
              Text('$w', style: AppText.label.copyWith(color: ink)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stand-in picture when the chapter's art is not bundled yet: a light
/// accent sky, two cut-paper hills, a moon, and Bumpy on top.
class _AccentPaperPanel extends StatelessWidget {
  const _AccentPaperPanel({
    required this.accent,
    required this.palette,
    required this.bumpy,
  });

  final Color accent;
  final AppPalette palette;
  final Widget bumpy;

  @override
  Widget build(BuildContext context) {
    final sky = Color.lerp(
      accent,
      palette.isHalloween ? palette.skyTop : palette.paper,
      palette.isHalloween ? .55 : .5,
    )!;
    return ColoredBox(
      color: sky,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _PaperHillsPainter(
              accent: accent,
              moon: palette.moon,
              shadow: palette.shadow,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.s, bottom: AppSpace.l),
            child: FittedBox(child: bumpy),
          ),
        ],
      ),
    );
  }
}

class _PaperHillsPainter extends CustomPainter {
  const _PaperHillsPainter({
    required this.accent,
    required this.moon,
    required this.shadow,
  });

  final Color accent;
  final Color moon;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final under = Paint()..color = shadow.withValues(alpha: .3);
    void paper(Path path, Color color) {
      canvas.drawPath(path.shift(const Offset(0, 2)), under);
      canvas.drawPath(path, Paint()..color = color);
    }

    paper(
      Path()..addOval(
        Rect.fromCircle(center: Offset(w * .84, h * .24), radius: h * .13),
      ),
      moon,
    );
    paper(
      Path()
        ..moveTo(0, h * .72)
        ..quadraticBezierTo(w * .25, h * .48, w * .55, h * .7)
        ..quadraticBezierTo(w * .8, h * .86, w, h * .66)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Color.lerp(accent, Colors.white, .2)!,
    );
    paper(
      Path()
        ..moveTo(0, h * .88)
        ..quadraticBezierTo(w * .4, h * .7, w * .7, h * .86)
        ..quadraticBezierTo(w * .88, h * .95, w, h * .84)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Color.lerp(accent, Colors.black, .12)!,
    );
  }

  @override
  bool shouldRepaint(_PaperHillsPainter old) =>
      old.accent != accent || old.moon != moon || old.shadow != shadow;
}

/// A soft torn-paper bottom edge.
class _DeckledEdge extends CustomClipper<Path> {
  const _DeckledEdge();

  @override
  Path getClip(Size size) {
    const step = 22.0;
    const dip = 5.0;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - dip);
    var x = size.width;
    var up = true;
    while (x > 0) {
      final next = math.max(0.0, x - step);
      path.quadraticBezierTo(
        (x + next) / 2,
        up ? size.height : size.height - dip * 2,
        next,
        size.height - dip,
      );
      x = next;
      up = !up;
    }
    return path..close();
  }

  @override
  bool shouldReclip(_DeckledEdge oldClipper) => false;
}

/// A small cut-paper diamond in the chapter's colour before each heading.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(
    this.text, {
    required this.icon,
    required this.marker,
    required this.palette,
  });

  final String text;
  final IconData icon;
  final Color marker;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final (fill, onFill) = _accentPair(marker);
    return Row(
      children: [
        // Each part has its own small sign in the chapter colour, so the
        // three are told apart at a glance. Decorative.
        ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: AppRadii.tag,
              boxShadow: [
                BoxShadow(
                  color: palette.shadow.withValues(
                    alpha: palette.isHalloween ? 1 : .45,
                  ),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(icon, size: 20, color: onFill),
            ),
          ),
        ),
        const SizedBox(width: AppSpace.m),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              text,
              style: AppText.heading.copyWith(color: palette.ink),
            ),
          ),
        ),
      ],
    );
  }
}

/// A piece on the card washed with the chapter's colour. [PaperCard] only
/// knows plain raised paper, so this one is drawn here with the same edge,
/// corners and shadow.
class _TintedPiece extends StatelessWidget {
  const _TintedPiece({
    super.key,
    required this.tint,
    required this.palette,
    required this.child,
  });

  final Color tint;
  final AppPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        // A lighter wash at night, where the mix turns muddy sooner.
        color: Color.lerp(
          palette.paperRaised,
          tint,
          palette.isHalloween ? .2 : .3,
        ),
        borderRadius: AppRadii.control,
        border: Border.all(color: palette.edge),
        boxShadow: paperShadows(palette, raised: true),
      ),
      child: Padding(padding: const EdgeInsets.all(AppSpace.l), child: child),
    );
  }
}

/// Bumpy's line, spoken: a small Bumpy beside a paper speech bubble whose
/// tail points at them. On a narrow or large-text screen Bumpy stands above
/// the bubble instead.
///
/// When the page first builds, Bumpy hops once (the Today room's hop: up
/// 18 px with ease-out, down with a bounce) and the bubble fades in while
/// sliding up 8 px. Both are skipped when the system asks for less motion.
class _BumpySays extends StatefulWidget {
  const _BumpySays({
    required this.line,
    required this.nickname,
    required this.palette,
    required this.bumpy,
  });

  final String line;

  /// The name the parent gave the baby; empty when none was given.
  final String nickname;
  final AppPalette palette;
  final Widget bumpy;

  /// The whole opening: the hop takes all of it, the bubble the first 250 ms.
  static const opening = Duration(milliseconds: 450);
  static const hopHeight = 18.0;
  static const bubbleRise = 8.0;

  @override
  State<_BumpySays> createState() => _BumpySaysState();
}

class _BumpySaysState extends State<_BumpySays>
    with SingleTickerProviderStateMixin {
  late final AnimationController _opening = AnimationController(
    vsync: this,
    duration: _BumpySays.opening,
  );

  // The same hop as the Today room (bumpy_avatar.dart).
  late final Animation<double> _hop = bumpyHop(
    height: _BumpySays.hopHeight,
  ).animate(_opening);

  late final Animation<double> _bubble = CurvedAnimation(
    parent: _opening,
    curve: Interval(
      0,
      250 / _BumpySays.opening.inMilliseconds,
      curve: Curves.easeOut,
    ),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _opening.value = 1;
    } else {
      _opening.forward();
    }
  }

  @override
  void dispose() {
    _opening.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final still = MediaQuery.disableAnimationsOf(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return Semantics(
      container: true,
      label: widget.nickname.isEmpty ? 'Bumpy says' : '${widget.nickname} says',
      child: LayoutBuilder(
        builder: (context, box) {
          final stacked = _stackBumpy(context, box.maxWidth);
          const size = 64.0;
          final face = ExcludeSemantics(
            child: SizedBox.square(
              key: const ValueKey('chapter-bumpy-face'),
              dimension: size,
              child: FittedBox(child: widget.bumpy),
            ),
          );
          final hopping = still
              ? face
              : AnimatedBuilder(
                  animation: _hop,
                  child: face,
                  builder: (_, child) => Transform.translate(
                    key: const ValueKey('chapter-bumpy-hop'),
                    // Whole device pixels, so the paper is not resampled.
                    offset: Offset(
                      0,
                      (_hop.value * pixelRatio).roundToDouble() / pixelRatio,
                    ),
                    child: child,
                  ),
                );
          final bubble = _SpeechBubble(
            palette: palette,
            tailUp: stacked,
            child: widget.nickname.isEmpty
                ? Text(
                    widget.line,
                    style: AppText.bumpyStory.copyWith(color: palette.ink),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The parent's own name for the baby, signed on the
                      // bubble like a name on a note.
                      Text(
                        widget.nickname,
                        key: const ValueKey('chapter-bumpy-name'),
                        style: AppText.label.copyWith(color: palette.inkSoft),
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        widget.line,
                        style: AppText.bumpyStory.copyWith(color: palette.ink),
                      ),
                    ],
                  ),
          );
          final arriving = still
              ? bubble
              : AnimatedBuilder(
                  animation: _bubble,
                  child: bubble,
                  builder: (_, child) => Opacity(
                    key: const ValueKey('chapter-bubble-fade'),
                    opacity: _bubble.value,
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        _BumpySays.bubbleRise * (1 - _bubble.value),
                      ),
                      child: child,
                    ),
                  ),
                );
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: AppSpace.s),
                  child: hopping,
                ),
                arriving,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              hopping,
              Expanded(child: arriving),
            ],
          );
        },
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({
    required this.palette,
    required this.tailUp,
    required this.child,
  });

  final AppPalette palette;
  final bool tailUp;
  final Widget child;

  static const double tail = 14;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(palette: palette, tailUp: tailUp),
      child: Padding(
        padding: tailUp
            ? const EdgeInsets.fromLTRB(
                AppSpace.l,
                tail + AppSpace.m,
                AppSpace.l,
                AppSpace.l,
              )
            : const EdgeInsets.fromLTRB(
                tail + AppSpace.l,
                AppSpace.m,
                AppSpace.l,
                AppSpace.l,
              ),
        child: child,
      ),
    );
  }
}

/// Raised paper with hand-cut corners and a small tail, a 1 px lit edge and
/// the hard paper shadow.
class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.palette, required this.tailUp});

  final AppPalette palette;
  final bool tailUp;

  Path _shape(Size size) {
    const t = _SpeechBubble.tail;
    final body = tailUp
        ? Rect.fromLTWH(0, t, size.width, size.height - t)
        : Rect.fromLTWH(t, 0, size.width - t, size.height);
    final r = AppRadii.card;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          body,
          topLeft: r.topLeft,
          topRight: r.topRight,
          bottomRight: r.bottomRight,
          bottomLeft: r.bottomLeft,
        ),
      );
    final tip = tailUp
        ? (Path()
            ..moveTo(24, t + 6)
            ..lineTo(32, 0)
            ..lineTo(48, t + 6)
            ..close())
        : (Path()
            ..moveTo(t + 6, 22)
            ..lineTo(0, 30)
            ..lineTo(t + 6, 44)
            ..close());
    return Path.combine(PathOperation.union, path, tip);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shape = _shape(size);
    canvas.drawPath(
      shape.shift(const Offset(0, 2)),
      Paint()
        ..color = palette.shadow.withValues(
          alpha: palette.isHalloween ? 1 : .45,
        ),
    );
    canvas.drawPath(shape, Paint()..color = palette.paperRaised);
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = palette.edge,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.palette != palette || old.tailUp != tailUp;
}

/// The existing weekly card for this exact week, inside the chapter.
class _ChapterWeekCard extends StatelessWidget {
  const _ChapterWeekCard({
    required this.week,
    required this.card,
    required this.palette,
    required this.band,
    required this.onBand,
    required this.isCurrentWeek,
    required this.onReturn,
  });

  final int week;
  final WeekCard? card;
  final AppPalette palette;
  final Color band;
  final Color onBand;
  final bool isCurrentWeek;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      raised: true,
      padding: const EdgeInsets.all(AppSpace.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpace.m,
            runSpacing: AppSpace.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Week $week',
                  style: AppText.title.copyWith(color: palette.ink),
                ),
              ),
              if (isCurrentWeek) _HereTag(fill: band, ink: onBand),
              // Only a review build ever shows a draft card.
              if (card?.isDraft ?? false)
                DraftTag.of(palette: palette, held: card!.isHeld),
            ],
          ),
          if (card != null) ...[
            const SizedBox(height: AppSpace.s),
            Text(
              card!.babyLine,
              style: AppText.bumpyStory.copyWith(color: palette.ink),
            ),
          ],
          if (!isCurrentWeek) ...[
            const SizedBox(height: AppSpace.s),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: palette.ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: AppSpace.m,
                ),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back to this week'),
              onPressed: onReturn,
            ),
          ],
        ],
      ),
    );
  }
}

/// "You are here" as a small paper tag.
class _HereTag extends StatelessWidget {
  const _HereTag({required this.fill, required this.ink});

  final Color fill;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: fill, borderRadius: AppRadii.tag),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s,
          vertical: AppSpace.xs,
        ),
        child: Text('You are here', style: AppText.label.copyWith(color: ink)),
      ),
    );
  }
}

/// One tap puts the chapter's question on the visit list.
class _AddQuestion extends StatefulWidget {
  const _AddQuestion({
    required this.question,
    required this.week,
    required this.state,
    required this.palette,
  });

  final String question;
  final int week;
  final AppState state;
  final AppPalette palette;

  @override
  State<_AddQuestion> createState() => _AddQuestionState();
}

class _AddQuestionState extends State<_AddQuestion> {
  bool _saving = false;
  bool _notSaved = false;

  Future<void> _add() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _notSaved = false;
    });
    final ok = await widget.state.addVisitQuestion(
      widget.question,
      origin: VisitOrigin.week,
      week: widget.week,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _notSaved = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final added = widget.state.hasVisitQuestion(widget.question);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '“${widget.question}”',
          style: AppText.bodyStrong.copyWith(color: palette.ink),
        ),
        const SizedBox(height: AppSpace.m),
        Semantics(
          liveRegion: true,
          child: added
              ? ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: palette.ink,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpace.s),
                      Expanded(
                        child: Text(
                          'On your visit list',
                          style: AppText.bodyStrong.copyWith(
                            color: palette.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              // The one form of this action on Guides, the guide page and
              // here (`VisitListButton` in guides_screen.dart; this part
              // file cannot import it): full width, outlined, list-plus.
              : OutlinedButton.icon(
                  key: const ValueKey('chapter-add-question'),
                  onPressed: _saving ? null : _add,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSpace.target),
                  ),
                  icon: const Icon(Icons.playlist_add, size: 22),
                  label: const Text(
                    'Add to my visit list',
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
        if (_notSaved)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            child: Text(
              'That did not save. You can try again.',
              style: AppText.body.copyWith(color: palette.ink),
            ),
          ),
      ],
    );
  }
}

/// The topic guides that belong to this chapter (`chapter` in
/// `topic_guides.json`): one more row each under the curious question,
/// labelled with the guide's own title. Nothing when the gate shows none.
class _ChapterTopicLinks extends StatelessWidget {
  const _ChapterTopicLinks({
    required this.chapterId,
    required this.state,
    required this.palette,
    required this.band,
    required this.onBand,
  });

  final String chapterId;
  final AppState state;
  final AppPalette palette;
  final Color band;
  final Color onBand;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TopicGuideEntry>>(
      future: ContentLoader.loadTopicGuides(),
      initialData: ContentLoader.loadedTopicGuides,
      builder: (context, snapshot) {
        final mine = [
          for (final t in snapshot.data ?? const <TopicGuideEntry>[])
            if (t.guide.chapter == chapterId) t,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final topic in mine) ...[
              const SizedBox(height: AppSpace.m),
              TopicGuideRow(
                key: ValueKey('chapter-topic-${topic.guide.id}'),
                title: topic.title.text,
                isDraft: topic.guide.isDraft || topic.title.isDraft,
                palette: palette,
                iconTile: band,
                iconColor: onBand,
                onTap: () => GuideScreen.openTopic(context, state, topic),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The curious question: a paper row that opens the guide for its need.
class _CuriousLink extends StatelessWidget {
  const _CuriousLink({
    required this.question,
    required this.need,
    required this.palette,
    required this.band,
    required this.onBand,
    required this.onTap,
  });

  final String question;
  final MaternalNeed need;
  final AppPalette palette;
  final Color band;
  final Color onBand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      raised: true,
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpace.row),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.m,
                AppSpace.m,
                AppSpace.s,
                AppSpace.m,
              ),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: band,
                      borderRadius: AppRadii.tag,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.s),
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 24,
                        color: onBand,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.m),
                  Expanded(
                    child: Text(
                      question,
                      semanticsLabel:
                          '$question Opens the ${needWord(need)} guide.',
                      style: AppText.bodyStrong.copyWith(color: palette.ink),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 24,
                    color: palette.inkSoft,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The chapter's quiet source line: "Source: NHS, 15 weeks pregnant guide".
/// Web page titles carry the site after " - " ("... - Best Start in Life -
/// NHS"); only the first part is shown, and the stored record is untouched.
String chapterSourceLine(String org, String title) {
  final page = title.split(' - ').first.trim();
  return page.isEmpty ? 'Source: $org' : 'Source: $org, $page';
}

/// The questions already on the visit list that belong to [chapter]: its
/// own suggested question, any question picked on one of its weeks, and the
/// parent's own words added while they were in its weeks. The parent's own
/// words first; at most three, the latest of each kind kept.
List<VisitQuestion> chapterQuestionsOnList(
  Chapter chapter,
  List<VisitQuestion> list, {
  DateTime? dueDate,
}) {
  final suggested = chapter.suggestedQuestion.trim();
  bool belongs(VisitQuestion q) {
    if (suggested.isNotEmpty && q.text == suggested) return true;
    if (q.origin == VisitOrigin.week && q.week != null) {
      return chapter.contains(q.week!);
    }
    final added = q.added;
    if (q.isOwnWords && added != null && dueDate != null) {
      return chapter.contains(
        PregnancyCalculator.weekFromDueDate(
          dueDate: dueDate,
          currentDate: added,
        ),
      );
    }
    return false;
  }

  final mine = VisitQuestion.ownFirst(list.where(belongs));
  return mine.length <= 3 ? mine : mine.sublist(mine.length - 3);
}

/// "On your list": the chapter's get-ready part shows back what the parent
/// already saved, in place of offering the same question again.
class _OnYourList extends StatelessWidget {
  const _OnYourList({required this.questions, required this.palette});

  final List<VisitQuestion> questions;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      key: const ValueKey('chapter-on-list'),
      raised: true,
      padding: const EdgeInsets.all(AppSpace.l),
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: palette.ink, size: 24),
                const SizedBox(width: AppSpace.s),
                Expanded(
                  child: Text(
                    'On your list:',
                    style: AppText.bodyStrong.copyWith(color: palette.ink),
                  ),
                ),
              ],
            ),
            for (final q in questions) ...[
              const SizedBox(height: AppSpace.s),
              Text(
                '“${q.text}”',
                style: AppText.body.copyWith(color: palette.ink),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The get-ready part: an outline cut around it, no fill, so it reads as the
/// practical part between the plain "know" text and the warm look-forward
/// piece. A border only, not another paper level.
class _ReadyFrame extends StatelessWidget {
  const _ReadyFrame({required this.palette, required this.child});

  final AppPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('chapter-ready-frame'),
      decoration: BoxDecoration(
        borderRadius: AppRadii.control,
        border: Border.all(color: palette.outline, width: 1.5),
      ),
      child: Padding(padding: const EdgeInsets.all(AppSpace.l), child: child),
    );
  }
}
