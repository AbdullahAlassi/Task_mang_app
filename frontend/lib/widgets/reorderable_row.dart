import 'package:flutter/material.dart';
import 'dart:async';

class ReorderableRow extends StatefulWidget {
  final List<Widget> children;
  final Function(int, int) onReorder;
  final ScrollController? scrollController;

  const ReorderableRow({
    Key? key,
    required this.children,
    required this.onReorder,
    this.scrollController,
  }) : super(key: key);

  @override
  State<ReorderableRow> createState() => _ReorderableRowState();
}

class _ReorderableRowState extends State<ReorderableRow> {
  int? _dragIndex;
  Timer? _autoScrollTimer;
  double _dragStartX = 0;
  static const double _scrollThreshold =
      150.0; // Distance from screen edge to trigger scroll
  static const double _maxScrollSpeed = 25.0;
  static const double _minScrollSpeed = 10.0;
  GlobalKey _rowKey = GlobalKey();

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll(double dragX) {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 8), (_) {
      if (widget.scrollController == null) return;

      final scrollPosition = widget.scrollController!.position;
      final viewportDimension = scrollPosition.viewportDimension;
      final maxScroll = scrollPosition.maxScrollExtent;
      final currentScroll = scrollPosition.pixels;

      // Get the screen size
      final screenWidth = MediaQuery.of(context).size.width;

      // Calculate distance from screen edges
      final distanceFromLeftEdge = dragX;
      final distanceFromRightEdge = screenWidth - dragX;

      // Determine scroll direction and speed based on screen edges
      double scrollDelta = 0;
      if (distanceFromLeftEdge < _scrollThreshold) {
        // Scroll left when near left screen edge
        final speedFactor = 1 - (distanceFromLeftEdge / _scrollThreshold);
        scrollDelta = -(_minScrollSpeed +
            (_maxScrollSpeed - _minScrollSpeed) * speedFactor);
      } else if (distanceFromRightEdge < _scrollThreshold) {
        // Scroll right when near right screen edge
        final speedFactor = 1 - (distanceFromRightEdge / _scrollThreshold);
        scrollDelta =
            _minScrollSpeed + (_maxScrollSpeed - _minScrollSpeed) * speedFactor;
      }

      // Apply scroll with bounds checking
      if (scrollDelta != 0) {
        final newScroll = currentScroll + scrollDelta;
        if (newScroll >= 0 && newScroll <= maxScroll) {
          widget.scrollController!.jumpTo(newScroll);
        }
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      key: _rowKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(widget.children.length, (index) {
        return DragTarget<int>(
          onWillAccept: (data) => data != null && data != index,
          onAccept: (data) {
            widget.onReorder(data, index);
          },
          builder: (context, candidateData, rejectedData) {
            return Draggable<int>(
              data: index,
              feedback: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 100,
                    maxHeight: 500,
                  ),
                  child: SizedBox(
                    width: 300,
                    child: widget.children[index],
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.5,
                child: widget.children[index],
              ),
              onDragStarted: () {
                setState(() {
                  _dragIndex = index;
                });
                // Start auto-scrolling immediately when drag starts
                final RenderBox? renderBox =
                    context.findRenderObject() as RenderBox?;
                if (renderBox != null) {
                  final dragPosition = renderBox.localToGlobal(Offset.zero);
                  _startAutoScroll(dragPosition.dx);
                }
              },
              onDragEnd: (_) {
                setState(() {
                  _dragIndex = null;
                });
                _stopAutoScroll();
              },
              onDragUpdate: (details) {
                // Update drag position for auto-scrolling with screen coordinates
                _startAutoScroll(details.globalPosition.dx);
              },
              child: widget.children[index],
            );
          },
        );
      }),
    );
  }
}
