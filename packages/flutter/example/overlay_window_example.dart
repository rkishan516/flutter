// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Example demonstrating the overlay window functionality.
/// 
/// This example creates a simple overlay window that displays
/// floating content above other windows.
void main() {
  runApp(const OverlayWindowExample());
}

class OverlayWindowExample extends StatelessWidget {
  const OverlayWindowExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Create an overlay window controller
    final OverlayWindowController overlayController = OverlayWindowController(
      initialPosition: const Offset(100, 100),
      alwaysOnTop: true,
      contentSizeConstraints: const BoxConstraints(
        minWidth: 200,
        maxWidth: 400,
        minHeight: 100,
        maxHeight: 300,
      ),
    );

    return OverlayWindow(
      controller: overlayController,
      child: const MaterialApp(
        home: OverlayContent(),
      ),
    );
  }
}

class OverlayContent extends StatefulWidget {
  const OverlayContent({super.key});

  @override
  State<OverlayContent> createState() => _OverlayContentState();
}

class _OverlayContentState extends State<OverlayContent> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Overlay Window',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Counter: $_counter',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: _incrementCounter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Increment'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Access the overlay controller to change position
                    final OverlayWindowController? controller = 
                        WindowControllerContext.of(context) as OverlayWindowController?;
                    if (controller != null) {
                      // Move the overlay to a new position
                      controller.setPosition(
                        Offset(
                          controller.position.dx + 50,
                          controller.position.dy + 50,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Move'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Example of a floating toolbar overlay
class FloatingToolbarExample extends StatelessWidget {
  const FloatingToolbarExample({super.key});

  @override
  Widget build(BuildContext context) {
    final OverlayWindowController toolbarController = OverlayWindowController(
      initialPosition: const Offset(50, 200),
      alwaysOnTop: true,
      contentSizeConstraints: const BoxConstraints(
        minWidth: 60,
        maxHeight: 300,
      ),
    );

    return OverlayWindow(
      controller: toolbarController,
      child: MaterialApp(
        home: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.brush, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.color_lens, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.text_fields, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.layers, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}