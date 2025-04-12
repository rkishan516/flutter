// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class TestIcon extends StatefulWidget {
  const TestIcon({super.key});

  @override
  TestIconState createState() => TestIconState();
}

class TestIconState extends State<TestIcon> {
  late IconThemeData iconTheme;

  @override
  Widget build(BuildContext context) {
    iconTheme = IconTheme.of(context);
    return const Icon(Icons.add);
  }
}

class TestText extends StatefulWidget {
  const TestText(this.text, {super.key});

  final String text;

  @override
  TestTextState createState() => TestTextState();
}

class TestTextState extends State<TestText> {
  late TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    textStyle = DefaultTextStyle.of(context).style;
    return Text(widget.text);
  }
}

// Helper function to get RenderParagraph for text.
RenderParagraph _getTextRenderObject(WidgetTester tester, String text) {
  return tester.element<StatelessElement>(find.text(text)).renderObject! as RenderParagraph;
}

void main() {
  test('ListTileThemeData copyWith, ==, hashCode, basics', () {
    expect(const ListTileThemeData(), const ListTileThemeData().copyWith());
    expect(const ListTileThemeData().hashCode, const ListTileThemeData().copyWith().hashCode);
  });

  test('ListTileThemeData lerp special cases', () {
    expect(ListTileThemeData.lerp(null, null, 0), null);
    const ListTileThemeData data = ListTileThemeData();
    expect(identical(ListTileThemeData.lerp(data, data, 0.5), data), true);
  });

  test('ListTileThemeData defaults', () {
    const ListTileThemeData themeData = ListTileThemeData();
    expect(themeData.dense, null);
    expect(themeData.shape, null);
    expect(themeData.style, null);
    expect(themeData.selectedColor, null);
    expect(themeData.iconColor, null);
    expect(themeData.textColor, null);
    expect(themeData.titleTextStyle, null);
    expect(themeData.subtitleTextStyle, null);
    expect(themeData.leadingAndTrailingTextStyle, null);
    expect(themeData.contentPadding, null);
    expect(themeData.tileColor, null);
    expect(themeData.selectedTileColor, null);
    expect(themeData.horizontalTitleGap, null);
    expect(themeData.minVerticalPadding, null);
    expect(themeData.minLeadingWidth, null);
    expect(themeData.minTileHeight, null);
    expect(themeData.enableFeedback, null);
    expect(themeData.mouseCursor, null);
    expect(themeData.visualDensity, null);
    expect(themeData.titleAlignment, null);
    expect(themeData.isThreeLine, null);
  });

  testWidgets('Default ListTileThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const ListTileThemeData().debugFillProperties(builder);

    final List<String> description =
        builder.properties
            .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
            .map((DiagnosticsNode node) => node.toString())
            .toList();

    expect(description, <String>[]);
  });

  testWidgets('ListTileThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const ListTileThemeData(
      dense: true,
      shape: StadiumBorder(),
      style: ListTileStyle.drawer,
      selectedColor: Color(0x00000001),
      iconColor: Color(0x00000002),
      textColor: Color(0x00000003),
      titleTextStyle: TextStyle(color: Color(0x00000004)),
      subtitleTextStyle: TextStyle(color: Color(0x00000005)),
      leadingAndTrailingTextStyle: TextStyle(color: Color(0x00000006)),
      contentPadding: EdgeInsets.all(100),
      tileColor: Color(0x00000007),
      selectedTileColor: Color(0x00000008),
      horizontalTitleGap: 200,
      minVerticalPadding: 300,
      minLeadingWidth: 400,
      minTileHeight: 30,
      enableFeedback: true,
      mouseCursor: MaterialStateMouseCursor.clickable,
      visualDensity: VisualDensity.comfortable,
      titleAlignment: ListTileTitleAlignment.top,
      isThreeLine: true,
    ).debugFillProperties(builder);

    final List<String> description =
        builder.properties
            .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
            .map((DiagnosticsNode node) => node.toString())
            .toList();

    expect(
      description,
      equalsIgnoringHashCodes(<String>[
        'dense: true',
        'shape: StadiumBorder(BorderSide(width: 0.0, style: none))',
        'style: drawer',
        'selectedColor: ${const Color(0x00000001)}',
        'iconColor: ${const Color(0x00000002)}',
        'textColor: ${const Color(0x00000003)}',
        'titleTextStyle: TextStyle(inherit: true, color: ${const Color(0x00000004)})',
        'subtitleTextStyle: TextStyle(inherit: true, color: ${const Color(0x00000005)})',
        'leadingAndTrailingTextStyle: TextStyle(inherit: true, color: ${const Color(0x00000006)})',
        'contentPadding: EdgeInsets.all(100.0)',
        'tileColor: ${const Color(0x00000007)}',
        'selectedTileColor: ${const Color(0x00000008)}',
        'horizontalTitleGap: 200.0',
        'minVerticalPadding: 300.0',
        'minLeadingWidth: 400.0',
        'minTileHeight: 30.0',
        'enableFeedback: true',
        'mouseCursor: WidgetStateMouseCursor(clickable)',
        'visualDensity: VisualDensity#00000(h: -1.0, v: -1.0)(horizontal: -1.0, vertical: -1.0)',
        'titleAlignment: ListTileTitleAlignment.top',
        'isThreeLine: true',
      ]),
    );
  });

  testWidgets('ListTileTheme backwards compatibility constructor', (WidgetTester tester) async {
    late ListTileThemeData theme;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListTileTheme(
            dense: true,
            shape: const StadiumBorder(),
            style: ListTileStyle.drawer,
            selectedColor: const Color(0x00000001),
            iconColor: const Color(0x00000002),
            textColor: const Color(0x00000003),
            contentPadding: const EdgeInsets.all(100),
            tileColor: const Color(0x00000004),
            selectedTileColor: const Color(0x00000005),
            horizontalTitleGap: 200,
            minVerticalPadding: 300,
            minLeadingWidth: 400,
            enableFeedback: true,
            mouseCursor: MaterialStateMouseCursor.clickable,
            child: Center(
              child: Builder(
                builder: (BuildContext context) {
                  theme = ListTileTheme.of(context);
                  return const Placeholder();
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(theme.dense, true);
    expect(theme.shape, const StadiumBorder());
    expect(theme.style, ListTileStyle.drawer);
    expect(theme.selectedColor, const Color(0x00000001));
    expect(theme.iconColor, const Color(0x00000002));
    expect(theme.textColor, const Color(0x00000003));
    expect(theme.contentPadding, const EdgeInsets.all(100));
    expect(theme.tileColor, const Color(0x00000004));
    expect(theme.selectedTileColor, const Color(0x00000005));
    expect(theme.horizontalTitleGap, 200);
    expect(theme.minVerticalPadding, 300);
    expect(theme.minLeadingWidth, 400);
    expect(theme.enableFeedback, true);
    expect(theme.mouseCursor, MaterialStateMouseCursor.clickable);
  });

  testWidgets('ListTileTheme', (WidgetTester tester) async {
    final Key listTileKey = UniqueKey();
    final Key titleKey = UniqueKey();
    final Key subtitleKey = UniqueKey();
    final Key leadingKey = UniqueKey();
    final Key trailingKey = UniqueKey();
    late ThemeData theme;

    Widget buildFrame({
      bool enabled = true,
      bool dense = false,
      bool selected = false,
      ShapeBorder? shape,
      Color? selectedColor,
      Color? iconColor,
      Color? textColor,
    }) {
      return MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Material(
          child: Center(
            child: ListTileTheme(
              data: ListTileThemeData(
                dense: dense,
                shape: shape,
                selectedColor: selectedColor,
                iconColor: iconColor,
                textColor: textColor,
                minVerticalPadding: 25.0,
                mouseCursor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
                  if (states.contains(MaterialState.disabled)) {
                    return SystemMouseCursors.forbidden;
                  }

                  return SystemMouseCursors.click;
                }),
                visualDensity: VisualDensity.compact,
                titleAlignment: ListTileTitleAlignment.bottom,
              ),
              child: Builder(
                builder: (BuildContext context) {
                  theme = Theme.of(context);
                  return ListTile(
                    key: listTileKey,
                    enabled: enabled,
                    selected: selected,
                    leading: TestIcon(key: leadingKey),
                    trailing: TestIcon(key: trailingKey),
                    title: TestText('title', key: titleKey),
                    subtitle: TestText('subtitle', key: subtitleKey),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    const Color green = Color(0xFF00FF00);
    const Color red = Color(0xFFFF0000);
    const ShapeBorder roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
    );

    Color iconColor(Key key) => tester.state<TestIconState>(find.byKey(key)).iconTheme.color!;
    Color textColor(Key key) => tester.state<TestTextState>(find.byKey(key)).textStyle.color!;
    ShapeBorder inkWellBorder() =>
        tester
            .widget<InkWell>(
              find.descendant(of: find.byType(ListTile), matching: find.byType(InkWell)),
            )
            .customBorder!;

    // A selected ListTile's leading, trailing, and text get the primary color by default
    await tester.pumpWidget(buildFrame(selected: true));
    await tester.pump(const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), theme.primaryColor);
    expect(iconColor(trailingKey), theme.primaryColor);
    expect(textColor(titleKey), theme.primaryColor);
    expect(textColor(subtitleKey), theme.primaryColor);

    // A selected ListTile's leading, trailing, and text get the ListTileTheme's selectedColor
    await tester.pumpWidget(buildFrame(selected: true, selectedColor: green));
    await tester.pump(const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), green);
    expect(iconColor(trailingKey), green);
    expect(textColor(titleKey), green);
    expect(textColor(subtitleKey), green);

    // An unselected ListTile's leading and trailing get the ListTileTheme's iconColor
    // An unselected ListTile's title texts get the ListTileTheme's textColor
    await tester.pumpWidget(buildFrame(iconColor: red, textColor: green));
    await tester.pump(const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), red);
    expect(iconColor(trailingKey), red);
    expect(textColor(titleKey), green);
    expect(textColor(subtitleKey), green);

    // If the item is disabled it's rendered with the theme's disabled color.
    await tester.pumpWidget(buildFrame(enabled: false));
    await tester.pump(const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), theme.disabledColor);
    expect(iconColor(trailingKey), theme.disabledColor);
    expect(textColor(titleKey), theme.disabledColor);
    expect(textColor(subtitleKey), theme.disabledColor);

    // If the item is disabled it's rendered with the theme's disabled color.
    // Even if it's selected.
    await tester.pumpWidget(buildFrame(enabled: false, selected: true));
    await tester.pump(const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), theme.disabledColor);
    expect(iconColor(trailingKey), theme.disabledColor);
    expect(textColor(titleKey), theme.disabledColor);
    expect(textColor(subtitleKey), theme.disabledColor);

    // A selected ListTile's InkWell gets the ListTileTheme's shape
    await tester.pumpWidget(buildFrame(selected: true, shape: roundedShape));
    expect(inkWellBorder(), roundedShape);

    // Cursor updates when hovering disabled ListTile
    await tester.pumpWidget(buildFrame(enabled: false));
    final Offset listTile = tester.getCenter(find.byKey(titleKey));
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(listTile);
    await tester.pumpAndSettle();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.forbidden,
    );

    // VisualDensity is respected
    final RenderBox box = tester.renderObject(find.byKey(listTileKey));
    expect(box.size, equals(const Size(800, 80.0)));

    // titleAlignment is respected.
    final Offset titleOffset = tester.getTopLeft(find.text('title'));
    final Offset leadingOffset = tester.getTopLeft(find.byKey(leadingKey));
    final Offset trailingOffset = tester.getTopRight(find.byKey(trailingKey));
    expect(leadingOffset.dy - titleOffset.dy, 6);
    expect(trailingOffset.dy - titleOffset.dy, 6);
  });

  testWidgets('ListTileTheme colors are applied to leading and trailing text widgets', (
    WidgetTester tester,
  ) async {
    final Key leadingKey = UniqueKey();
    final Key trailingKey = UniqueKey();

    const Color selectedColor = Colors.orange;
    const Color defaultColor = Colors.black;

    late ThemeData theme;
    Widget buildFrame({bool enabled = true, bool selected = false}) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: ListTileTheme(
              data: const ListTileThemeData(selectedColor: selectedColor, textColor: defaultColor),
              child: Builder(
                builder: (BuildContext context) {
                  theme = Theme.of(context);
                  return ListTile(
                    enabled: enabled,
                    selected: selected,
                    leading: TestText('leading', key: leadingKey),
                    title: const TestText('title'),
                    trailing: TestText('trailing', key: trailingKey),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    Color textColor(Key key) => tester.state<TestTextState>(find.byKey(key)).textStyle.color!;

    await tester.pumpWidget(buildFrame());
    // Enabled color should use ListTileTheme.textColor.
    expect(textColor(leadingKey), defaultColor);
    expect(textColor(trailingKey), defaultColor);

    await tester.pumpWidget(buildFrame(selected: true));
    // Wait for text color to animate.
    await tester.pumpAndSettle();
    // Selected color should use ListTileTheme.selectedColor.
    expect(textColor(leadingKey), selectedColor);
    expect(textColor(trailingKey), selectedColor);

    await tester.pumpWidget(buildFrame(enabled: false));
    // Wait for text color to animate.
    await tester.pumpAndSettle();
    // Disabled color should be ThemeData.disabledColor.
    expect(textColor(leadingKey), theme.disabledColor);
    expect(textColor(trailingKey), theme.disabledColor);
  });

  testWidgets(
    "Material3 - ListTile respects ListTileTheme's titleTextStyle, subtitleTextStyle & leadingAndTrailingTextStyle",
    (WidgetTester tester) async {
      const TextStyle titleTextStyle = TextStyle(
        fontSize: 23.0,
        color: Color(0xffff0000),
        fontStyle: FontStyle.italic,
      );
      const TextStyle subtitleTextStyle = TextStyle(
        fontSize: 20.0,
        color: Color(0xff00ff00),
        fontStyle: FontStyle.italic,
      );
      const TextStyle leadingAndTrailingTextStyle = TextStyle(
        fontSize: 18.0,
        color: Color(0xff0000ff),
        fontStyle: FontStyle.italic,
      );

      final ThemeData theme = ThemeData(
        listTileTheme: const ListTileThemeData(
          titleTextStyle: titleTextStyle,
          subtitleTextStyle: subtitleTextStyle,
          leadingAndTrailingTextStyle: leadingAndTrailingTextStyle,
        ),
      );

      Widget buildFrame() {
        return MaterialApp(
          theme: theme,
          home: Material(
            child: Center(
              child: Builder(
                builder: (BuildContext context) {
                  return const ListTile(
                    leading: TestText('leading'),
                    title: TestText('title'),
                    subtitle: TestText('subtitle'),
                    trailing: TestText('trailing'),
                  );
                },
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildFrame());
      final RenderParagraph leading = _getTextRenderObject(tester, 'leading');
      expect(leading.text.style!.fontSize, leadingAndTrailingTextStyle.fontSize);
      expect(leading.text.style!.color, leadingAndTrailingTextStyle.color);
      expect(leading.text.style!.fontStyle, leadingAndTrailingTextStyle.fontStyle);
      final RenderParagraph title = _getTextRenderObject(tester, 'title');
      expect(title.text.style!.fontSize, titleTextStyle.fontSize);
      expect(title.text.style!.color, titleTextStyle.color);
      expect(title.text.style!.fontStyle, titleTextStyle.fontStyle);
      final RenderParagraph subtitle = _getTextRenderObject(tester, 'subtitle');
      expect(subtitle.text.style!.fontSize, subtitleTextStyle.fontSize);
      expect(subtitle.text.style!.color, subtitleTextStyle.color);
      expect(subtitle.text.style!.fontStyle, subtitleTextStyle.fontStyle);
      final RenderParagraph trailing = _getTextRenderObject(tester, 'trailing');
      expect(trailing.text.style!.fontSize, leadingAndTrailingTextStyle.fontSize);
      expect(trailing.text.style!.color, leadingAndTrailingTextStyle.color);
      expect(trailing.text.style!.fontStyle, leadingAndTrailingTextStyle.fontStyle);
    },
  );

  testWidgets(
    "Material2 - ListTile respects ListTileTheme's titleTextStyle, subtitleTextStyle & leadingAndTrailingTextStyle",
    (WidgetTester tester) async {
      const TextStyle titleTextStyle = TextStyle(
        fontSize: 23.0,
        color: Color(0xffff0000),
        fontStyle: FontStyle.italic,
      );
      const TextStyle subtitleTextStyle = TextStyle(
        fontSize: 20.0,
        color: Color(0xff00ff00),
        fontStyle: FontStyle.italic,
      );
      const TextStyle leadingAndTrailingTextStyle = TextStyle(
        fontSize: 18.0,
        color: Color(0xff0000ff),
        fontStyle: FontStyle.italic,
      );

      final ThemeData theme = ThemeData(
        useMaterial3: false,
        listTileTheme: const ListTileThemeData(
          titleTextStyle: titleTextStyle,
          subtitleTextStyle: subtitleTextStyle,
          leadingAndTrailingTextStyle: leadingAndTrailingTextStyle,
        ),
      );

      Widget buildFrame() {
        return MaterialApp(
          theme: theme,
          home: Material(
            child: Center(
              child: Builder(
                builder: (BuildContext context) {
                  return const ListTile(
                    leading: TestText('leading'),
                    title: TestText('title'),
                    subtitle: TestText('subtitle'),
                    trailing: TestText('trailing'),
                  );
                },
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildFrame());
      final RenderParagraph leading = _getTextRenderObject(tester, 'leading');
      expect(leading.text.style!.fontSize, leadingAndTrailingTextStyle.fontSize);
      expect(leading.text.style!.color, leadingAndTrailingTextStyle.color);
      expect(leading.text.style!.fontStyle, leadingAndTrailingTextStyle.fontStyle);
      final RenderParagraph title = _getTextRenderObject(tester, 'title');
      expect(title.text.style!.fontSize, titleTextStyle.fontSize);
      expect(title.text.style!.color, titleTextStyle.color);
      expect(title.text.style!.fontStyle, titleTextStyle.fontStyle);
      final RenderParagraph subtitle = _getTextRenderObject(tester, 'subtitle');
      expect(subtitle.text.style!.fontSize, subtitleTextStyle.fontSize);
      expect(subtitle.text.style!.color, subtitleTextStyle.color);
      expect(subtitle.text.style!.fontStyle, subtitleTextStyle.fontStyle);
      final RenderParagraph trailing = _getTextRenderObject(tester, 'trailing');
      expect(trailing.text.style!.fontSize, leadingAndTrailingTextStyle.fontSize);
      expect(trailing.text.style!.color, leadingAndTrailingTextStyle.color);
      expect(trailing.text.style!.fontStyle, leadingAndTrailingTextStyle.fontStyle);
    },
  );

  testWidgets('ListTileTheme.merge combines static constructor parameters', (
    WidgetTester tester,
  ) async {
    const ListTileThemeData themeData = ListTileThemeData(
      dense: true,
      shape: StadiumBorder(),
      style: ListTileStyle.drawer,
      selectedColor: Color(0x00000001),
      iconColor: Color(0x00000002),
      textColor: Color(0x00000003),
      contentPadding: EdgeInsets.all(100),
      tileColor: Color(0x00000004),
      selectedTileColor: Color(0x00000005),
      horizontalTitleGap: 200,
      minVerticalPadding: 300,
      minLeadingWidth: 400,
      enableFeedback: true,
      mouseCursor: MaterialStateMouseCursor.clickable,
      visualDensity: VisualDensity.comfortable,
      titleAlignment: ListTileTitleAlignment.top,
      isThreeLine: true,
    );

    late ListTileThemeData mergedTheme;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListTileTheme.merge(
            dense: true,
            shape: const StadiumBorder(),
            style: ListTileStyle.drawer,
            selectedColor: const Color(0x00000001),
            iconColor: const Color(0x00000002),
            textColor: const Color(0x00000003),
            contentPadding: const EdgeInsets.all(100),
            tileColor: const Color(0x00000004),
            selectedTileColor: const Color(0x00000005),
            horizontalTitleGap: 200,
            minVerticalPadding: 300,
            minLeadingWidth: 400,
            enableFeedback: true,
            mouseCursor: MaterialStateMouseCursor.clickable,
            visualDensity: VisualDensity.comfortable,
            titleAlignment: ListTileTitleAlignment.top,
            isThreeLine: true,
            child: Center(
              child: Builder(
                builder: (BuildContext context) {
                  mergedTheme = ListTileTheme.of(context);
                  return const Placeholder();
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(mergedTheme.dense, themeData.dense);
    expect(mergedTheme.shape, themeData.shape);
    expect(mergedTheme.style, themeData.style);
    expect(mergedTheme.selectedColor, themeData.selectedColor);
    expect(mergedTheme.iconColor, themeData.iconColor);
    expect(mergedTheme.textColor, themeData.textColor);
    expect(mergedTheme.contentPadding, themeData.contentPadding);
    expect(mergedTheme.tileColor, themeData.tileColor);
    expect(mergedTheme.selectedTileColor, themeData.selectedTileColor);
    expect(mergedTheme.horizontalTitleGap, themeData.horizontalTitleGap);
    expect(mergedTheme.minVerticalPadding, themeData.minVerticalPadding);
    expect(mergedTheme.minLeadingWidth, themeData.minLeadingWidth);
    expect(mergedTheme.enableFeedback, themeData.enableFeedback);
    expect(mergedTheme.mouseCursor, themeData.mouseCursor);
    expect(mergedTheme.visualDensity, themeData.visualDensity);
    expect(mergedTheme.titleAlignment, themeData.titleAlignment);
    expect(mergedTheme.isThreeLine, themeData.isThreeLine);
  });

  testWidgets('ListTileTheme.merge combines static constructor parameters with parent theme', (
    WidgetTester tester,
  ) async {
    const ListTileThemeData parentTheme = ListTileThemeData(
      dense: false,
      shape: BeveledRectangleBorder(),
      style: ListTileStyle.list,
      selectedColor: Color(0x00000011),
      iconColor: Color(0x00000012),
      textColor: Color(0x00000013),
      contentPadding: EdgeInsets.all(110),
      tileColor: Color(0x00000014),
      selectedTileColor: Color(0x00000015),
      horizontalTitleGap: 210,
      minVerticalPadding: 310,
      minLeadingWidth: 410,
      enableFeedback: false,
      mouseCursor: MaterialStateMouseCursor.textable,
      visualDensity: VisualDensity.standard,
      titleAlignment: ListTileTitleAlignment.center,
      isThreeLine: false,
    );

    const ListTileThemeData themeData = ListTileThemeData(
      dense: true,
      shape: StadiumBorder(),
      style: ListTileStyle.drawer,
      selectedColor: Color(0x00000001),
      iconColor: Color(0x00000002),
      textColor: Color(0x00000003),
      contentPadding: EdgeInsets.all(100),
      tileColor: Color(0x00000004),
      selectedTileColor: Color(0x00000005),
      horizontalTitleGap: 200,
      minVerticalPadding: 300,
      minLeadingWidth: 400,
      enableFeedback: true,
      mouseCursor: MaterialStateMouseCursor.clickable,
      visualDensity: VisualDensity.comfortable,
      titleAlignment: ListTileTitleAlignment.top,
      isThreeLine: true,
    );

    late ListTileThemeData mergedTheme;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListTileTheme(
            data: parentTheme,
            child: ListTileTheme.merge(
              dense: true,
              shape: const StadiumBorder(),
              style: ListTileStyle.drawer,
              selectedColor: const Color(0x00000001),
              iconColor: const Color(0x00000002),
              textColor: const Color(0x00000003),
              contentPadding: const EdgeInsets.all(100),
              tileColor: const Color(0x00000004),
              selectedTileColor: const Color(0x00000005),
              horizontalTitleGap: 200,
              minVerticalPadding: 300,
              minLeadingWidth: 400,
              enableFeedback: true,
              mouseCursor: MaterialStateMouseCursor.clickable,
              visualDensity: VisualDensity.comfortable,
              titleAlignment: ListTileTitleAlignment.top,
              isThreeLine: true,
              child: Center(
                child: Builder(
                  builder: (BuildContext context) {
                    mergedTheme = ListTileTheme.of(context);
                    return const Placeholder();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(mergedTheme.dense, themeData.dense);
    expect(mergedTheme.shape, themeData.shape);
    expect(mergedTheme.style, themeData.style);
    expect(mergedTheme.selectedColor, themeData.selectedColor);
    expect(mergedTheme.iconColor, themeData.iconColor);
    expect(mergedTheme.textColor, themeData.textColor);
    expect(mergedTheme.contentPadding, themeData.contentPadding);
    expect(mergedTheme.tileColor, themeData.tileColor);
    expect(mergedTheme.selectedTileColor, themeData.selectedTileColor);
    expect(mergedTheme.horizontalTitleGap, themeData.horizontalTitleGap);
    expect(mergedTheme.minVerticalPadding, themeData.minVerticalPadding);
    expect(mergedTheme.minLeadingWidth, themeData.minLeadingWidth);
    expect(mergedTheme.enableFeedback, themeData.enableFeedback);
    expect(mergedTheme.mouseCursor, themeData.mouseCursor);
    expect(mergedTheme.visualDensity, themeData.visualDensity);
    expect(mergedTheme.titleAlignment, themeData.titleAlignment);
    expect(mergedTheme.isThreeLine, themeData.isThreeLine);
  });

  testWidgets('ListTileTheme.select only rebuilds when the selected property changes', (
    WidgetTester tester,
  ) async {
    int buildCount = 0;
    late Color? tileColor; // Use nullable Color?

    // Define two distinct colors to test changes.
    const Color color1 = Colors.red;
    const Color color2 = Colors.blue;

    final Widget singletonThemeSubtree = Builder(
      builder: (BuildContext context) {
        buildCount++;
        // Select the tileColor property.
        tileColor = ListTileTheme.select(context, (ListTileThemeData theme) => theme.tileColor);
        return const Placeholder();
      },
    );

    // Initial build with color1.
    await tester.pumpWidget(
      MaterialApp(
        home: ListTileTheme(
          data: const ListTileThemeData(tileColor: color1),
          child: singletonThemeSubtree,
        ),
      ),
    );

    expect(buildCount, 1);
    expect(tileColor, color1);

    // Rebuild with a change to a non-selected property (selectedTileColor).
    await tester.pumpWidget(
      MaterialApp(
        home: ListTileTheme(
          data: const ListTileThemeData(
            tileColor: color1, // Selected property unchanged
            selectedTileColor: color2, // Non-selected property changed
          ),
          child: singletonThemeSubtree,
        ),
      ),
    );

    // Expect no rebuild because the selected property didn't change.
    expect(buildCount, 1);
    expect(tileColor, color1);

    // Rebuild with a change to the selected property (tileColor).
    await tester.pumpWidget(
      MaterialApp(
        home: ListTileTheme(
          data: const ListTileThemeData(
            tileColor: color2, // Selected property changed
            selectedTileColor: color2,
          ),
          child: singletonThemeSubtree,
        ),
      ),
    );

    // Expect rebuild because the selected property changed.
    expect(buildCount, 2);
    expect(tileColor, color2);
  });
}
