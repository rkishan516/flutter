// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show AppExitType, Display, FlutterView;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '_window_ffi.dart' if (dart.library.js_util) '_window_web.dart' as window_impl;
import 'binding.dart';
import 'framework.dart';
import 'view.dart';
import 'window_positioner.dart';

/// Defines the possible archetypes for a window.
enum WindowArchetype {
  /// Defines a traditional window
  regular,

  /// Defines a dialog window
  dialog,

  /// Defines a tooltip window
  tooltip,

  /// Defines an overlay window
  overlay,
}

/// Defines sizing request for a window.
class WindowSizing {
  /// Creates a new [WindowSizing] object.
  WindowSizing({this.preferredSize, this.constraints});

  /// Preferred size of the window. This may not be honored by the platform.
  final Size? preferredSize;

  /// Constraints for the window. This may not be honored by the platform.
  final BoxConstraints? constraints;
}

/// Base class for window controllers.
///
/// A window controller must provide a [future] that resolves to a
/// a [WindowCreationResult] object. This object contains the view
/// associated with the window, the archetype of the window, the size
/// of the window, and the state of the window.
///
/// The caller may also provide a callback to be called when the window
/// is destroyed, and a callback to be called when an error is encountered
/// during the creation of the window.
///
/// Each [WindowController] is associated with exactly one root [FlutterView].
///
/// When the window is destroyed for any reason (either by the caller or by the
/// platform), the content of the controller will thereafter be invalid. Callers
/// may check if this content is invalid via the [isReady] property.
///
/// This class implements the [Listenable] interface, so callers can listen
/// for changes to the window's properties.
abstract class WindowController with ChangeNotifier {
  @protected
  /// Sets the view associated with this window.
  // ignore: use_setters_to_change_properties
  void setView(FlutterView view) {
    _view = view;
  }

  /// The archetype of the window.
  WindowArchetype get type;

  /// The current size of the window. This may differ from the requested size.
  Size get contentSize;

  /// Destroys this window. It is permissible to call this method multiple times.
  void destroy();

  /// Whether this window has been destroyed.
  bool get destroyed;

  /// The root view associated to this window, which is unique to each window.
  FlutterView get rootView => _view;
  late final FlutterView _view;
}

abstract class TooltipWindowController extends WindowController {
  factory TooltipWindowController({
    required FlutterView parent,
    required Rect anchorRect,
    required WindowPositioner positioner,
    BoxConstraints? contentSizeConstraints,
    TooltipWindowControllerDelegate? delegate,
  }) {
    WidgetsFlutterBinding.ensureInitialized();
    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    final TooltipWindowController controller = owner.createTooltipWindowController(
      parent: parent,
      contentSizeConstraints: contentSizeConstraints ?? const BoxConstraints(),
      delegate: delegate ?? TooltipWindowControllerDelegate(),
      anchorRect: anchorRect,
      positioner: positioner,
    );
    return controller;
  }

  @protected
  /// Creates an empty [TooltipWindowController].
  TooltipWindowController.empty();

  @override
  WindowArchetype get type => WindowArchetype.tooltip;
}

/// A controller for an overlay window.
///
/// An overlay window is a frameless, floating window that automatically adjusts
/// size based on content dimensions and appears above other windows. Unlike
/// existing archetypes, overlay windows can have parent-child relationships and
/// persist independently while maintaining always-on-top behavior as optional
/// behavior.
///
/// This class does not interact with the widget tree. Instead, it is typically
/// provided to the [OverlayWindow] widget, which renders the content inside the
/// overlay window.
///
/// An example usage might look like:
/// ```dart
/// final OverlayWindowController controller = OverlayWindowController(
///   initialPosition: const Offset(100, 100),
///   alwaysOnTop: true,
/// );
/// runApp(OverlayWindow(
///   controller: controller,
///   child: Container(
///     padding: const EdgeInsets.all(16),
///     child: const Text('Overlay Content'),
///   ),
/// ));
/// ```
///
/// When provided to an [OverlayWindow] widget, widgets inside of the [child]
/// parameter will have access to the [OverlayWindowController] via the
/// [WindowControllerContext] widget.
abstract class OverlayWindowController extends WindowController {
  /// Creates an [OverlayWindowController] with the provided properties.
  /// Upon construction, the overlay window is created for the platform.
  ///
  /// [parent] optional parent view for the overlay window.
  /// [anchorRect] rectangle used as reference for positioning the overlay.
  /// [positioner] handles intelligent positioning of the overlay window.
  /// [contentSizeConstraints] constraints for the window content size.
  /// [delegate] optional delegate for the controller.
  /// [alwaysOnTop] whether the overlay window should stay on top of other windows.
  factory OverlayWindowController({
    FlutterView? parent,
    required Rect anchorRect,
    required WindowPositioner positioner,
    BoxConstraints? contentSizeConstraints,
    OverlayWindowControllerDelegate? delegate,
    bool alwaysOnTop = false,
  }) {
    WidgetsFlutterBinding.ensureInitialized();
    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    final OverlayWindowController controller = owner.createOverlayWindowController(
      parent: parent,
      anchorRect: anchorRect,
      positioner: positioner,
      contentSizeConstraints: contentSizeConstraints ?? const BoxConstraints(),
      delegate: delegate ?? OverlayWindowControllerDelegate(),
      alwaysOnTop: alwaysOnTop,
    );
    return controller;
  }

  @protected
  /// Creates an empty [OverlayWindowController].
  OverlayWindowController.empty();

  @override
  WindowArchetype get type => WindowArchetype.overlay;

  /// Whether the overlay window is always on top of other windows.
  bool get alwaysOnTop;

  /// Sets whether the overlay window should be always on top of other windows.
  void setAlwaysOnTop(bool alwaysOnTop);

  /// The parent view of the overlay window, if any.
  FlutterView? get parent;
}

mixin class TooltipWindowControllerDelegate {
  /// Invoked when user attempts to close the window. Default implementation
  /// destroys the window. Subclass can override the behavior to delay
  /// or prevent the window from closing.
  void onWindowCloseRequested(TooltipWindowController controller) {
    controller.destroy();
  }

  void onWindowDestroyed() {}
}

/// Delegate class for overlay window controller.
mixin class OverlayWindowControllerDelegate {
  /// Invoked when user attempts to close the window. Default implementation
  /// destroys the window. Subclass can override the behavior to delay
  /// or prevent the window from closing.
  void onWindowCloseRequested(OverlayWindowController controller) {
    controller.destroy();
  }

  void onWindowDestroyed() {}
}

/// Delegate class for regular window controller.
mixin class RegularWindowControllerDelegate {
  /// Invoked when user attempts to close the window. Default implementation
  /// destroys the window. Subclass can override the behavior to delay
  /// or prevent the window from closing.
  void onWindowCloseRequested(RegularWindowController controller) {
    controller.destroy();
  }

  /// Invoked when the window is closed. Default implementation exits the
  /// application if this was the last top-level window.
  void onWindowDestroyed() {
    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    if (!owner.hasTopLevelWindows()) {
      // No more top-level windows, exit the application.
      ServicesBinding.instance.exitApplication(AppExitType.cancelable);
    }
  }
}

/// Delegate class for dialog window controller.
mixin class DialogWindowControllerDelegate {
  /// Invoked when user attempts to close the window. Default implementation
  /// destroys the window. Subclass can override the behavior to delay
  /// or prevent the window from closing.
  void onWindowCloseRequested(DialogWindowController controller) {
    controller.destroy();
  }

  /// Invoked when the window is closed. Default implementation exits the
  /// application if this was the last top-level window.
  void onWindowDestroyed() {
    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    if (!owner.hasTopLevelWindows()) {
      // No more top-level windows, exit the application.
      ServicesBinding.instance.exitApplication(AppExitType.cancelable);
    }
  }
}

/// A controller for a regular window.
///
/// A regular window is a traditional window that can be resized, minimized,
/// maximized, and closed. Upon construction, the window is created for the
/// platform with the provided properties.
///
/// This class does not interact with the widget tree. Instead, it is typically
/// provided to the [RegularWindow] widget, who does the work of rendering the
/// content inside of this window.
///
/// An example usage might look like:
/// ```dart
/// final RegularWindowController controller = RegularWindowController(
///   contentSize: const WindowSizing(
///     size: Size(800, 600),
///     constraints: BoxConstraints(minWidth: 640, minHeight: 480),
///   ),
///   title: "Example Window",
/// );
/// runWidget(RegularWindow(
///   controller: controller,
///   child: MaterialApp(home: Container())));
/// ```
///
/// When provided to a [RegularWindow] widget, widgets inside of the [child]
/// parameter will have access to the [RegularWindowController] via the
/// [WindowControllerContext] widget.
abstract class RegularWindowController extends WindowController {
  /// Creates a [RegularWindowController] with the provided properties.
  /// Upon construction, the window is created for the platform.
  ///
  /// [contentSize] sizing requests for the window. This may not be honored by the platform
  /// [title] the title of the window
  /// [state] the initial state of the window
  /// [delegate] optional delegate for the controller controller.
  factory RegularWindowController({
    required WindowSizing contentSize,
    String? title,
    RegularWindowControllerDelegate? delegate,
  }) {
    WidgetsFlutterBinding.ensureInitialized();
    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    final RegularWindowController controller = owner.createRegularWindowController(
      contentSize: contentSize,
      delegate: delegate ?? RegularWindowControllerDelegate(),
    );
    if (title != null) {
      controller.setTitle(title);
    }
    return controller;
  }

  @protected
  /// Creates an empty [RegularWindowController].
  RegularWindowController.empty();

  @override
  WindowArchetype get type => WindowArchetype.regular;

  /// Request change for the window content size.
  ///
  /// [contentSize] describes the new requested window size. The properties
  /// of this object are applied independently of each other. For example,
  /// setting [WindowSizing.preferredSize] does not affect the [WindowSizing.constraints]
  /// set previously.
  ///
  /// System compositor is free to ignore the request.
  void updateContentSize(WindowSizing sizing);

  /// Request change for the window title.
  /// [title] new title of the window.
  void setTitle(String title);

  /// Requests that the window be displayed in its current size and position.
  /// If the window is minimized or maximized, the window returns to the size
  /// and position that it had before that state was applied.
  void activate();

  /// Requests the window to be maximized. This has no effect
  /// if the window is currently full screen or minimized, but may
  /// affect the window size upon restoring it from minimized or
  /// full screen state.
  void setMaximized(bool maximized);

  /// Returns whether window is currently maximized.
  bool isMaximized();

  /// Requests window to be minimized.
  void setMinimized(bool minimized);

  /// Returns whether window is currently minimized.
  bool isMinimized();

  /// Request change for the window to enter or exit fullscreen state.
  /// [fullscreen] whether to enter or exit fullscreen state.
  /// [displayId] optional [Display] identifier to use for fullscreen mode.
  /// Specifying the [displayId] might not be supported on all platforms.
  void setFullscreen(bool fullscreen, {int? displayId});

  /// Returns whether window is currently in fullscreen mode.
  bool isFullscreen();
}

/// A controller for a dialog window.
///
/// Two types of dialogs are supported:
///  * Modal dialogs: created with a non-null [parent]. These dialogs are modal
///    to [parent], do not have a system menu and are not selectable from the
///    window switcher.
///  * Modeless dialogs: created with a null [parent]. These dialogs can be
///    minimized (but not maximized), and have a disabled close button.
///
/// This class does not interact with the widget tree. Instead, it is typically
/// provided to the [DialogWindow] widget, which renders the content inside the
/// dialog window.
///
/// When provided to a [DialogWindow] widget, widgets inside of the [child]
/// parameter will have access to the [DialogWindowController] via the
/// [WindowControllerContext] widget.
abstract class DialogWindowController extends WindowController {
  /// Creates a [DialogWindowController] with the provided properties.
  /// Upon construction, the dialog is created for the platform.
  ///
  /// If [parent] is non-null, the dialog is created as modal.
  ///
  /// [contentSize] Initial content size of the window.
  /// [parent] root view of the parent window.
  /// [title] the title of the window.
  /// [state] the initial state of the window.
  /// [delegate] optional delegate for the controller controller.
  factory DialogWindowController({
    required WindowSizing contentSize,
    FlutterView? parent,
    String? title,
    DialogWindowControllerDelegate? delegate,
  }) {
    WidgetsFlutterBinding.ensureInitialized();
    final WindowingOwner owner = WidgetsBinding.instance.windowingOwner;
    final DialogWindowController controller = owner.createDialogWindowController(
      contentSize: contentSize,
      delegate: delegate ?? DialogWindowControllerDelegate(),
      parent: parent,
    );
    if (title != null) {
      controller.setTitle(title);
    }
    return controller;
  }

  @protected
  /// Creates an empty [DialogWindowController].
  DialogWindowController.empty();

  @override
  WindowArchetype get type => WindowArchetype.dialog;

  /// The parent view.
  FlutterView? get parent;

  /// Request change for the window content size.
  ///
  /// [contentSize] describes the new requested window size. The properties
  /// of this object are applied independently of each other. For example,
  /// setting [WindowSizing.size] does not affect the [WindowSizing.constraints]
  /// set previously.
  ///
  /// System compositor is free to ignore the request.
  void updateContentSize(WindowSizing contentSize);

  /// Request change for the window title.
  /// [title] new title of the window.
  void setTitle(String title);

  /// Requests window to be minimized.
  void setMinimized(bool minimized);

  /// Returns whether window is currently minimized.
  bool isMinimized();
}

/// [WindowingOwner] is responsible for creating and managing window controllers.
///
/// Custom subclass can be provided by subclassing [WidgetsBinding] and
/// overriding the [createWindowingOwner] method.
abstract class WindowingOwner {
  /// Creates a [RegularWindowController] with the provided properties.
  RegularWindowController createRegularWindowController({
    required WindowSizing contentSize,
    required RegularWindowControllerDelegate delegate,
  });

  /// Creates a [DialogWindowController] with the provided properties.
  DialogWindowController createDialogWindowController({
    required WindowSizing contentSize,
    required DialogWindowControllerDelegate delegate,
    FlutterView? parent,
  });

  /// Creates a [TooltipWindowController] with the provided properties.
  TooltipWindowController createTooltipWindowController({
    required BoxConstraints contentSizeConstraints,
    required Rect anchorRect,
    required WindowPositioner positioner,
    required TooltipWindowControllerDelegate delegate,
    required FlutterView parent,
  });

  /// Creates an [OverlayWindowController] with the provided properties.
  OverlayWindowController createOverlayWindowController({
    required BoxConstraints contentSizeConstraints,
    required OverlayWindowControllerDelegate delegate,
    required Rect anchorRect,
    required WindowPositioner positioner,
    FlutterView? parent,
    bool alwaysOnTop = false,
  });

  /// Returns whether application has any top level windows created by this
  /// windowing owner.
  bool hasTopLevelWindows();

  /// Creates default windowing owner for standard desktop embedders.
  static WindowingOwner createDefaultOwner() {
    return window_impl.createDefaultOwner() ?? _FallbackWindowingOwner();
  }
}

/// Windowing delegate used on platforms that do not support windowing.
class _FallbackWindowingOwner extends WindowingOwner {
  @override
  RegularWindowController createRegularWindowController({
    required WindowSizing contentSize,
    required RegularWindowControllerDelegate delegate,
  }) {
    throw UnsupportedError(
      'Current platform does not support windowing.\n'
      'Implement a WindowingDelegate for this platform.',
    );
  }

  @override
  DialogWindowController createDialogWindowController({
    required WindowSizing contentSize,
    required DialogWindowControllerDelegate delegate,
    FlutterView? parent,
  }) {
    throw UnsupportedError(
      'Current platform does not support windowing.\n'
      'Implement a WindowingDelegate for this platform.',
    );
  }

  @override
  TooltipWindowController createTooltipWindowController({
    required BoxConstraints contentSizeConstraints,
    required TooltipWindowControllerDelegate delegate,
    required FlutterView parent,
    required Rect anchorRect,
    required WindowPositioner positioner,
  }) {
    throw UnsupportedError(
      'Current platform does not support windowing.\n'
      'Implement a WindowingDelegate for this platform.',
    );
  }

  @override
  OverlayWindowController createOverlayWindowController({
    required BoxConstraints contentSizeConstraints,
    required OverlayWindowControllerDelegate delegate,
    required Rect anchorRect,
    required WindowPositioner positioner,
    FlutterView? parent,
    bool alwaysOnTop = false,
  }) {
    throw UnsupportedError(
      'Current platform does not support windowing.\n'
      'Implement a WindowingDelegate for this platform.',
    );
  }

  @override
  bool hasTopLevelWindows() {
    return false;
  }
}

/// The [RegularWindow] widget provides a way to render a regular window in the
/// widget tree. The provided [controller] creates the native window that backs
/// the widget. The [child] widget is rendered into this newly created window.
///
/// While the window is being created, the [RegularWindow] widget will render
/// an empty [ViewCollection] widget. Once the window is created, the [child]
/// widget will be rendered into the window inside of a [View].
///
/// An example usage might look like:
/// ```dart
/// final RegularWindowController controller = RegularWindowController(
///   contentSize: const WindowSizing(
///     size: Size(800, 600),
///     constraints: BoxConstraints(minWidth: 640, minHeight: 480),
///   ),
///   title: "Example Window",
/// );
/// runApp(RegularWindow(
///   controller: controller,
///   child: MaterialApp(home: Container())));
/// ```
///
/// When a [RegularWindow] widget is removed from the tree, the window that was created
/// by the [controller] is automatically destroyed if it has not yet been destroyed.
///
/// Widgets in the same tree as the [child] widget will have access to the
/// [RegularWindowController] via the [WindowControllerContext] widget.
class RegularWindow extends StatefulWidget {
  /// Creates a regular window widget.
  /// [controller] the controller for this window
  /// [child] the content to render into this window
  /// [key] the key for this widget
  const RegularWindow({super.key, required this.controller, required this.child});

  /// Controller for this widget.
  final RegularWindowController controller;

  /// The content rendered into this window.
  final Widget child;

  @override
  State<RegularWindow> createState() => _RegularWindowState();
}

class _RegularWindowState extends State<RegularWindow> {
  @override
  void dispose() {
    super.dispose();
    widget.controller.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return View(
      view: widget.controller.rootView,
      child: WindowControllerContext(controller: widget.controller, child: widget.child),
    );
  }
}

/// The [DialogWindow] widget provides a way to render a dialog window in the
/// widget tree. The provided [controller] creates the native window that backs
/// the widget. The [child] widget is rendered into this newly created window.
///
/// While the window is being created, the [DialogWindow] widget will render
/// an empty [ViewCollection] widget. Once the window is created, the [child]
/// widget will be rendered into the window inside of a [View].
///
/// When a [DialogWindow] widget is removed from the tree, the window that was created
/// by the [controller] is automatically destroyed if it has not yet been destroyed.
///
/// Widgets in the same tree as the [child] widget will have access to the
/// [DialogWindowController] via the [WindowControllerContext] widget.
class DialogWindow extends StatefulWidget {
  /// Creates a dialog window widget.
  /// [controller] the controller for this window
  /// [child] the content to render into this window
  /// [key] the key for this widget
  const DialogWindow({super.key, required this.controller, required this.child});

  /// Controller for this widget.
  final DialogWindowController controller;

  /// The content rendered into this window.
  final Widget child;

  @override
  State<DialogWindow> createState() => _DialogWindowState();
}

class _DialogWindowState extends State<DialogWindow> {
  @override
  void dispose() {
    super.dispose();
    widget.controller.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return View(
      view: widget.controller.rootView,
      child: WindowControllerContext(controller: widget.controller, child: widget.child),
    );
  }
}

/// The [TooltipWindow] widget provides a way to render a tooltip window in the
/// widget tree. The provided [controller] creates the native window that backs
/// the widget. The [child] widget is rendered into this newly created window.
///
/// While the window is being created, the [TooltipWindow] widget will render
/// an empty [ViewCollection] widget. Once the window is created, the [child]
/// widget will be rendered into the window inside of a [View].
///
/// When a [TooltipWindow] widget is removed from the tree, the window that was created
/// by the [controller] is automatically destroyed if it has not yet been destroyed.
///
/// Widgets in the same tree as the [child] widget will have access to the
/// [TooltipWindowController] via the [WindowControllerContext] widget.
class TooltipWindow extends StatefulWidget {
  /// Creates a dialog window widget.
  /// [controller] the controller for this window
  /// [child] the content to render into this window
  /// [key] the key for this widget
  const TooltipWindow({super.key, required this.controller, required this.child});

  /// Controller for this widget.
  final TooltipWindowController controller;

  /// The content rendered into this window.
  final Widget child;

  @override
  State<TooltipWindow> createState() => _TooltipWindowState();
}

class _TooltipWindowState extends State<TooltipWindow> {
  @override
  void dispose() {
    super.dispose();
    widget.controller.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return View(
      view: widget.controller.rootView,
      child: WindowControllerContext(controller: widget.controller, child: widget.child),
    );
  }
}

/// The [OverlayWindow] widget provides a way to render an overlay window in the
/// widget tree. The provided [controller] creates the native window that backs
/// the widget. The [child] widget is rendered into this newly created window.
///
/// While the window is being created, the [OverlayWindow] widget will render
/// an empty [ViewCollection] widget. Once the window is created, the [child]
/// widget will be rendered into the window inside of a [View].
///
/// An example usage might look like:
/// ```dart
/// final OverlayWindowController controller = OverlayWindowController(
///   initialPosition: const Offset(100, 100),
///   alwaysOnTop: true,
/// );
/// runApp(OverlayWindow(
///   controller: controller,
///   child: Container(
///     padding: const EdgeInsets.all(16),
///     child: const Text('Overlay Content'),
///   ),
/// ));
/// ```
///
/// When an [OverlayWindow] widget is removed from the tree, the window that was created
/// by the [controller] is automatically destroyed if it has not yet been destroyed.
///
/// Widgets in the same tree as the [child] widget will have access to the
/// [OverlayWindowController] via the [WindowControllerContext] widget.
class OverlayWindow extends StatefulWidget {
  /// Creates an overlay window widget.
  /// [controller] the controller for this window
  /// [child] the content to render into this window
  /// [key] the key for this widget
  const OverlayWindow({super.key, required this.controller, required this.child});

  /// Controller for this widget.
  final OverlayWindowController controller;

  /// The content rendered into this window.
  final Widget child;

  @override
  State<OverlayWindow> createState() => _OverlayWindowState();
}

class _OverlayWindowState extends State<OverlayWindow> {
  @override
  void dispose() {
    super.dispose();
    widget.controller.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return View(
      view: widget.controller.rootView,
      child: WindowControllerContext(controller: widget.controller, child: widget.child),
    );
  }
}

/// Provides descendants with access to the [WindowController] associated with
/// the window that is being rendered.
class WindowControllerContext extends InheritedWidget {
  /// Creates a new [WindowControllerContext]
  /// [controller] the controller associated with this window
  /// [child] the child widget
  const WindowControllerContext({super.key, required this.controller, required super.child});

  /// The controller associated with this window.
  final WindowController controller;

  /// Returns the [WindowContext] if any
  static WindowController? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WindowControllerContext>()?.controller;
  }

  @override
  bool updateShouldNotify(WindowControllerContext oldWidget) {
    return controller != oldWidget.controller;
  }
}
