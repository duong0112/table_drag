import 'package:flutter/material.dart';

// ignore: must_be_immutable
class TextCustom extends StatelessWidget {
  TextCustom(this.text,{
    Key? key,
    this.tooltip,
    this.maxLines = 100,
    this.style,
    this.textAlign = TextAlign.left,
    this.preferBelow = true,
    this.showTooltip = true,
    this.verticalOffset,
  }) : super(key: key){
    style ??= const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black);
  }

  /// Text to be displayed
  String text;

  /// Specifiy the text to be displayed for the tooltip (when text is overflowing)
  /// If not specified, the tooltip text will be the original text displayed.
  String? tooltip;

  bool showTooltip;

  /// maxLine for the text to be displayed in
  int maxLines;

  /// Style of the text
  TextStyle? style;

  /// Text alignment
  TextAlign textAlign;

  /// Whether the tooltip defaults to being displayed below the widget.
  final bool? preferBelow;

  /// Tooltip verticalOffset
  final double? verticalOffset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, size) {
        // Creation of a TextSpan
        TextSpan span = TextSpan(
          text: text,
          style: style,
        );

        // Creation of a TextPainter which will be used to determine whether there is an overflow or not (in fact when max lines will be exceeded)
        TextPainter tp = TextPainter(
          maxLines: maxLines,
          textScaleFactor: MediaQuery.of(context).textScaleFactor, // to be accurate when the device scales font sizes up (or down)
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
          text: span,
        );

        // The TextPainter is linked to the layout
        tp.layout(maxWidth: size.maxWidth);

        // Then we get back the overflow info from the TextPainter "didExceedMaxLines" property
        bool isOnOverflow = tp.didExceedMaxLines;
        return Tooltip(
          message: isOnOverflow && showTooltip ? (tooltip??text) : '',
          verticalOffset: verticalOffset,
          preferBelow: preferBelow,
          child: Text.rich(
            span,
            overflow: TextOverflow.ellipsis,
            maxLines: maxLines,
            textAlign: textAlign,
            style: style,
          ),
        );
      },
    );
  }
}
