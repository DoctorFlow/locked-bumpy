import 'package:flutter/material.dart';
import '../../content/urgent_loader.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/paper.dart';
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
    return PageOnTable(
      title: rowLabel,
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // One frame: the block's own 2 px ink-edged paper is the card,
          // so it gets the full page width like every other page.
          UrgentSignsBlock(
            urgent: list,
            palette: palette,
            week: state.currentWeek,
          ),
          if (list != null) ...[
            const SizedBox(height: AppSpace.xl),
            SourcesNote(
              palette: palette,
              sources: [for (final s in list.sources) '${s.org}: ${s.title}'],
              lastChecked: list.lastChecked,
            ),
          ],
        ],
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

/// The shared urgent list in full: title, intro, the signs (under their
/// group titles when the file groups them), then the action and the footer.
/// Never collapsed, never in Bumpy's voice. When [urgent] is null (hidden by
/// the gate) it shows [UrgentSigns.fallback] instead.
///
/// Calm but serious: an ink-edged piece of raised paper, plain ink text, no
/// alarm colour. Every sign is its own line with room around it; the action
/// sentence sits on its own paper strip and is the strongest line. [compact]
/// (card 5 of a guide) tightens the spacing only; nothing is hidden.
class UrgentSignsBlock extends StatelessWidget {
  const UrgentSignsBlock({
    super.key,
    required this.urgent,
    required this.palette,
    this.compact = false,
    this.week,
  });

  final UrgentSigns? urgent;
  final AppPalette palette;
  final bool compact;

  /// The parent's current week, or null when unknown. A sign whose
  /// `from_week` is later moves to the end (Amendment 4); nothing is hidden,
  /// and with no week the order is the file's.
  final int? week;

  @override
  Widget build(BuildContext context) {
    final list = urgent;
    final body = AppText.body.copyWith(color: palette.ink);
    final strong = AppText.bodyStrong.copyWith(
      color: palette.ink,
      height: 24 / 16,
    );
    final signGap = compact ? AppSpace.xs : AppSpace.m;
    Widget sign(int i, String text) => Padding(
      key: ValueKey('urgent-sign-$i'),
      padding: EdgeInsets.only(bottom: signGap),
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
          Expanded(child: Text(text, style: body)),
        ],
      ),
    );

    return DecoratedBox(
      key: ValueKey(list == null ? 'urgent-fallback' : 'urgent-signs'),
      decoration: BoxDecoration(
        color: palette.paperRaised,
        borderRadius: AppRadii.control,
        border: Border.all(color: palette.ink, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.l),
        child: list == null
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: 2,
                        end: AppSpace.m,
                      ),
                      child: Icon(
                        Icons.health_and_safety_outlined,
                        color: palette.ink,
                        size: 24,
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
                    spacing: AppSpace.s,
                    runSpacing: AppSpace.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          Icons.health_and_safety_outlined,
                          color: palette.ink,
                          size: 24,
                        ),
                      ),
                      Semantics(
                        header: true,
                        child: Text(
                          list.title,
                          style: AppText.heading.copyWith(color: palette.ink),
                        ),
                      ),
                      if (list.isDraft) DraftTag(palette: palette),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s),
                  Text(list.intro, style: strong),
                  SizedBox(height: compact ? AppSpace.m : AppSpace.l),
                  if (list.groups.isEmpty)
                    for (final (i, s) in list.signsFor(week).indexed) sign(i, s)
                  else
                    ..._grouped(list, sign),
                  SizedBox(height: compact ? AppSpace.s : AppSpace.m),
                  _ActionStrip(text: list.action, palette: palette),
                  if (list.footer != null) ...[
                    const SizedBox(height: AppSpace.l),
                    Text(list.footer!, style: body),
                  ],
                ],
              ),
      ),
    );
  }

  List<Widget> _grouped(
    UrgentSigns list,
    Widget Function(int i, String text) sign,
  ) {
    var i = 0;
    final gap = compact ? AppSpace.s : AppSpace.m;
    return [
      for (final (g, group) in list.groupsFor(week).indexed) ...[
        if (g > 0) SizedBox(height: gap),
        // The last quiet group (signs that belong later than the parent's
        // week): set apart by a hairline and a softer title. The signs
        // themselves read exactly as the others do.
        if (group.later) ...[
          Divider(height: 1, thickness: 1, color: palette.rule),
          SizedBox(height: gap),
        ],
        Padding(
          key: group.later ? const ValueKey('urgent-later-group') : null,
          padding: const EdgeInsets.only(bottom: AppSpace.s),
          child: Wrap(
            spacing: AppSpace.s,
            runSpacing: AppSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                header: true,
                child: Text(
                  group.title,
                  style: group.later
                      ? AppText.body.copyWith(color: palette.inkSoft)
                      : AppText.bodyStrong.copyWith(color: palette.ink),
                ),
              ),
              if (group.later && group.isDraft && !list.isDraft)
                DraftTag(palette: palette),
            ],
          ),
        ),
        for (final s in group.signs) sign(i++, s),
      ],
    ];
  }
}

/// The action sentence on its own paper strip with a phone icon: the
/// strongest line of the list, in ink, never an alarm colour.
class _ActionStrip extends StatelessWidget {
  const _ActionStrip({required this.text, required this.palette});
  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey('urgent-action'),
    decoration: BoxDecoration(
      color: palette.paper,
      borderRadius: AppRadii.control,
      border: Border.all(color: palette.ink, width: 2),
      boxShadow: paperShadows(palette, raised: true),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpace.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpace.m),
              child: Icon(Icons.call, color: palette.ink, size: 24),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppText.heading.copyWith(color: palette.ink),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The quiet link to this page, set on the page (not on a card): a text
/// button (underlined, 48 px) in moonlight, which reads on the page in both
/// looks. Today has it beside its safety line; every chapter page ends with
/// it. One widget, so the words and look are the same in both places.
class UrgentLink extends StatelessWidget {
  const UrgentLink({super.key, required this.state, required this.palette});

  final AppState state;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        style: TextButton.styleFrom(foregroundColor: palette.moonlight),
        onPressed: () => UrgentScreen.open(context, state),
        child: const Text(UrgentScreen.rowLabel, textAlign: TextAlign.center),
      ),
    );
  }
}
