import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

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
        height: 20.0,
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
                children: children.expandIndexed<Widget>((index, child) sync* {
                  if (index > 0) yield VerticalDivider(width: 0.0, color: colors.onPrimary);

                  yield ChipGraphScope(
                    isLast: children.length == index + 1,
                    child: child,
                  );
                }).toList(),
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
    return Row(
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
  final GraphTile Function(BuildContext context, T data) builder;

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

    const tileHeight = 32.0;
    const leadingWidth = tileHeight / 2.0;

    return SingleChildScrollView(
      child: Column(
        children: nodes.mapIndexed((index, node) {
          final depth = nodesDepth[node.id] ?? 0;

          final parentDistance =
              nodes.skip(index).takeWhile((value) => value.id != node.parent).length;

          return Builder(builder: (context) {
            final tile = builder(context, node.data);

            final child = ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: tileHeight,
              ),
              child: tile,
            );

            return InkWell(
              onSecondaryTap: tile.onSecondaryTap,
              onSecondaryTapUp: tile.onSecondaryTapDown,
              child: CustomPaint(
                foregroundPainter: _LinePainter(
                  color: colors.onSurface,
                  shouldDrawLine: nodes.length - 1 != index,
                  lineSpace: leadingWidth,
                  targetHeightPosition: parentDistance,
                  targetWidthPosition: nodesDepth[node.parent] ?? depth,
                  widthPosition: depth,
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: leadingWidth * nodesDepth.values.max + 4.0),
                  child: child,
                ),
              ),
            );
          });
        }).toList(),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final Color color;
  final bool shouldDrawLine;
  final int widthPosition;
  final int targetHeightPosition;
  final int targetWidthPosition;
  final double lineSpace;

  const _LinePainter({
    required this.color,
    required this.shouldDrawLine,
    required this.widthPosition,
    required this.targetHeightPosition,
    required this.targetWidthPosition,
    required this.lineSpace,
  });

  double resolveDx(int width) => lineSpace * (width - 1) + lineSpace / 2;

  static const double _ballRadius = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final space = resolveDx(widthPosition);

    final ballOffset = Offset(space, size.height / 2);
    const ballPadding = 2.0;

    if (shouldDrawLine && targetHeightPosition > 0) {
      var dy = ballOffset.dy;
      var dx = resolveDx(widthPosition);

      final path = Path()..moveTo(dx, dy += _ballRadius + ballPadding);

      if (targetWidthPosition == widthPosition) {}
      final effectiveTargetHeightPos =
          targetHeightPosition + (targetWidthPosition != widthPosition ? -1 : 0);
      if (effectiveTargetHeightPos > 0) {
        path.lineTo(
            space, dy += size.height * effectiveTargetHeightPos - (_ballRadius + ballPadding) * 2);
      }

      if (targetWidthPosition != widthPosition) {
        final borderRadius = lineSpace / 2;
        final lineLength = size.height - (_ballRadius * 2) - (ballPadding * 2) - (borderRadius * 2);

        path
          ..lineTo(dx, dy += lineLength)
          ..arcToCenter(Offset(dx -= borderRadius, dy), borderRadius, 0, 90)
          ..lineTo(dx = resolveDx(targetWidthPosition) + borderRadius, dy += borderRadius)
          ..arcToCenter(Offset(dx, dy += borderRadius), borderRadius, 180, 90);
      } else {}

      canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke);
    }

    _drawCircle(canvas, size);
  }

  void _drawCircle(Canvas canvas, Size size) {
    final dx = resolveDx(widthPosition);

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
