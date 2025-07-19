// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_OVERLAY_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_OVERLAY_H_

#include "host_window.h"

namespace flutter {
class HostWindowOverlay : public HostWindow {
 public:
  HostWindowOverlay(WindowManager* window_manager,
                    FlutterWindowsEngine* engine,
                    const WindowSizing& content_size,
                    HWND parent_window,
                    double initial_x,
                    double initial_y,
                    bool always_on_top);

 protected:
  LRESULT HandleMessage(HWND hwnd,
                        UINT message,
                        WPARAM wparam,
                        LPARAM lparam) override;

 private:
  // Updates the always-on-top state of the overlay window.
  void UpdateAlwaysOnTopState(bool always_on_top);

  bool always_on_top_;
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_HOST_WINDOW_OVERLAY_H_