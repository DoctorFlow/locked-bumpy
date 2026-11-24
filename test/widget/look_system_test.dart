import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/core/theme/app_text.dart';
import 'package:little_bumpy/core/theme/app_theme.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/core/theme/paper.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/presentation/widgets/app_nav_bar.dart';
import 'package:little_bumpy/presentation/widgets/bumpy_avatar.dart';
import 'package:little_bumpy/presentation/widgets/nursery_scene.dart';
import 'package:little_bumpy/presentation/widgets/paper_choice.dart';
import 'package:shared_preferences/shared_preferences.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return la >= lb ? (la + .05) / (lb + .05) : (lb + .05) / (la + .05);
}

String name(AppPalette p) => p.isHalloween ? 'Halloween' : 'Everyday';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(ContentLoader.loadWeekCards);
  const looks = [AppPalette.everyday, AppPalette.halloween];

  for (final p in looks) {
    test('${name(p)}: every text pair in the palette reads at 4.5:1', () {
      final text = <String, (Color, Color)>{
        'ink on paper': (p.ink, p.paper),
        'ink on raised paper': (p.ink, p.paperRaised),
        'soft ink on paper': (p.inkSoft, p.paper),
        'soft ink on raised paper': (p.inkSoft, p.paperRaised),
        'moonlight on the page top': (p.moonlight, p.skyTop),
        'moonlight on the page bottom': (p.moonlight, p.skyBottom),
        'soft moonlight on the page top': (p.moonlightSoft, p.skyTop),
        'soft moonlight on the page bottom': (p.moonlightSoft, p.skyBottom),
        'button label on accent': (p.accentText, p.accent),
        'accent on paper': (p.accent, p.paper),
        'accent on raised paper': (p.accent, p.paperRaised),
        'tab label on the tab bar': (p.tabBarText, p.tabBar),
        'selected tab on the tab bar': (p.accent, p.tabBar),
        'danger on paper': (p.danger, p.paper),
        'label on danger': (p.onDanger, p.danger),
        'erase action on the page': (AppPalette.eraseAccent, p.skyTop),
        'erase label': (AppPalette.eraseInk, AppPalette.eraseAccent),
      };
      for (final MapEntry(key: pair, value: (front, back)) in text.entries) {
        expect(contrast(front, back), greaterThanOrEqualTo(4.5), reason: pair);
      }
      // Control edges need 3:1 against whatever they sit on.
      for (final back in [p.paper, p.paperRaised, p.skyTop, p.skyBottom]) {
        expect(contrast(p.outline, back), greaterThanOrEqualTo(3));
      }
    });

    test('${name(p)}: the theme carries the type scale and 48 px targets', () {
      final theme = buildTheme(p);
      final slots = {
        'displayLarge': theme.textTheme.displayLarge,
        'displayMedium': theme.textTheme.displayMedium,
        'displaySmall': theme.textTheme.displaySmall,
        'headlineLarge': theme.textTheme.headlineLarge,
        'headlineMedium': theme.textTheme.headlineMedium,
        'headlineSmall': theme.textTheme.headlineSmall,
        'titleLarge': theme.textTheme.titleLarge,
        'titleMedium': theme.textTheme.titleMedium,
        'titleSmall': theme.textTheme.titleSmall,
        'bodyLarge': theme.textTheme.bodyLarge,
        'bodyMedium': theme.textTheme.bodyMedium,
        'bodySmall': theme.textTheme.bodySmall,
        'labelLarge': theme.textTheme.labelLarge,
        'labelMedium': theme.textTheme.labelMedium,
        'labelSmall': theme.textTheme.labelSmall,
      };
      for (final MapEntry(key: slot, value: style) in slots.entries) {
        expect(style!.fontSize, greaterThanOrEqualTo(13), reason: slot);
        expect(style.color, p.ink, reason: slot);
        expect([AppText.sans, AppText.serif], contains(style.fontFamily));
      }
      // Text with no style of its own is reading text.
      expect(theme.textTheme.bodyMedium!.fontSize, 16);
      expect(theme.textTheme.bodyLarge!.fontSize, 16);

      const target = Size.square(AppSpace.target);
      for (final style in [
        theme.filledButtonTheme.style!,
        theme.elevatedButtonTheme.style!,
        theme.outlinedButtonTheme.style!,
        theme.textButtonTheme.style!,
      ]) {
        expect(style.minimumSize!.resolve({}), target);
        expect(style.textStyle!.resolve({})!.fontSize, 16);
      }
      expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
      expect(theme.extension<AppPalette>(), p);
    });
  }

  test('the named styles keep to two families and a 13 px floor', () {
    expect(AppText.all, hasLength(10));
    for (final MapEntry(key: style, value: text) in AppText.all.entries) {
      expect(text.fontSize, greaterThanOrEqualTo(13), reason: style);
      expect(text.color, isNull, reason: '$style takes the palette colour');
      expect([AppText.sans, AppText.serif], contains(text.fontFamily));
      // Fraunces is a variable font: its file default is the heaviest cut.
      if (text.fontFamily == AppText.serif) {
        expect(
          text.fontVariations!.map((axis) => axis.axis),
          containsAll(['opsz', 'wght', 'SOFT', 'WONK']),
          reason: style,
        );
      }
    }
    expect(AppText.body.fontSize, 16);
    expect(AppText.button.fontSize, 16);
  });

  for (final p in looks) {
    testWidgets('${name(p)}: tab labels grow with the text size, on one line, at 320 px', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final semantics = tester.ensureSemantics();
      SharedPreferences.setMockInitialValues({'due_date_iso': '2027-04-10'});
      final state = await AppState.load();

      Future<void> pump(double scale) => tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(p),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            bottomNavigationBar: ListenableBuilder(
              listenable: state,
              builder: (_, _) => AppNavBar(state: state),
            ),
          ),
        ),
      );

      await pump(1);
      final plain = tester.getSize(find.text('Today')).height;
      for (final label in ['Today', 'This Week', 'Guides']) {
        final tab = find.ancestor(
          of: find.text(label),
          matching: find.byType(InkWell),
        );
        expect(tester.getSize(tab).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(tab).width, greaterThanOrEqualTo(48));
      }
      // Selected: a filled icon on an accent marker, a bold accent label,
      // and the selected state for a screen reader.
      expect(find.byIcon(Icons.today), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Today')).style!.fontWeight,
        FontWeight.w700,
      );
      expect(
        tester.widget<Text>(find.text('Guides')).style!.fontWeight,
        FontWeight.w400,
      );
      expect(
        tester.getSemantics(find.text('Today')),
        isSemantics(isSelected: true, hasTapAction: true),
      );
      expect(find.bySemanticsLabel(RegExp('Today\\s+Tab 1 of 3')), findsOne);

      await tester.tap(find.text('Guides'));
      await tester.pumpAndSettle();
      expect(state.currentTab, 2);
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Guides')),
        isSemantics(isSelected: true),
      );

      // At 200% the labels grow to 1.3x and stay on one line, inside the tab.
      await pump(2);
      await tester.pumpAndSettle();
      for (final label in ['Today', 'This Week', 'Guides']) {
        final grown = tester.getSize(find.text(label)).height;
        expect(grown, greaterThan(plain * 1.2), reason: label);
        expect(grown, lessThan(plain * 1.5), reason: label);
        final tab = tester.getRect(
          find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
        );
        final drawn = tester.getRect(find.text(label));
        expect(drawn.left, greaterThanOrEqualTo(tab.left), reason: label);
        expect(drawn.right, lessThanOrEqualTo(tab.right), reason: label);
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('the lamp is named by the words it shows', (tester) async {
    SharedPreferences.setMockInitialValues({
      'due_date_iso': '2027-04-10',
      'is_halloween': false,
    });
    final state = await AppState.load();
    await tester.pumpWidget(LittleBumpyApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('Switch look'), findsOneWidget);
    expect(find.bySemanticsLabel('Switch look to Halloween'), findsOneWidget);
    await tester.tap(find.byTooltip('Switch to Halloween'));
    await tester.pumpAndSettle();
    expect(state.isHalloween, isTrue);
    expect(find.bySemanticsLabel('Switch look to Everyday'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a small paper choice still gets a 48 px target', (tester) async {
    Widget choice(Size child) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: PaperChoice(
            label: 'Choice',
            onTap: () {},
            focusColor: AppPalette.everyday.accent,
            borderRadius: AppRadii.control,
            child: SizedBox.fromSize(size: child),
          ),
        ),
      ),
    );
    await tester.pumpWidget(choice(const Size(72, 40)));
    expect(tester.getSize(find.byType(PaperChoice)), const Size(72, 48));
    await tester.pumpWidget(choice(const Size(120, 64)));
    expect(tester.getSize(find.byType(PaperChoice)), const Size(120, 64));
  });

  for (final p in looks) {
    testWidgets('${name(p)}: Bumpy has a hill and a shadow at every size', (
      tester,
    ) async {
      for (final height in [204.0, 192.0, 156.0, 150.0, 112.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 288,
                child: NurseryScene(
                  palette: p,
                  height: height,
                  avatar: BumpyAvatar(
                    need: MaternalNeed.iron,
                    palette: p,
                    happy: false,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final ground = find.descendant(
          of: find.byType(NurseryScene),
          matching: find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter != null,
          ),
        );
        expect(
          tester.renderObject(ground),
          paints
            ..path(color: p.hill.withValues(alpha: .45))
            ..path(color: p.hill)
            ..circle(),
          reason: 'room $height',
        );
        // Bumpy stands at the bottom of the room, feet on the hill.
        expect(
          tester.getBottomLeft(find.byType(BumpyAvatar)).dy,
          tester.getBottomLeft(find.byType(NurseryScene)).dy,
        );
        expect(tester.takeException(), isNull);
      }
    });
  }
}
