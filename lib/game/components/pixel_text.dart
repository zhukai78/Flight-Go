import 'package:flutter/material.dart';

/// 像素化文本小部件
/// 
/// 这个小部件提供了像素游戏风格的文本渲染。
/// 它通过特殊的装饰和间距创建一个像素化的外观。
class PixelText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color textColor;
  final Color shadowColor;
  final bool isTitle;
  
  const PixelText({
    super.key,
    required this.text,
    this.fontSize = 24,
    this.textColor = Colors.white,
    this.shadowColor = Colors.blue,
    this.isTitle = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTitle ? 16.0 : 8.0,
        vertical: isTitle ? 8.0 : 4.0,
      ),
      decoration: isTitle 
        ? BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            border: Border.all(
              color: shadowColor,
              width: 4.0,
              style: BorderStyle.solid,
            ),
          )
        : null,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 2.0, // 增加字母间距，增强像素感
          height: 1.2, // 减小行高，使文本更紧凑
          shadows: [
            Shadow(
              blurRadius: 0.0, // 无模糊的阴影增强像素感
              color: shadowColor,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// 像素化按钮
/// 
/// 提供带像素风格的按钮
class PixelButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color color;
  final double width;
  
  const PixelButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.color = Colors.blue,
    this.width = 220.0,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        // 像素风格的边框和阴影
        border: Border.all(
          color: color.withOpacity(0.7), 
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 0, // 无模糊
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            color: color,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20.0,
                  ),
                  const SizedBox(width: 8.0),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 