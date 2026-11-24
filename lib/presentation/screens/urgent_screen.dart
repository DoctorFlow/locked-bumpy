import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../content/urgent_loader.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/urgent_signs.dart';
import '../widgets/draft_tag.dart';
import 'guide_screen.dart';

/// The shared urgent list as a full page, opened from the Guides tab row
/// "When to get help right away". It sits on the app's route stack, so
/// Pause and Erase (which rebuild the whole app) close it at once.
class UrgentScreen extends StatelessWidget {
  const UrgentScreen({
    super.key,
    required this.state,
    required this.urgent,
    this.fromBundle = false,
  });

  final AppState state;

  /// Null when the gate hides the list: the page shows the fallback.
  final UrgentSigns? urgent;

  /// True: ignore [urgent] and show the bundled list ([open] sets this).
  final bool fromBundle;

  /// The Guides tab row label and this page's title.
  static const rowLabel = 'When to get help right away';

  /// Opens the page. The one entry point other screens call.
  static Future<void> open(BuildContext context, AppState state) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              UrgentScreen(state: state, urgent: null, fromBundle: true),
        ),
      );

  @override
  Widget build(BuildContext context) => withUrgentSigns(
    fromBundle: fromBundle,
    given: urgent,
    builder: (list) => _page(context, list),
  );

  Widget _page(BuildContext context, UrgentSigns? list) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: palette.skyBottom,
      appBar: AppBar(
        backgroundColor: palette.skyTop,
        foregroundColor: palette.moonlight,
        surfaceTintColor: Colors.transparent,
        title: const Text(rowLabel),
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
              return ListView(
                padding: EdgeInsets.fromLTRB(side, 16, side, 24),
                children: [
                  Material(
                    color: palette.paper,
                    borderRadius: BorderRadius.circular(20),
                    elevation: 1,
                    shadowColor: palette.skyBottom,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: UrgentSignsBlock(urgent: list, palette: palette),
                    ),
                  ),
                  if (list != null) ...[
                    const SizedBox(height: 22),
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
                    for (final source in list.sources)
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
                      'Last checked '
                      '${GuideScreen.readableDate(list.lastChecked)}',
                      style: TextStyle(color: palette.moonlight, fontSize: 16),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Builds with the shared list: [given] when [fromBundle] is false, else the
/// bundled list once it has loaded (null, so the fallback, until then and
/// whenever the gate hides it). Opening a page never waits on the file.
Widget withUrgentSigns({
  required bool fromBundle,
  required UrgentSigns? given,
  required Widget Function(UrgentSigns? urgent) builder,
}) => fromBundle
    ? FutureBuilder<UrgentSigns?>(
        future: UrgentLoader.load(),
        builder: (context, snapshot) => builder(snapshot.data),
      )
    : builder(given);

/// The shared urgent list in full: title, intro, every sign on its own line,
/// then the action. Never collapsed, never in Bumpy's voice. When [urgent]
/// is null (hidden by the gate) it shows [UrgentSigns.fallback] instead.
///
/// Calm but serious: an ink-edged panel on raised paper, plain ink text,
/// no alarm colour. Readable in both looks (ink on paper is >= 4.5:1).
class UrgentSignsBlock extends StatelessWidget {
  const UrgentSignsBlock({
    super.key,
    required this.urgent,
    required this.palette,
  });

  final UrgentSigns? urgent;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final list = urgent;
    final body = TextStyle(color: palette.ink, fontSize: 16, height: 1.45);
    final strong = body.copyWith(fontWeight: FontWeight.w700);
    return Container(
      key: ValueKey(list == null ? 'urgent-fallback' : 'urgent-signs'),
      decoration: BoxDecoration(
        color: palette.paperRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.ink, width: 2),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: list == null
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(top: 2, end: 10),
                    child: Icon(
                      Icons.health_and_safety_outlined,
                      color: palette.ink,
                      size: 22,
                    ),
                  ),
                ),
                Expanded(child: Text(UrgentSigns.fallback, style: strong)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        Icons.health_and_safety_outlined,
                        color: palette.ink,
                        size: 22,
                      ),
                    ),
                    Semantics(
                      header: true,
                      child: Text(
                        list.title,
                        style: TextStyle(
                          color: palette.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (list.isDraft) DraftTag(palette: palette),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  list.intro,
                  style: body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                for (final (i, sign) in list.signs.indexed)
                  Padding(
                    key: ValueKey('urgent-sign-$i'),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              top: 8,
                              end: 10,
                            ),
                            child: SizedBox.square(
                              dimension: 8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: palette.ink,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(child: Text(sign, style: body)),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(list.action, style: strong),
              ],
            ),
    );
  }
}
