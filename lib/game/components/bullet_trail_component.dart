import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../flight_go_game.dart';

/// 子弹尾迹组件，为子弹添加拖尾效果
class BulletTrailComponent extends PositionComponent {
  final Color color;
  final double duration;
  final double initialSize;
  final double fadeFactor;
  final bool isPlayerBullet;
  
  // 当前存活时间
  double _timeAlive = 0;
  
  // 不透明度
  double _opacity = 1.0;
  
  // 当前大小
  double _currentSize;
  
  // 随机旋转
  final double _rotation;
  
  // 构造函数
  BulletTrailComponent({
    required Vector2 position,
    required this.initialSize,
    required this.color,
    this.duration = 0.4,
    this.fadeFactor = 1.2,
    this.isPlayerBullet = true,
  }) : 
    _currentSize = initialSize,
    _rotation = Random().nextDouble() * 2 * pi,
    super(
      position: position,
      size: Vector2.all(initialSize),
      anchor: Anchor.center,
      priority: -1,
    );
  
  @override
  void render(Canvas canvas) {
    try {
      // 保存当前画布状态
      canvas.save();
      
      // 设置原点为中心点
      final centerX = size.x / 2;
      final centerY = size.y / 2;
      
      // 应用旋转
      canvas.translate(centerX, centerY);
      canvas.rotate(_rotation);
      canvas.translate(-centerX, -centerY);
      
      // 创建径向渐变
      final gradient = RadialGradient(
        colors: [
          color.withOpacity(_opacity * 0.9),
          color.withOpacity(_opacity * 0.4),
          color.withOpacity(0),
        ],
        stops: const [0.0, 0.6, 1.0],
      );
      
      // 创建着色器
      final shader = gradient.createShader(
        Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: _currentSize / 2,
        ),
      );
      
      // 绘制圆形粒子
      final paint = Paint()
        ..shader = shader
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(centerX, centerY),
        _currentSize / 2,
        paint,
      );
      
      // 为玩家子弹添加额外的发光效果
      if (isPlayerBullet && _opacity > 0.4) {
        final glowPaint = Paint()
          ..color = color.withOpacity(_opacity * 0.2)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        
        canvas.drawCircle(
          Offset(centerX, centerY),
          _currentSize / 1.8,
          glowPaint,
        );
      }
      
      // 恢复画布状态
      canvas.restore();
    } catch (e) {
      debugPrint('Trail render error: $e');
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    try {
      // 更新存活时间
      _timeAlive += dt;
      
      // 计算不透明度，随时间线性减少
      _opacity = 1.0 - (_timeAlive / duration) * fadeFactor;
      
      // 更新大小，随时间增大
      _currentSize = initialSize * (1.0 + _timeAlive / duration * 0.8);
      
      // 更新组件大小
      size.setAll(_currentSize);
      
      // 如果不透明度降到0.05或以下，移除该组件
      if (_opacity <= 0.05) {
        removeFromParent();
      }
    } catch (e) {
      debugPrint('Trail update error: $e');
      removeFromParent();
    }
  }
} 