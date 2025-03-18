import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 引擎火焰效果组件
class EngineFlameComponent extends PositionComponent {
  // 火焰颜色
  final Color baseColor;
  
  // 火焰强度
  final double intensity;
  
  // 火焰动画计时器
  double _animationTime = 0;
  
  // 随机数生成器
  final Random _random = Random();
  
  // 火焰形状随机抖动
  double _flickerOffset = 0;
  
  EngineFlameComponent({
    required Vector2 position,
    required Vector2 size,
    this.baseColor = Colors.blue,
    this.intensity = 1.0,
  }) : super(
    position: position,
    size: size,
    anchor: Anchor.topCenter,
  );
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // 基本火焰
    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    
    // 外部火焰
    final outerPaint = Paint()
      ..color = baseColor.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    // 内部亮色火焰
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    // 绘制外部火焰
    final outerPath = Path()
      ..moveTo(0, 0)
      ..lineTo(-size.x / 2 - _flickerOffset, size.y * 0.6)
      ..lineTo(-size.x / 3, size.y * 0.8)
      ..lineTo(-size.x / 6, size.y * 0.6 + _flickerOffset)
      ..lineTo(0, size.y)
      ..lineTo(size.x / 6, size.y * 0.6 + _flickerOffset)
      ..lineTo(size.x / 3, size.y * 0.8)
      ..lineTo(size.x / 2 + _flickerOffset, size.y * 0.6)
      ..lineTo(0, 0)
      ..close();
    
    canvas.drawPath(outerPath, outerPaint);
    
    // 绘制基本火焰
    final basePath = Path()
      ..moveTo(0, 0)
      ..lineTo(-size.x / 3, size.y * 0.7)
      ..lineTo(-size.x / 6, size.y * 0.6)
      ..lineTo(0, size.y * 0.9)
      ..lineTo(size.x / 6, size.y * 0.6)
      ..lineTo(size.x / 3, size.y * 0.7)
      ..lineTo(0, 0)
      ..close();
    
    canvas.drawPath(basePath, basePaint);
    
    // 绘制内部火焰
    final innerPath = Path()
      ..moveTo(0, 0)
      ..lineTo(-size.x / 6, size.y * 0.5)
      ..lineTo(0, size.y * 0.7)
      ..lineTo(size.x / 6, size.y * 0.5)
      ..lineTo(0, 0)
      ..close();
    
    canvas.drawPath(innerPath, innerPaint);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 更新动画时间
    _animationTime += dt * 10;
    
    // 更新火焰形状抖动
    _flickerOffset = sin(_animationTime) * size.x * 0.1 + _random.nextDouble() * size.x * 0.05;
  }
} 