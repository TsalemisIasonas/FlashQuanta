import 'package:flutter/material.dart';

class FlashcardWidget extends StatefulWidget {
  final String front;
  final String back;
  final double width;
  final double height;
  final VoidCallback? onFlip;

  const FlashcardWidget({
    Key? key,
    required this.front,
    required this.back,
    this.width = double.infinity,
    this.height = 220,
    this.onFlip,
  }) : super(key: key);

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget>
    with SingleTickerProviderStateMixin {
  bool _showFront = true;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  void _toggle() {
    setState(() {
      _showFront = !_showFront;
      if (_showFront) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    });
    widget.onFlip?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * 3.1416; // 0..pi
          final isFrontVisible = angle <= 3.1416 / 2 ? true : false;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(angle),
              child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.secondary,
                    colorScheme.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(blurRadius: 10, color: Colors.black45, offset: Offset(0, 1)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(1.5),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D0D), // almost black, slightly paler than pure black
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: isFrontVisible
                        ? Text(
                            widget.front,
                            style: const TextStyle(fontSize: 20, color: Colors.white),
                            textAlign: TextAlign.center,
                          )
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(3.1416),
                            child: Text(
                              widget.back,
                              style: const TextStyle(fontSize: 20, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}