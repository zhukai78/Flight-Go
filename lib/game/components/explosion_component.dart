import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flight_go_game.dart';

/// 爆炸效果组件
class ExplosionComponent extends PositionComponent {
  // 爆炸持续时间
  final double duration;
  
  // 爆炸颜色
  final Color primaryColor;
  final Color secondaryColor;
  
  // 爆炸初始大小
  final double initialRadius;
  
  // 爆炸最大大小
  final double maxRadius;
  
  // 爆炸波动频率
  final double waveFrequency;
  
  // 爆炸波动幅度
  final double waveAmplitude;
  
  // 是否添加火花效果
  final bool addSparks;
  
  // 随机数生成器
  final _random = Random();
  
  // 当前半径
  double _currentRadius;
  
  // 已经持续的时间
  double _elapsedTime = 0;
  
  // 不透明度
  double _opacity = 1.0;
  
  // 旋转角度
  double _rotation = 0.0;
  
  // 火花粒子列表
  final List<_SparkParticle> _sparks = [];
  
  // 构造函数
  ExplosionComponent({
    required Vector2 position,
    this.duration = 0.8,
    this.initialRadius = 15.0,
    this.maxRadius = 40.0,
    this.primaryColor = Colors.orange,
    this.secondaryColor = Colors.yellow,
    this.waveFrequency = 15.0,
    this.waveAmplitude = 0.15,
    this.addSparks = true,
  }) : 
    _currentRadius = initialRadius,
    super(
      position: position,
      size: Vector2.all(initialRadius * 2),
      anchor: Anchor.center,
      priority: 2, // 较高的优先级，确保爆炸在最前面显示
    ) {
    // 初始随机旋转
    _rotation = _random.nextDouble() * pi * 2;
    
    // 如果需要添加火花效果
    if (addSparks) {
      // 创建随机数量的火花粒子，但不要太多
      final sparkCount = 5 + _random.nextInt(6); // 减少火花数量，从8-16降至5-10
      for (int i = 0; i < sparkCount; i++) {
        // 随机角度和速度
        final angle = _random.nextDouble() * pi * 2;
        final speed = 50.0 + _random.nextDouble() * 120.0; // 降低一些速度上限
        
        // 随机存活时间，但保持较短
        final sparkDuration = duration * 0.3 + _random.nextDouble() * duration * 0.5;
        
        // 随机大小
        final size = 1.0 + _random.nextDouble() * 2.5; // 稍微减小火花大小范围
        
        // 随机颜色
        final sparkColor = _random.nextBool() ? primaryColor : secondaryColor;
        
        // 创建火花粒子
        _sparks.add(_SparkParticle(
          initialPosition: Vector2.zero(),
          angle: angle,
          speed: speed,
          size: size,
          duration: sparkDuration,
          color: sparkColor,
        ));
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    try {
      // 保存画布状态
      canvas.save();
      
      // 设置位移到中心
      final centerX = _currentRadius;
      final centerY = _currentRadius;
      canvas.translate(centerX, centerY);
      
      // 绘制爆炸主体
      // 外层光晕
      final outerGlow = Paint()
        ..color = primaryColor.withAlpha((255 * _opacity * 0.4).toInt())
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
      canvas.drawCircle(
        Offset.zero,
        _currentRadius * 1.2,
        outerGlow,
      );
      
      // 中层爆炸
      final middleGlow = Paint()
        ..shader = RadialGradient(
          colors: [
            secondaryColor.withOpacity(_opacity * 0.8),
            primaryColor.withOpacity(_opacity * 0.6),
            primaryColor.withOpacity(_opacity * 0.2),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: Offset.zero,
            radius: _currentRadius,
          ),
        );
      
      canvas.drawCircle(
        Offset.zero,
        _currentRadius,
        middleGlow,
      );
      
      // 内部亮点
      final innerGlow = Paint()
        ..color = Colors.white.withOpacity(_opacity * 0.9)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset.zero,
        _currentRadius * 0.4,
        innerGlow,
      );
      
      // 绘制火花粒子
      if (addSparks) {
        for (final spark in _sparks) {
          spark.render(canvas);
        }
      }
      
      // 恢复画布状态
      canvas.restore();
    } catch (e) {
      debugPrint('Explosion render error: $e');
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    try {
      // 更新已经持续的时间
      _elapsedTime += dt;
      
      // 计算进度（0.0 到 1.0）
      final progress = _elapsedTime / duration;
      
      // 更新不透明度，爆炸初期快速增亮，后期缓慢淡出
      if (progress < 0.2) {
        // 初期快速增亮
        _opacity = progress / 0.2;
      } else {
        // 后期缓慢淡出
        _opacity = 1.0 - ((progress - 0.2) / 0.8);
      }
      
      // 更新旋转
      _rotation += dt * 1.5;
      
      // 更新半径，添加波动效果
      final radiusProgress = min(1.0, progress * 1.5);
      final baseRadius = initialRadius + (maxRadius - initialRadius) * radiusProgress;
      
      // 添加波动效果
      final waveFactor = sin(_elapsedTime * waveFrequency) * waveAmplitude;
      _currentRadius = baseRadius * (1.0 + waveFactor);
      
      // 更新组件大小
      size.setAll(_currentRadius * 2);
      
      // 更新火花粒子
      if (addSparks) {
        for (final spark in _sparks) {
          spark.update(dt, progress);
        }
      }
      
      // 如果持续时间结束，移除组件
      if (_elapsedTime >= duration) {
        removeFromParent();
      }
    } catch (e) {
      debugPrint('Explosion update error: $e');
      removeFromParent();
    }
  }
}

/// 爆炸火花粒子，用于创建爆炸的飞散效果
class _SparkParticle {
  // 粒子位置
  final Vector2 position;
  
  // 初始位置
  final Vector2 initialPosition;
  
  // 运动角度
  final double angle;
  
  // 运动速度
  final double speed;
  
  // 粒子大小
  final double size;
  
  // 粒子颜色
  final Color color;
  
  // 粒子持续时间
  final double duration;
  
  // 已经持续的时间
  double _elapsedTime = 0;
  
  // 不透明度
  double _opacity = 1.0;
  
  // 随机数生成器
  final _random = Random();
  
  // 构造函数
  _SparkParticle({
    required this.initialPosition,
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.duration,
  }) : position = initialPosition.clone();
  
  // 渲染粒子
  void render(Canvas canvas) {
    // 创建画笔
    final paint = Paint()
      ..color = color.withOpacity(_opacity)
      ..style = PaintingStyle.fill;
    
    // 绘制火花粒子
    canvas.drawCircle(
      Offset(position.x, position.y),
      size,
      paint,
    );
    
    // 为较大的火花添加光晕
    if (size > 2.0) {
      final glowPaint = Paint()
        ..color = color.withOpacity(_opacity * 0.5)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      
      canvas.drawCircle(
        Offset(position.x, position.y),
        size * 1.8,
        glowPaint,
      );
    }
  }
  
  // 更新粒子
  void update(double dt, double explosionProgress) {
    // 更新已经持续的时间
    _elapsedTime += dt;
    
    // 计算进度（0.0 到 1.0）
    final progress = _elapsedTime / duration;
    
    // 更新不透明度
    _opacity = 1.0 - progress;
    
    // 更新位置，加入一点随机抖动
    final displacement = Vector2(
      cos(angle) * speed * dt,
      sin(angle) * speed * dt,
    );
    
    // 添加一点随机抖动
    displacement.x += (_random.nextDouble() - 0.5) * 2.0;
    displacement.y += (_random.nextDouble() - 0.5) * 2.0;
    
    // 更新位置
    position.add(displacement);
    
    // 随着爆炸进展，减缓火花速度
    if (explosionProgress > 0.5) {
      final slowdownFactor = 1.0 - ((explosionProgress - 0.5) / 0.5) * 0.8;
      position.x *= slowdownFactor;
      position.y *= slowdownFactor;
    }
  }
} 