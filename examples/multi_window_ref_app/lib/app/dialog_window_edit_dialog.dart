// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void showDialogWindowEditDialog(
    {required BuildContext context,
    required DialogWindowController controller}) {
  showDialog(
      context: context,
      builder: (context) => _DialogWindowEditDialog(
          controller: controller, onClose: () => Navigator.pop(context)));
}

class _DialogWindowEditDialog extends StatefulWidget {
  const _DialogWindowEditDialog(
      {required this.controller, required this.onClose});

  final DialogWindowController controller;
  final VoidCallback onClose;

  @override
  State<StatefulWidget> createState() => _DialogWindowEditDialogState();
}

class _DialogWindowEditDialogState extends State<_DialogWindowEditDialog> {
  late Size initialSize;
  late String initialTitle;
  late bool initialMinimized;

  late final TextEditingController widthController;
  late final TextEditingController heightController;
  late final TextEditingController titleController;

  bool? nextIsMinized;

  @override
  void initState() {
    super.initState();
    initialSize = widget.controller.contentSize;
    initialTitle = ""; // TODO: Get the title
    initialMinimized = widget.controller.isMinimized();

    widthController = TextEditingController(text: initialSize.width.toString());
    heightController =
        TextEditingController(text: initialSize.height.toString());
    titleController = TextEditingController(text: initialTitle);

    widget.controller.addListener(_onNotification);
  }

  void _onNotification() {
    // We listen on the state of the controller. If a value that the user
    // can edit changes from what it was initially set to, we invalidate
    // their current change and store the new "initial" value.
    if (widget.controller.contentSize != initialSize) {
      initialSize = widget.controller.contentSize;
      widthController.text = widget.controller.contentSize.width.toString();
      heightController.text = widget.controller.contentSize.height.toString();
    }
    if (widget.controller.isMinimized() != initialMinimized) {
      setState(() {
        initialMinimized = widget.controller.isMinimized();
        nextIsMinized = null;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_onNotification);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Window Properties"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widthController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Width"),
          ),
          TextField(
            controller: heightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Height"),
          ),
          TextField(
            controller: titleController,
            decoration: InputDecoration(labelText: "Title"),
          ),
          CheckboxListTile(
              title: const Text('Minimized'),
              value: nextIsMinized ?? initialMinimized,
              onChanged: (bool? value) {
                if (value != null) {
                  setState(() => nextIsMinized = value);
                }
              })
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => widget.onClose(),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () => _onSave(),
          child: Text("Save"),
        ),
      ],
    );
  }

  void _onSave() {
    double? width = double.tryParse(widthController.text);
    double? height = double.tryParse(heightController.text);
    String? title = titleController.text.isEmpty ? null : titleController.text;
    if (width != null && height != null) {
      widget.controller.updateContentSize(
        WindowSizing(preferredSize: Size(width, height)),
      );
    }
    if (title != null) {
      widget.controller.setTitle(title);
    }
    if (nextIsMinized != null) {
      if (widget.controller.isMinimized() != nextIsMinized) {
        widget.controller.setMinimized(nextIsMinized!);
      }
    }

    widget.onClose();
  }
}
