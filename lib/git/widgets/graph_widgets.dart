import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:pure_extensions/pure_extensions.dart';

class GraphChip extends StatelessWidget {
  final bool isSelected;
  final Widget icon;
  final List<Widget> children;

  const GraphChip({
    super.key,
    this.isSelected = false,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.primary,
      borderRadius: const BorderRadius.all(Radius.circular(8.0)),
      child: SizedBox(
        height: 24.0,
        child: Row(
          children: [
            const SizedBox(width: 4.0),
            IconTheme(
              data: const IconThemeData(size: 16.0),
              child: icon,
            ),
            DefaultTextStyle.merge(
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w900 : null,
                color: colors.onPrimary,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children
                    .mapIndexed<Widget>((index, child) {
                      return ChipGraphScope(
                        isLast: children.length == index + 1,
                        child: child,
                      );
                    })
                    .joinElement(VerticalDivider(width: 0.0, color: colors.onPrimary))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChipGraphScope extends InheritedWidget {
  final bool isLast;

  const ChipGraphScope({
    super.key,
    required this.isLast,
    required super.child,
  });

  static ChipGraphScope of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<ChipGraphScope>();
    assert(result != null, 'No ChipGraphScope found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(ChipGraphScope oldWidget) => isLast != oldWidget.isLast;
}

class GraphTile extends StatelessWidget {
  final VoidCallback? onSecondaryTap;
  final GestureTapUpCallback? onSecondaryTapDown;
  final List<Widget> leading;
  final Widget content;
  final List<Widget> trailing;

  const GraphTile({
    super.key,
    this.onSecondaryTap,
    this.onSecondaryTapDown,
    this.leading = const <Widget>[],
    required this.content,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onSecondaryTap: onSecondaryTap,
      onSecondaryTapUp: onSecondaryTapDown,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                ...leading.expand((element) => [element, const SizedBox(width: 8.0)]),
                Expanded(
                  child: DefaultTextStyle.merge(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    child: content,
                  ),
                ),
              ],
            ),
          ),
          ...trailing.expand((element) => [element, const SizedBox(width: 8.0)]),
        ],
      ),
    );
  }
}

// - [ <Branch/Tag Icon> | <Branch/Tag Name> <| Is Origin> ] <Commit>   | <Date> | <Author> | <Commit>

class GitNode<T> {
  final String id;
  final String? parent;
  final T data;

  const GitNode({
    required this.id,
    this.parent,
    required this.data,
  });
}

class GitGraph<T> extends StatelessWidget {
  final List<GitNode<T>> nodes;
  final Widget Function(BuildContext context, T data) builder;

  const GitGraph({
    super.key,
    required this.nodes,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    var currentDepth = 0;
    final nodesDepth = <String, int>{};

    for (var i = 0; i < nodes.length; i++) {
      final prevNodes = nodes.take(i);
      final currentNode = nodes[i];

      final parents = prevNodes.where((element) => element.parent == currentNode.id).toList();
      if (parents.length > 1) currentDepth -= parents.length - 1;

      if (!nodesDepth.containsKey(currentNode.id)) {
        currentDepth += 1;
        nodesDepth[currentNode.id] = currentDepth;
      }
      if (currentNode.parent != null) {
        nodesDepth[currentNode.parent!] =
            min(nodesDepth[currentNode.parent!] ?? currentDepth, nodesDepth[currentNode.id]!);
      }
    }

    return ListView.builder(
      cacheExtent: 256.0,
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        final depth = nodesDepth[node.id] ?? 0;

        final parentDistance =
            nodes.skip(index).takeWhile((value) => value.id != node.parent).length;

        final child = ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 40.0,
          ),
          child: builder(context, node.data),
        );

        return CustomPaint(
          foregroundPainter: _LinePainter(
            color: colors.onBackground,
            shouldDrawLine: nodes.length - 1 != index,
            lineSpace: 24.0,
            targetHeightPos: parentDistance,
            targetWidthPos: nodesDepth[node.parent] ?? depth,
            widthPos: depth,
          ),
          child: Padding(
            padding: EdgeInsets.only(left: 24.0 * nodesDepth.values.max),
            child: child,
          ),
        );
      },
    );
  }
}

class _LinePainter extends CustomPainter {
  final Color color;
  final bool shouldDrawLine;
  final int widthPos;
  final int targetHeightPos;
  final int targetWidthPos;
  final double lineSpace;

  const _LinePainter({
    required this.color,
    required this.shouldDrawLine,
    required this.widthPos,
    required this.targetHeightPos,
    required this.targetWidthPos,
    required this.lineSpace,
  });

  double resolveDx(int width) => lineSpace * (width - 1) + lineSpace / 2;

  static const double _ballRadius = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final space = resolveDx(widthPos);

    final ballOffset = Offset(space, size.height / 2);
    const ballPadding = 2.0;

    if (shouldDrawLine && targetHeightPos > 0) {
      var dy = ballOffset.dy;
      var dx = resolveDx(widthPos);

      final path = Path()..moveTo(dx, dy += _ballRadius + ballPadding);

      if (targetWidthPos == widthPos) {}
      final effectiveTargetHeightPos = targetHeightPos + (targetWidthPos != widthPos ? -1 : 0);
      if (effectiveTargetHeightPos > 0) {
        path.lineTo(
            space, dy += size.height * effectiveTargetHeightPos - (_ballRadius + ballPadding) * 2);
      }

      if (targetWidthPos != widthPos) {
        final borderRadius = lineSpace / 2;
        final lineLength = size.height - (_ballRadius * 2) - (ballPadding * 2) - (borderRadius * 2);

        path
          ..lineTo(dx, dy += lineLength)
          ..arcToCenter(
            Offset(dx -= borderRadius, dy),
            borderRadius,
            0,
            90,
          )
          ..lineTo(dx = resolveDx(targetWidthPos) + borderRadius, dy += borderRadius)
          ..arcToCenter(
            Offset(dx, dy += borderRadius),
            borderRadius,
            180,
            90,
          );
      } else {}

      canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 2.5
            ..style = PaintingStyle.stroke);
    }

    _drawCircle(canvas, size);
  }

  void _drawCircle(Canvas canvas, Size size) {
    final dx = resolveDx(widthPos);

    canvas.drawCircle(
        Offset(dx, size.height / 2),
        _ballRadius,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

double degreesToRadians(double degrees) => degrees * (pi / 180);

extension on Path {
  void arcToCenter(Offset center, double radius, double startAngle, double sweepAngle) {
    arcTo(
      Rect.fromCircle(center: center, radius: radius),
      degreesToRadians(startAngle),
      degreesToRadians(sweepAngle),
      true,
    );
  }
}
