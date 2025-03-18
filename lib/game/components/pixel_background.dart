import 'package:flutter/material.dart';

/// 像素网格背景
///
/// 在屏幕上绘制像素风格的网格背景，增强游戏的复古像素风格感
class PixelBackground extends StatelessWidget {
  final Color gridColor;
  final double gridSize;
  final double gridOpacity;
  
  const PixelBackground({
    super.key,
    this.gridColor = Colors.blue,
    this.gridSize = 20.0,
    this.gridOpacity = 0.15,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PixelGridPainter(
        gridColor: gridColor,
        gridSize: gridSize,
        gridOpacity: gridOpacity,
      ),
      child: Container(), // 空容器，让CustomPaint填充整个区域
    );
  }
}

/// 绘制像素网格的自定义画笔
class PixelGridPainter extends CustomPainter {
  final Color gridColor;
  final double gridSize;
  final double gridOpacity;
  
  PixelGridPainter({
    required this.gridColor,
    required this.gridSize,
    required this.gridOpacity,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withOpacity(gridOpacity)
      ..strokeWidth = 1.0;
    
    // 绘制水平线
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    // 绘制垂直线
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // 添加一些随机"像素"，增强视觉效果
    final pixelPaint = Paint()
      ..color = gridColor.withOpacity(gridOpacity * 2);
    
    // 使用伪随机方式生成一些像素点
    for (int i = 0; i < 50; i++) {
      final x = ((i * 13) % (size.width ~/ gridSize)) * gridSize;
      final y = ((i * 17) % (size.height ~/ gridSize)) * gridSize;
      
      canvas.drawRect(
        Rect.fromLTWH(x, y, gridSize, gridSize),
        pixelPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(PixelGridPainter oldDelegate) {
    return oldDelegate.gridColor != gridColor ||
           oldDelegate.gridSize != gridSize ||
           oldDelegate.gridOpacity != gridOpacity;
  }
} 