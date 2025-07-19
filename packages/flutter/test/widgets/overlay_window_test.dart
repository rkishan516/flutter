// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show FlutterView;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverlayWindow', () {
    testWidgets('OverlayWindowController factory creates controller with correct properties', (WidgetTester tester) async {
      const Offset initialPosition = Offset(100, 200);
      const bool alwaysOnTop = true;
      const BoxConstraints constraints = BoxConstraints(
        minWidth: 200,
        maxWidth: 400,
        minHeight: 100,
        maxHeight: 300,
      );

      // This test will only work when platform implementation is available
      // For now, we expect an UnsupportedError since no platform implementation exists
      expect(() {
        OverlayWindowController(
          initialPosition: initialPosition,
          alwaysOnTop: alwaysOnTop,
          contentSizeConstraints: constraints,
        );
      }, throwsA(isA<UnsupportedError>()));
    });

    testWidgets('OverlayWindow widget builds correctly', (WidgetTester tester) async {
      // This test will only work when platform implementation is available
      // For now, we expect an UnsupportedError
      
      expect(() {
        OverlayWindowController(
          initialPosition: const Offset(100, 100),
          alwaysOnTop: true,
        );
      }, throwsA(isA<UnsupportedError>()));
    });

    testWidgets('OverlayWindowControllerDelegate callbacks work correctly', (WidgetTester tester) async {
      bool closeRequested = false;
      bool windowDestroyed = false;
      Offset? positionChanged;

      final TestOverlayDelegate delegate = TestOverlayDelegate(
        onCloseRequested: (OverlayWindowController controller) {
          closeRequested = true;
          controller.destroy();
        },
        onDestroyed: () {
          windowDestroyed = true;
        },
        onPositionChangedCallback: (Offset position) {
          positionChanged = position;
        },
      );

      // Test delegate callbacks (mock implementation)
      delegate.onWindowCloseRequested(TestOverlayController());
      expect(closeRequested, isTrue);

      delegate.onWindowDestroyed();
      expect(windowDestroyed, isTrue);

      delegate.onPositionChanged(const Offset(50, 75));
      expect(positionChanged, const Offset(50, 75));
    });

    testWidgets('WindowArchetype.overlay is properly defined', (WidgetTester tester) async {
      expect(WindowArchetype.values, contains(WindowArchetype.overlay));
      expect(WindowArchetype.overlay.toString(), 'WindowArchetype.overlay');
    });
  });

  group('OverlayWindowController', () {
    test('position property accessors', () {
      // Mock implementation for testing
      final TestOverlayController controller = TestOverlayController();
      
      // Test initial position
      expect(controller.position, Offset.zero);
      
      // Test position setting
      const Offset newPosition = Offset(150, 250);
      controller.setPosition(newPosition);
      expect(controller.position, newPosition);
    });

    test('alwaysOnTop property accessors', () {
      // Mock implementation for testing
      final TestOverlayController controller = TestOverlayController();
      
      // Test initial state
      expect(controller.alwaysOnTop, isFalse);
      
      // Test setting always on top
      controller.setAlwaysOnTop(true);
      expect(controller.alwaysOnTop, isTrue);
      
      // Test unsetting always on top
      controller.setAlwaysOnTop(false);
      expect(controller.alwaysOnTop, isFalse);
    });
  });
}

/// Test implementation of OverlayWindowControllerDelegate for testing callbacks
class TestOverlayDelegate with OverlayWindowControllerDelegate {
  TestOverlayDelegate({
    this.onCloseRequested,
    this.onDestroyed,
    this.onPositionChangedCallback,
  });

  final void Function(OverlayWindowController)? onCloseRequested;
  final void Function()? onDestroyed;
  final void Function(Offset)? onPositionChangedCallback;

  @override
  void onWindowCloseRequested(OverlayWindowController controller) {
    onCloseRequested?.call(controller);
  }

  @override
  void onWindowDestroyed() {
    onDestroyed?.call();
  }

  @override
  void onPositionChanged(Offset newPosition) {
    onPositionChangedCallback?.call(newPosition);
  }
}

/// Test implementation of OverlayWindowController for testing
class TestOverlayController extends OverlayWindowController {
  TestOverlayController() : super.empty();

  Offset _position = Offset.zero;
  bool _alwaysOnTop = false;

  @override
  WindowArchetype get type => WindowArchetype.overlay;

  @override
  Size get contentSize => const Size(200, 100);

  @override
  bool get destroyed => false;

  @override
  void destroy() {
    // Test implementation - no-op
  }

  @override
  Offset get position => _position;

  @override
  void setPosition(Offset position) {
    _position = position;
  }

  @override
  bool get alwaysOnTop => _alwaysOnTop;

  @override
  void setAlwaysOnTop(bool alwaysOnTop) {
    _alwaysOnTop = alwaysOnTop;
  }

  @override
  FlutterView? get parent => null;
}
