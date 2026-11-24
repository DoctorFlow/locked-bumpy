import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/core/theme/app_theme.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/presentation/sheets/closet_sheet.dart';
import 'package:little_bumpy/presentation/widgets/app_nav_bar.dart';
import 'package:little_bumpy/presentation/widgets/draft_tag.dart';
import 'package:little_bumpy/presentation/widgets/visit_topics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's frame at 200 percent text on a 320 px phone (design critique 4,
/// fix 1): the review banner, the tab labels and "Choose week" stay on one
/// line and inside the screen, the targets stay 48 px, and the page itself
/// still follows the full text size.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ContentLoader.load('assets/content/today_lines.json');
    await ContentLoader.loadWeekCards();
    // The real faces, so word widths match a phone (the test font draws
    // every letter as a 1 em square).
    Future<void> face(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }

    await face('Fraunces', ['Fraunces.ttf']);
    await face('Atkinson Hyperlegible', [
      'AtkinsonHyperlegible-Regular.ttf',
      'AtkinsonHyperlegible-Bold.ttf',
    ]);
  });

  const size = Size(320, 568);
  const tabs = ['Today', 'This Week', 'Guides'];

  void phone(WidgetTester t) {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = size;
    t.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<AppState> boot(bool halloween) async {
    SharedPreferences.setMockInitialValues({
      'due_date_iso': '2027-05-10',
      'is_halloween': halloween,
    });
    return AppState.load(now: () => DateTime(2026, 11, 23));
  }

  /// The number of lines [text] is drawn on.
  int lines(WidgetTester t, String text) {
    final paragraph = t.renderObject<RenderParagraph>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    );
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: text.length),
    );
    return boxes.map((b) => b.top.round()).toSet().length;
  }

  /// [text] is on one line and drawn inside [within] (the screen by default).
  void expectOneLineInside(WidgetTester t, String text, {Rect? within}) {
    expect(lines(t, text), 1, reason: '"$text" wraps');
    final box = within ?? Offset.zero & size;
    final drawn = t.getRect(find.text(text));
    expect(drawn.left, greaterThanOrEqualTo(box.left - .5), reason: text);
    expect(drawn.right, lessThanOrEqualTo(box.right + .5), reason: text);
  }

  void expectTabs(WidgetTester t) {
    for (final label in tabs) {
      final tab = find.ancestor(
        of: find.text(label),
        matching: find.byType(InkWell),
      );
      final rect = t.getRect(tab);
      expect(rect.height, greaterThanOrEqualTo(48), reason: label);
      expect(rect.width, greaterThanOrEqualTo(48), reason: label);
      expectOneLineInside(t, label, within: rect);
    }
    // Every icon is still there.
    final icons = find.descendant(
      of: find.byType(AppNavBar),
      matching: find.byType(Icon),
    );
    expect(icons, findsNWidgets(3));
    for (final icon in t.widgetList<Icon>(icons)) {
      expect(icon.size, 24);
    }
  }

  for (final halloween in [false, true]) {
    final look = halloween ? 'Halloween' : 'Everyday';

    testWidgets('$look: tabs and "Choose week" hold one line at 320 px and '
        '200% text, and the page keeps the full text size', (t) async {
      phone(t);
      final state = await boot(halloween);
      await t.pumpWidget(LittleBumpyApp(state: state));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expectTabs(t);
      // The tab labels stop at 1.3x; the page above them does not.
      final label = t.element(find.text('Guides'));
      expect(MediaQuery.textScalerOf(label).scale(10), 13);
      final page = t.element(find.byType(AppNavBar));
      expect(MediaQuery.textScalerOf(page).scale(10), 20);

      await t.tap(find.text('This Week'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expectTabs(t);
      final choose = find.text('Choose week');
      await t.ensureVisible(choose);
      await t.pumpAndSettle();
      expectOneLineInside(t, 'Choose week');
      final button = find.ancestor(
        of: choose,
        matching: find.byWidgetPredicate((w) => w is TextButton),
      );
      expect(t.getSize(button).height, greaterThanOrEqualTo(48));
      // "Choose week" still follows the full text size; it only shrinks to
      // fit between the arrows.
      expect(MediaQuery.textScalerOf(t.element(choose)).scale(10), 20);
      expect(find.bySemanticsLabel('Previous week'), findsOneWidget);
      expect(find.bySemanticsLabel('Next week'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('$look: the review banner is one line at 320 px and 200% '
        'text, and tall sheets keep 8 px under it', (t) async {
      phone(t);
      final state = await boot(halloween);
      final palette = halloween ? AppPalette.halloween : AppPalette.everyday;
      await t.pumpWidget(
        MaterialApp(
          theme: buildTheme(palette),
          builder: (context, child) => ReviewBanner(child: child),
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () => ClosetSheet.open(context, state),
                    child: const Text('closet'),
                  ),
                  TextButton(
                    onPressed: () => VisitTopics.edit(context, state),
                    child: const Text('visit'),
                  ),
                ],
              ),
              bottomNavigationBar: AppNavBar(state: state),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expectOneLineInside(t, ReviewBanner.message);
      final banner = t.getRect(
        find
            .ancestor(
              of: find.text(ReviewBanner.message),
              matching: find.byType(Material),
            )
            .first,
      );
      // A thin strip, not a two-line block.
      expect(banner.height, lessThanOrEqualTo(40));
      expectTabs(t);

      for (final open in ['closet', 'visit']) {
        await t.tap(find.text(open));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: open);
        final sheet = t.getRect(find.byType(BottomSheet));
        expect(
          sheet.top - banner.bottom,
          greaterThanOrEqualTo(8),
          reason: '$open sheet touches the banner',
        );
        Navigator.of(t.element(find.byType(BottomSheet))).pop();
        await t.pumpAndSettle();
      }
      await t.pumpWidget(const SizedBox());
    });
  }
}
