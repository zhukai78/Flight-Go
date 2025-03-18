import 'package:flutter/material.dart';

/// 像素化图标小部件
/// 
/// 这个组件创建一个像素风格的图标，通过使用网格和方块拼接而成。
class PixelIcon extends StatelessWidget {
  final IconType iconType;
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  
  const PixelIcon({
    super.key,
    required this.iconType,
    this.size = 64.0,
    this.primaryColor = Colors.white,
    this.secondaryColor = Colors.blue,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border.all(
          color: secondaryColor.withOpacity(0.7),
          width: 2,
        ),
      ),
      child: CustomPaint(
        painter: PixelIconPainter(
          iconType: iconType,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
        ),
      ),
    );
  }
}

/// 像素图标类型
enum IconType {
  rocket,
  star,
  heart,
  shield,
  coin,
}

/// 像素图标绘制器
class PixelIconPainter extends CustomPainter {
  final IconType iconType;
  final Color primaryColor;
  final Color secondaryColor;
  
  PixelIconPainter({
    required this.iconType,
    required this.primaryColor,
    required this.secondaryColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final pixelSize = size.width / 8; // 将图标划分为8x8网格
    
    // 根据图标类型绘制不同的像素图案
    switch (iconType) {
      case IconType.rocket:
        _drawRocket(canvas, size, pixelSize);
        break;
      case IconType.star:
        _drawStar(canvas, size, pixelSize);
        break;
      case IconType.heart:
        _drawHeart(canvas, size, pixelSize);
        break;
      case IconType.shield:
        _drawShield(canvas, size, pixelSize);
        break;
      case IconType.coin:
        _drawCoin(canvas, size, pixelSize);
        break;
    }
  }
  
  // 绘制火箭图标
  void _drawRocket(Canvas canvas, Size size, double pixelSize) {
    final rocketPattern = [
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 1, 1, 2, 2, 1, 1, 0],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [1, 2, 2, 2, 2, 2, 2, 1],
      [1, 1, 0, 2, 2, 0, 1, 1],
      [0, 0, 0, 1, 1, 0, 0, 0],
    ];
    _drawPixelPattern(canvas, size, pixelSize, rocketPattern);
  }
  
  // 绘制星星图标
  void _drawStar(Canvas canvas, Size size, double pixelSize) {
    final starPattern = [
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [1, 1, 2, 2, 2, 2, 1, 1],
      [1, 2, 2, 2, 2, 2, 2, 1],
      [0, 1, 1, 2, 2, 1, 1, 0],
      [0, 0, 1, 1, 1, 1, 0, 0],
      [0, 1, 0, 0, 0, 0, 1, 0],
    ];
    _drawPixelPattern(canvas, size, pixelSize, starPattern);
  }
  
  // 绘制心形图标
  void _drawHeart(Canvas canvas, Size size, double pixelSize) {
    final heartPattern = [
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 1, 1, 0, 0, 1, 1, 0],
      [1, 2, 2, 1, 1, 2, 2, 1],
      [1, 2, 2, 2, 2, 2, 2, 1],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
    ];
    _drawPixelPattern(canvas, size, pixelSize, heartPattern);
  }
  
  // 绘制盾牌图标
  void _drawShield(Canvas canvas, Size size, double pixelSize) {
    final shieldPattern = [
      [0, 0, 1, 1, 1, 1, 0, 0],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [1, 2, 2, 1, 1, 2, 2, 1],
      [1, 2, 1, 2, 2, 1, 2, 1],
      [1, 2, 2, 2, 2, 2, 2, 1],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
    ];
    _drawPixelPattern(canvas, size, pixelSize, shieldPattern);
  }
  
  // 绘制金币图标
  void _drawCoin(Canvas canvas, Size size, double pixelSize) {
    final coinPattern = [
      [0, 0, 1, 1, 1, 1, 0, 0],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [1, 2, 2, 1, 1, 2, 2, 1],
      [1, 2, 1, 2, 2, 1, 2, 1],
      [1, 2, 1, 2, 2, 1, 2, 1],
      [1, 2, 2, 1, 1, 2, 2, 1],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [0, 0, 1, 1, 1, 1, 0, 0],
    ];
    _drawPixelPattern(canvas, size, pixelSize, coinPattern);
  }
  
  // 绘制像素图案
  void _drawPixelPattern(Canvas canvas, Size size, double pixelSize, List<List<int>> pattern) {
    final paint = Paint();
    
    for (int y = 0; y < pattern.length; y++) {
      for (int x = 0; x < pattern[y].length; x++) {
        // 获取当前像素的值
        final pixelValue = pattern[y][x];
        
        // 根据像素值设置颜色
        if (pixelValue == 1) {
          paint.color = primaryColor;
        } else if (pixelValue == 2) {
          paint.color = secondaryColor;
        } else {
          continue; // 跳过值为0的像素（透明）
        }
        
        // 绘制像素
        canvas.drawRect(
          Rect.fromLTWH(
            x * pixelSize,
            y * pixelSize,
            pixelSize,
            pixelSize,
          ),
          paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(PixelIconPainter oldDelegate) {
    return oldDelegate.iconType != iconType ||
           oldDelegate.primaryColor != primaryColor ||
           oldDelegate.secondaryColor != secondaryColor;
  }
} 