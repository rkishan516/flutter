// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/host_window_overlay.h"

#include "flutter/shell/platform/windows/flutter_windows_engine.h"

namespace {
flutter::BoxConstraints GetBoxConstraints(
    const flutter::WindowSizing& content_size) {
  std::optional<flutter::Size> smallest = std::nullopt;
  std::optional<flutter::Size> biggest = std::nullopt;

  if (content_size.has_view_constraints) {
    smallest = flutter::Size(content_size.view_min_width,
                             content_size.view_min_height);
    if (content_size.view_max_width > 0 && content_size.view_max_height > 0) {
      biggest = flutter::Size(content_size.view_max_width,
                              content_size.view_max_height);
    }
  }

  return flutter::BoxConstraints(smallest, biggest);
}

DWORD GetWindowStyleForOverlay() {
  // Use WS_POPUP for borderless window (no title bar, borders, etc.)
  return WS_POPUP | WS_VISIBLE;
}

DWORD GetExtendedWindowStyleForOverlay(bool always_on_top) {
  DWORD extended_window_style = WS_EX_TOOLWINDOW;  // Hide from taskbar
  if (always_on_top) {
    extended_window_style |= WS_EX_TOPMOST;
  }
  return extended_window_style;
}
}  // namespace

namespace flutter {

HostWindowOverlay::HostWindowOverlay(WindowManager* window_manager,
                                     FlutterWindowsEngine* engine,
                                     const WindowSizing& content_size,
                                     HWND parent_window,
                                     double initial_x,
                                     double initial_y,
                                     bool always_on_top)
    : HostWindow(
          window_manager,
          engine,
          WindowArchetype::kOverlay,
          GetWindowStyleForOverlay(),
          GetExtendedWindowStyleForOverlay(always_on_top),
          GetBoxConstraints(content_size),
          [&]() -> Rect {
            auto const constraints = GetBoxConstraints(content_size);
            auto const window_style = GetWindowStyleForOverlay();
            auto const extended_window_style =
                GetExtendedWindowStyleForOverlay(always_on_top);
            std::optional<Size> const window_size = GetWindowSizeForClientSize(
                *engine->windows_proc_table(),
                Size(content_size.preferred_view_width,
                     content_size.preferred_view_height),
                constraints.smallest(), constraints.biggest(), window_style,
                extended_window_style, parent_window);

            // Use the specified initial position
            Point window_origin = {static_cast<int>(initial_x),
                                   static_cast<int>(initial_y)};

            if (window_size.has_value()) {
              return Rect::MakeXYWH(window_origin.x, window_origin.y,
                                    window_size->width, window_size->height);
            } else {
              // Fallback to default size if size calculation fails
              return Rect::MakeXYWH(window_origin.x, window_origin.y, 200, 100);
            }
          }(),
          parent_window),
      always_on_top_(always_on_top) {
  // Apply initial always-on-top state after window creation
  if (GetWindowHandle()) {
    UpdateAlwaysOnTopState(always_on_top_);
  }
}

LRESULT HostWindowOverlay::HandleMessage(HWND hwnd,
                                         UINT message,
                                         WPARAM wparam,
                                         LPARAM lparam) {
  switch (message) {
    case WM_MOVE: {
      // Track position changes for notification to Dart layer
      POINT position = {LOWORD(lparam), HIWORD(lparam)};
      // Position change handling can be added here if needed
      break;
    }
  }

  // Call parent implementation for default handling
  return HostWindow::HandleMessage(hwnd, message, wparam, lparam);
}

void HostWindowOverlay::UpdateAlwaysOnTopState(bool always_on_top) {
  HWND hwnd = GetWindowHandle();
  if (hwnd) {
    HWND insert_after = always_on_top ? HWND_TOPMOST : HWND_NOTOPMOST;
    SetWindowPos(hwnd, insert_after, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    always_on_top_ = always_on_top;
  }
}

}  // namespace flutter