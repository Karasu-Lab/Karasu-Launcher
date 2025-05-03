import 'package:flutter/material.dart';

class ReorderableGridView extends StatefulWidget {
  final SliverGridDelegate gridDelegate;
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final void Function(int oldIndex, int newIndex) onReorder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ReorderableGridView({
    super.key,
    required this.gridDelegate,
    required this.itemBuilder,
    required this.itemCount,
    required this.onReorder,
    this.shrinkWrap = false,
    this.physics,
  });

  static ReorderableGridView builder({
    Key? key,
    required SliverGridDelegate gridDelegate,
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    required void Function(int oldIndex, int newIndex) onReorder,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ReorderableGridView(
      key: key,
      gridDelegate: gridDelegate,
      itemBuilder: itemBuilder,
      itemCount: itemCount,
      onReorder: onReorder,
      shrinkWrap: shrinkWrap,
      physics: physics,
    );
  }

  @override
  _ReorderableGridViewState createState() => _ReorderableGridViewState();
}

class _ReorderableGridViewState extends State<ReorderableGridView> {
  int? _draggedItemIndex;
  int? _hoveredItemIndex;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: widget.gridDelegate,
      itemCount: widget.itemCount,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemBuilder: (context, index) {
        final child = widget.itemBuilder(context, index);

        return LongPressDraggable<int>(
          key: child.key,
          data: index,
          feedback: Material(
            elevation: 6.0,
            color: Colors.transparent,
            child: SizedBox(
              width: 250,
              height: 200,
              child: Opacity(opacity: 0.7, child: child),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: child),
          onDragStarted: () {
            setState(() {
              _draggedItemIndex = index;
            });
          },
          onDragEnd: (_) {
            setState(() {
              _draggedItemIndex = null;
              _hoveredItemIndex = null;
            });
          },
          onDragCompleted: () {
            setState(() {
              _draggedItemIndex = null;
              _hoveredItemIndex = null;
            });
          },
          child: DragTarget<int>(
            onWillAcceptWithDetails: (details) {
              return details.data != index;
            },
            onAcceptWithDetails: (details) {
              final dragIndex = details.data;
              final targetIndex = index;

              if (dragIndex >= 0 &&
                  dragIndex < widget.itemCount &&
                  targetIndex >= 0 &&
                  targetIndex < widget.itemCount) {
                if (dragIndex != targetIndex) {
                  setState(() {
                    _hoveredItemIndex = null;
                    widget.onReorder(dragIndex, targetIndex);
                  });
                }
              }

              setState(() {
                _hoveredItemIndex = null;
              });
            },
            onMove: (_) {
              if (_hoveredItemIndex != index) {
                setState(() {
                  _hoveredItemIndex = index;
                });
              }
            },
            onLeave: (_) {
              if (_hoveredItemIndex == index) {
                setState(() {
                  _hoveredItemIndex = null;
                });
              }
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                decoration:
                    _hoveredItemIndex == index
                        ? BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        )
                        : null,
                child: child,
              );
            },
          ),
        );
      },
    );
  }
}
