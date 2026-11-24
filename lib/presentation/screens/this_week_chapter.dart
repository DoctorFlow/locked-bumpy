part of 'this_week_screen.dart';

// A chapter page: one stretch of weeks told as a page of a storybook.
// Order (CHAPTER-CONTRACT.md): picture with title and weeks, Bumpy's line,
// one thing to know, the card for this exact week, one thing to get ready,
// something to look forward to, then the curious question as a quiet link.

/// Opens the guide for [need]. The one place the chapter page leaves for a
/// guide, so the integrator changes a single line.
void _openGuide(BuildContext context, AppState state, MaternalNeed need) {
  // integration: GuideScreen.open(context, state, need)
  state.setTab(2);
}

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

/// Fill and text for a button in the chapter's colour, deepened when needed
/// so its 16 px label keeps at least 4.5:1 contrast.
(Color, Color) _buttonColours(Color accent) {
  final text = _onAccent(accent);
  if (_contrast(accent, text) >= 4.5) return (accent, text);
  for (var t = .05; t < 1; t += .05) {
    final fill = Color.lerp(accent, _darkOnAccent, t)!;
    if (_contrast(fill, _lightOnAccent) >= 4.5) return (fill, _lightOnAccent);
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
    final accent = chapter.accent;
    final onAccent = _onAccent(accent);
    final titleStyle = TextStyle(
      color: palette.ink,
      fontWeight: FontWeight.bold,
      fontSize: 18,
    );
    final bodyStyle = TextStyle(color: palette.ink, fontSize: 16, height: 1.4);
    final softStyle = TextStyle(
      color: palette.inkSoft,
      fontSize: 16,
      height: 1.4,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: palette.paper,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ChapterHeader(
              chapter: chapter,
              palette: palette,
              state: state,
              onAccent: onAccent,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BumpySays(
                    line: chapter.bumpyLine,
                    accent: accent,
                    palette: palette,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    'One thing to know',
                    accent: accent,
                    style: titleStyle,
                  ),
                  const SizedBox(height: 6),
                  Text(chapter.knowText, style: bodyStyle),
                  const SizedBox(height: 6),
                  Text(
                    'Source: ${chapter.knowSourceOrg}',
                    style: softStyle.copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 20),
                  _ChapterWeekCard(
                    week: week,
                    card: card,
                    palette: palette,
                    accent: accent,
                    isCurrentWeek: isCurrentWeek,
                    onReturn: onReturn,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    'One thing to get ready',
                    accent: accent,
                    style: titleStyle,
                  ),
                  const SizedBox(height: 6),
                  Text(chapter.readyText, style: bodyStyle),
                  if (chapter.suggestedQuestion.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _AddQuestion(
                      question: chapter.suggestedQuestion,
                      state: state,
                      palette: palette,
                      accent: accent,
                    ),
                  ],
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: onVisit,
                      style: TextButton.styleFrom(
                        foregroundColor: palette.ink,
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Write my own question'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PaperPanel(
                    color: Color.lerp(palette.paperRaised, accent, .14)!,
                    edge: accent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                          'Something to look forward to',
                          accent: accent,
                          style: titleStyle,
                        ),
                        const SizedBox(height: 6),
                        Text(chapter.lookForward, style: bodyStyle),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CuriousLink(
                    question: chapter.curiousQuestion,
                    need: chapter.curiousNeed,
                    palette: palette,
                    accent: accent,
                    onTap: () =>
                        _openGuide(context, state, chapter.curiousNeed),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Picture, deckled at the bottom like torn paper, over the accent strip
/// that carries the title and weeks.
class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({
    required this.chapter,
    required this.palette,
    required this.state,
    required this.onAccent,
  });

  final Chapter chapter;
  final AppPalette palette;
  final AppState state;
  final Color onAccent;

  @override
  Widget build(BuildContext context) {
    final accent = chapter.accent;
    final short = MediaQuery.sizeOf(context).height < 560;
    final panel = _AccentPaperPanel(
      accent: accent,
      palette: palette,
      bumpy: BumpyAvatar(
        need: state.costumeOverride ?? state.todayNeed,
        palette: palette,
        happy: true,
        skinTone: state.skinTone,
      ),
    );
    return ColoredBox(
      color: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipPath(
            clipper: const _DeckledEdge(),
            child: ExcludeSemantics(
              child: SizedBox(
                height: short ? 132 : 184,
                child: Image.asset(
                  chapter.illustrationPath(halloween: palette.isHalloween),
                  key: ValueKey(
                    chapter.illustrationPath(halloween: palette.isHalloween),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    chapter.title,
                    style: TextStyle(
                      color: onAccent,
                      fontSize: 26,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // A small paper tag, readable on any accent colour.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: palette.paper,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            offset: Offset(0, 1.5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        child: Text(
                          'Weeks ${chapter.fromWeek} to ${chapter.toWeek}',
                          style: TextStyle(
                            color: palette.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (!chapter.isApproved) _DraftChip(palette: palette),
                  ],
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
      palette.isHalloween ? palette.skyTop : Colors.white,
      palette.isHalloween ? .55 : .45,
    )!;
    return ColoredBox(
      color: sky,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _PaperHillsPainter(accent: accent, moon: palette.moon),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 14),
            child: FittedBox(child: bumpy),
          ),
        ],
      ),
    );
  }
}

class _PaperHillsPainter extends CustomPainter {
  const _PaperHillsPainter({required this.accent, required this.moon});

  final Color accent;
  final Color moon;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shadow = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    void paper(Path path, Color color) {
      canvas.drawPath(path.shift(const Offset(0, 3)), shadow);
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
      old.accent != accent || old.moon != moon;
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

/// Private Draft tag. The integrator swaps it for the shared one.
class _DraftChip extends StatelessWidget {
  const _DraftChip({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Draft, waiting for review',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.ink,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Text(
            'Draft',
            style: TextStyle(
              color: palette.paper,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// A small cut-paper diamond in the chapter's colour before each heading.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.accent, required this.style});

  final String text;
  final Color accent;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), offset: Offset(0, 1.5)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Semantics(header: true, child: Text(text, style: style)),
        ),
      ],
    );
  }
}

class _PaperPanel extends StatelessWidget {
  const _PaperPanel({
    required this.color,
    required this.edge,
    required this.child,
  });

  final Color color;
  final Color edge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border(bottom: BorderSide(color: edge, width: 3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            offset: Offset(0, 2),
            blurRadius: 2,
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

/// Bumpy's line in a paper speech bubble.
class _BumpySays extends StatelessWidget {
  const _BumpySays({
    required this.line,
    required this.accent,
    required this.palette,
  });

  final String line;
  final Color accent;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Bumpy says',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.paperRaised,
          border: Border.all(color: accent, width: 2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Text(
            line,
            style: TextStyle(
              color: palette.ink,
              fontSize: 18,
              height: 1.45,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}

/// The existing weekly card for this exact week, inside the chapter.
class _ChapterWeekCard extends StatelessWidget {
  const _ChapterWeekCard({
    required this.week,
    required this.card,
    required this.palette,
    required this.accent,
    required this.isCurrentWeek,
    required this.onReturn,
  });

  final int week;
  final WeekCard? card;
  final AppPalette palette;
  final Color accent;
  final bool isCurrentWeek;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return _PaperPanel(
      color: palette.paperRaised,
      edge: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Week $week',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: palette.ink,
                  ),
                ),
              ),
              if (isCurrentWeek)
                Text(
                  'You are here',
                  style: TextStyle(
                    color: palette.inkSoft,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (card != null) ...[
            const SizedBox(height: 8),
            Text(
              card!.babyLine,
              style: TextStyle(fontSize: 18, height: 1.45, color: palette.ink),
            ),
          ],
          if (!isCurrentWeek) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: palette.ink,
                minimumSize: const Size(48, 48),
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

/// One tap puts the chapter's question on the visit list.
class _AddQuestion extends StatefulWidget {
  const _AddQuestion({
    required this.question,
    required this.state,
    required this.palette,
    required this.accent,
  });

  final String question;
  final AppState state;
  final AppPalette palette;
  final Color accent;

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
    final ok = await widget.state.addVisitQuestion(widget.question);
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
    final (fill, label) = _buttonColours(widget.accent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '“${widget.question}”',
          style: TextStyle(
            color: palette.ink,
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
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
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
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
                )
              : FilledButton.icon(
                  onPressed: _saving ? null : _add,
                  style: FilledButton.styleFrom(
                    backgroundColor: fill,
                    foregroundColor: label,
                    minimumSize: const Size(48, 48),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(Icons.playlist_add_rounded),
                  label: const Text('Add to my visit list'),
                ),
        ),
        if (_notSaved)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'That did not save. You can try again.',
              style: TextStyle(color: palette.inkSoft, fontSize: 16),
            ),
          ),
      ],
    );
  }
}

/// The curious question: a quiet link into the guide for its need.
class _CuriousLink extends StatelessWidget {
  const _CuriousLink({
    required this.question,
    required this.need,
    required this.palette,
    required this.accent,
    required this.onTap,
  });

  final String question;
  final MaternalNeed need;
  final AppPalette palette;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: palette.inkSoft,
        minimumSize: const Size(48, 48),
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded, size: 20, color: palette.inkSoft),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              question,
              semanticsLabel: '$question Opens the ${need.label} guide.',
              style: TextStyle(
                fontSize: 16,
                height: 1.35,
                color: palette.inkSoft,
                decoration: TextDecoration.underline,
                decorationColor: accent,
                decorationThickness: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
