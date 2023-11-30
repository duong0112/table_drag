import 'dart:core';
import 'dart:ui';
import 'package:flutter/material.dart';

enum MorePopupDirection {
  // top,
  bottom,
  left,
  right,
}

class MenuContext {
  late double _popupWidth;
  late double _popupHeight;

  double arrowHeight = 10.0;
  bool _isDownArrow = true;
  bool isShowArrow;

  MorePopupDirection direction;

  double parentPaddingRight;
  double parentPaddingLeft;

  bool _isVisible = false;

  late Widget childWidget;

  late OverlayEntry _entry;
  late Offset _offset;
  late Rect _showRect;

  VoidCallback? dismissCallback;

  late Size _screenSize;

  BuildContext context;
  late Color _backgroundColor;

  late BorderRadius _borderRadius;
  late EdgeInsetsGeometry _padding;

  MenuContext(
      this.context,
      {Key? key,
        double? height,
        double? width,
        this.isShowArrow = true,
        this.parentPaddingRight = 0,
        this.parentPaddingLeft = 0,
        VoidCallback? onDismiss,
        this.direction = MorePopupDirection.bottom,
        Color? backgroundColor,
        Widget? childWidget,
        BorderRadius? borderRadius,
        EdgeInsetsGeometry? padding}) {
    dismissCallback = onDismiss;
    _popupHeight = height ?? 200;
    _popupWidth = width ?? 200;
    this.childWidget = childWidget!;
    _backgroundColor = backgroundColor ?? const Color(0xFFFFA500);
    _borderRadius = borderRadius ?? BorderRadius.circular(10.0);
    _padding = padding ?? const EdgeInsets.all(4.0);
  }

  /// Shows a popup near a widget with key [widgetKey] or [rect].
  void show({Rect? rect, GlobalKey? widgetKey}) {
    if (rect == null && widgetKey == null) {
      return;
    }

    _showRect = rect ?? _getWidgetGlobalRect(widgetKey!);
    _screenSize = window.physicalSize / window.devicePixelRatio;

    _calculatePosition(context);

    _entry = OverlayEntry(builder: (context) {
      return buildPopupLayout(_offset);
    });

    Overlay.of(context).insert(_entry);
    _isVisible = true;
  }

  void _calculatePosition(BuildContext context) {
    _offset = _calculateOffset(context);
  }

  /// Returns globalRect of widget with key [key]
  Rect _getWidgetGlobalRect(GlobalKey key) {
    RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
    var offset = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
        offset.dx, offset.dy, renderBox.size.width, renderBox.size.height);
  }

  /// Returns calculated widget offset using [context]
  Offset _calculateOffset(BuildContext context) {
    double dx = _showRect.left + _showRect.width / 2.0 - _popupWidth / 2.0;
    if (dx < 10.0) {
      dx = 10.0;
    }

    if (dx + _popupWidth > _screenSize.width && dx > 10.0) {
      double tempDx = _screenSize.width - _popupWidth - 10;
      if (tempDx > 10) dx = tempDx;
    }

    double dy = _showRect.top - _popupHeight;
    if (dy <= MediaQuery.of(context).padding.top + 10) {
      // not enough space above, show popup under the widget.
      dy = arrowHeight + _showRect.height + _showRect.top;
      _isDownArrow = false;
    } else {
      dy -= arrowHeight;
      _isDownArrow = true;
    }

    return Offset(dx, dy);
  }

  /// Builds Layout of popup for specific [offset]
  LayoutBuilder buildPopupLayout(Offset offset) {
    double leftPosition=offset.dx - parentPaddingRight;
    double topPosition=offset.dy;
    switch(direction){
    // case MorePopupDirection.top:
    //   leftPosition=offset.dx - parentPaddingRight;
    //   topPosition=offset.dy;
    //   break;
      case MorePopupDirection.bottom:
        leftPosition=offset.dx - parentPaddingRight;
        topPosition= offset.dy;
        break;
      case MorePopupDirection.left:
        leftPosition = offset.dx -_showRect.width - parentPaddingRight;
        topPosition = offset.dy - _showRect.height;
        break;
      case MorePopupDirection.right:
        leftPosition = offset.dx + _showRect.width + 8 - parentPaddingRight;
        topPosition = offset.dy - _showRect.height;
        break;
    }
    return LayoutBuilder(builder: (context, constraints) {
      return InkWell(
        onTap: () {
          dismiss();
        },
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: <Widget>[
              // popup content
              Positioned(
                left: leftPosition,
                top: topPosition,
                child: Container(
                    padding: _padding,
                    width: _popupWidth,
                    height: _popupHeight,
                    decoration: BoxDecoration(
                        color: _backgroundColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            spreadRadius: 0,
                            blurRadius: 19,
                            offset: const Offset(0, 5),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 0,
                            blurRadius: 56,
                            offset: const Offset(0, 12),
                          ),
                        ],
                        borderRadius: _borderRadius),
                    child: SingleChildScrollView(
                        child: childWidget
                    )
                ),
              ),
              // triangle arrow
              Visibility(
                visible: isShowArrow,
                child: Positioned(
                  left: (_showRect.left + _showRect.width / 2.0 - 8) - parentPaddingRight,
                  top: _isDownArrow
                      ? offset.dy + _popupHeight
                      : offset.dy - arrowHeight,
                  child: CustomPaint(
                    size: Size(16.0, arrowHeight),
                    painter: TrianglePainter(
                        isDownArrow: _isDownArrow, color: _backgroundColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Dismisses the popup
  void dismiss() {
    if (!_isVisible) {
      return;
    }
    _entry.remove();
    _isVisible = false;
    dismissCallback?.call();
  }
}

/// [TrianglePainter] is custom painter for drawing a triangle for popup
/// to point specific widget
class TrianglePainter extends CustomPainter {
  bool isDownArrow;
  Color color;

  TrianglePainter({this.isDownArrow = true, required this.color});

  /// Draws the triangle of specific [size] on [canvas]
  @override
  void paint(Canvas canvas, Size size) {
    Path path = Path();
    Paint paint = Paint();
    paint.strokeWidth = 2.0;
    paint.color = color;
    paint.style = PaintingStyle.fill;

    if (isDownArrow) {
      path.moveTo(0.0, -1.0);
      path.lineTo(size.width, -1.0);
      path.lineTo(size.width / 2.0, size.height);
    } else {
      path.moveTo(size.width / 2.0, 0.0);
      path.lineTo(0.0, size.height + 1);
      path.lineTo(size.width, size.height + 1);
    }

    canvas.drawPath(path, paint);
  }

  /// Specifies to redraw for [customPainter]
  @override
  bool shouldRepaint(CustomPainter customPainter) {
    return true;
  }
}