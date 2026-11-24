part of 'this_week_screen.dart';

// A chapter page: one stretch of weeks told as a page of a storybook.
// Order (CHAPTER-CONTRACT.md): picture with title and weeks, Bumpy's line,
// one thing to know, the card for this exact week, one thing to get ready,
// something to look forward to, then the curious question as a way into
// the guide.

/// Opens the guide for [need]. When the gate hides that guide (not approved,
/// and not a draft in a review build), the Guides tab opens instead, where
/// the need's card still offers its visit-list control: never an empty page.
Future<void> _openGuide(
  BuildContext context,
  AppState state,
  MaternalNeed need,
) async {
  final guides = await ContentLoader.loadGuides();
  if (!context.mounted) return;
  if (guides[need] == null) {
    state.setTab(2);
    return;
  }
  await GuideScreen.open(context, state, need);
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
    required this.onReturn,
    required this.onVisit,
  });

  final Chapter chapter;
  final int week;
  final WeekCard? card;
  final AppPalette palette;
  final AppState state;
  final bool isCurrentWeek;
  final VoidCallback onReturn;
  final VoidCallback onVisit;

  @override
  Widget build(BuildContext context) {
    final (band, onBand) = _accentPair(chapter.accent);
    final body = AppText.body.copyWith(color: palette.ink);
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              AppSpace.xl,
              AppSpace.l,
              AppSpace.l,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Opening: where the parent is, then Bumpy speaks.
                _ChapterWeekCard(
                  week: week,
                  card: card,
                  palette: palette,
                  band: band,
                  onBand: onBand,
                  isCurrentWeek: isCurrentWeek,
                  onReturn: onReturn,
                ),
                const SizedBox(height: AppSpace.l),
                _BumpySays(
                  line: chapter.bumpyLine,
                  palette: palette,
                  bumpy: bumpy,
                ),
                const SizedBox(height: AppSpace.xl),
                // Know: plain text on the card, the calmest section.
                _SectionTitle(
                  'One thing to know',
                  marker: band,
                  palette: palette,
                ),
                const SizedBox(height: AppSpace.s),
                Text(chapter.knowText, style: body),
                const SizedBox(height: AppSpace.s),
                // Quiet text only: the app opens no links.
                Text(
                  chapter.knowSourceTitle.isEmpty
                      ? 'Source: ${chapter.knowSourceOrg}'
                      : 'Source: ${chapter.knowSourceOrg}, '
                            '${chapter.knowSourceTitle}',
                  key: const ValueKey('chapter-know-source'),
                  style: AppText.label.copyWith(color: palette.inkSoft),
                ),
                const SizedBox(height: AppSpace.xxl),
                // Get ready: the suggested question is its own piece with
                // its one action; writing your own sits outside it.
                _SectionTitle(
                  'One thing to get ready',
                  marker: band,
                  palette: palette,
                ),
                const SizedBox(height: AppSpace.s),
                Text(chapter.readyText, style: body),
                const SizedBox(height: AppSpace.l),
                if (chapter.suggestedQuestion.isNotEmpty) ...[
                  PaperCard(
                    key: const ValueKey('chapter-question-piece'),
                    raised: true,
                    padding: const EdgeInsets.all(AppSpace.l),
                    child: _AddQuestion(
                      question: chapter.suggestedQuestion,
                      state: state,
                      palette: palette,
                      fill: band,
                      onFill: onBand,
                    ),
                  ),
                  const SizedBox(height: AppSpace.m),
                ],
                OutlinedButton.icon(
                  onPressed: onVisit,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Write my own question'),
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
                  onTap: () => _openGuide(context, state, chapter.curiousNeed),
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
  });

  final Chapter chapter;
  final AppPalette palette;
  final Widget bumpy;
  final Color band;
  final Color onBand;

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
                // A small paper tag, readable on any chapter colour.
                DecoratedBox(
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
                ),
              ],
            ),
          ),
        ],
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
  const _SectionTitle(this.text, {required this.marker, required this.palette});

  final String text;
  final Color marker;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PaperDiamond(color: marker, palette: palette),
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

/// A 12 px paper diamond with a hard shadow. Decorative.
class _PaperDiamond extends StatelessWidget {
  const _PaperDiamond({required this.color, required this.palette});

  final Color color;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(3),
            topRight: Radius.circular(1),
            bottomRight: Radius.circular(3),
            bottomLeft: Radius.circular(1),
          ),
          boxShadow: [
            BoxShadow(
              color: palette.shadow.withValues(
                alpha: palette.isHalloween ? 1 : .45,
              ),
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
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
          palette.isHalloween ? .12 : .16,
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
    required this.palette,
    required this.bumpy,
  });

  final String line;
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
      label: 'Bumpy says',
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
            child: Text(
              widget.line,
              style: AppText.bumpyStory.copyWith(color: palette.ink),
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
              if (card?.isDraft ?? false) DraftTag(palette: palette),
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
    required this.state,
    required this.palette,
    required this.fill,
    required this.onFill,
  });

  final String question;
  final AppState state;
  final AppPalette palette;
  final Color fill;
  final Color onFill;

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
              : FilledButton.icon(
                  onPressed: _saving ? null : _add,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.fill,
                    foregroundColor: widget.onFill,
                  ),
                  icon: const Icon(Icons.playlist_add_rounded),
                  label: const Text('Add to my visit list'),
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
