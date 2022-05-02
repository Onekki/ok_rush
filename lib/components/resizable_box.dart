import 'dart:math';

import 'package:flutter/material.dart';

class ResizableBox extends StatefulWidget {
  const ResizableBox({Key? key, required this.maxHeight, required this.child})
      : super(key: key);

  final Widget child;
  final double maxHeight;

  @override
  State<StatefulWidget> createState() {
    return _ResizableBoxState();
  }
}

class _ResizableBoxState extends State<ResizableBox> {
  late double height;

  @override
  void initState() {
    super.initState();
    height = widget.maxHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: height,
          child: widget.child,
        ),
        GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              var newHeight = height + details.delta.dy;
              height = max(min(widget.maxHeight, newHeight), 0);
              debugPrint("height = $height");
            });
          },
          child: Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            height: 16,
            decoration: const BoxDecoration(color: Colors.black),
            child: Container(
              alignment: Alignment.center,
              width: 128,
              height: 4,
              decoration: const BoxDecoration(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(
          height: 8,
        )
      ],
    );
  }
}
