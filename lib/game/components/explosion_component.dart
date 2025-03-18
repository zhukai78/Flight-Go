import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 爆炸效果组件
class ExplosionComponent extends PositionComponent {
  // 颜色
  final Color primaryColor;
  final Color secondaryColor;
  
  // 半径
  final double initialRadius;
  final double maxRadius;
  double _currentRadius;
  
  // 持续时间
  final double duration;
  double _timeAlive = 0;
  
  // 不透明度
  double _opacity = 1.0;
  
  // 像素大小
  final double _pixelSize;
  
  // 随机数生成器
  final Random _random = Random();
  
  // 预计算的像素点
  final List<Map<String, dynamic>> _pixelData = [];
  
  // 动画相关变量
  double _elapsedTime = 0.0;
  final double waveFrequency = 5.0;
  final double waveAmplitude = 0.2;
  
  // 错误状态标记
  bool _hasRenderError = false;
  DateTime _lastErrorTime = DateTime.now();
  int _errorCount = 0;
  
  // 安全设置透明度的辅助方法
  Color withSafeOpacity(Color baseColor, double opacity) {
    // 确保透明度在有效范围内 (0.0-1.0)
    final safeOpacity = opacity.clamp(0.0, 1.0);
    try {
      return baseColor.withOpacity(safeOpacity);
    } catch (e) {
      // 如果颜色处理出错，返回一个安全的默认颜色
      return Colors.white.withOpacity(safeOpacity);
    }
  }
  
  ExplosionComponent({
    required Vector2 position,
    required this.primaryColor,
    required this.secondaryColor,
    required this.initialRadius,
    required this.maxRadius,
    this.duration = 0.8,
  }) : 
    _currentRadius = initialRadius,
    _pixelSize = initialRadius / 10, // 像素大小固定为初始半径的1/10
    super(
      position: position,
      anchor: Anchor.center,
    ) {
    // 预计算像素点位置和颜色 - 减少每帧重新计算的开销
    // 这样可以确保爆炸的形状在整个生命周期保持一致，减少闪烁
    _precomputePixelData();
  }
  
  // 预计算像素数据
  void _precomputePixelData() {
    // 创建足够多的像素点以填充最大半径
    final int pixelCount = (maxRadius / _pixelSize * 2).ceil();
    
    // 创建爆炸中的像素点
    for (int i = 0; i < pixelCount * 2; i++) {
      // 使用固定种子生成随机位置，确保一致性
      final angle = _random.nextDouble() * 2 * pi;
      final distance = _random.nextDouble() * maxRadius;
      
      // 计算像素位置
      final x = cos(angle) * distance;
      final y = sin(angle) * distance;
      
      // 确定颜色 - 根据离中心的距离
      final normalizedDistance = distance / maxRadius;
      final useSecondaryColor = _random.nextDouble() < 0.3 || normalizedDistance > 0.7;
      
      _pixelData.add({
        'x': x,
        'y': y,
        'distance': distance,
        'color': useSecondaryColor ? secondaryColor : primaryColor,
        'size': _pixelSize * (1.0 + _random.nextDouble() * 0.5),
      });
    }
  }
  
  @override
  void render(Canvas canvas) {
    // 如果有之前的渲染错误，使用简化渲染
    if (_hasRenderError) {
      _renderSimplified(canvas);
      return;
    }
    
    try {
      // 中心点
      final centerX = size.x / 2;
      final centerY = size.y / 2;
      
      // 保存画布状态
      canvas.save();
      canvas.translate(centerX, centerY);
      
      // 主画笔
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = false; // 关闭抗锯齿，减少性能开销
      
      // 计算爆炸比例 (当前半径与最大半径的比值)
      final expansionRatio = _currentRadius / maxRadius;
      
      // 绘制爆炸的像素，限制单次渲染的像素数量
      final maxPixelsPerFrame = 100; // 限制每帧渲染的最大像素数
      int pixelCount = 0;
      
      for (final pixelData in _pixelData) {
        // 限制每帧渲染的像素数量
        if (pixelCount >= maxPixelsPerFrame) break;
        
        final distance = pixelData['distance'] as double;
        
        // 只绘制在当前半径范围内的像素
        if (distance <= _currentRadius) {
          pixelCount++;
          
          // 计算像素不透明度，离中心越远越透明
          final distanceRatio = distance / _currentRadius;
          final pixelOpacity = (_opacity * (1.0 - distanceRatio * 0.5)).clamp(0.0, 1.0);
          
          // 设置颜色和不透明度
          paint.color = withSafeOpacity(pixelData['color'] as Color, pixelOpacity);
          
          // 获取像素大小
          final pixelSize = pixelData['size'] as double;
          
          // 计算位置，考虑爆炸扩张
          final x = (pixelData['x'] as double) * expansionRatio;
          final y = (pixelData['y'] as double) * expansionRatio;
          
          // 绘制像素方块
          canvas.drawRect(
            Rect.fromLTWH(
              x - pixelSize / 2,
              y - pixelSize / 2,
              pixelSize,
              pixelSize,
            ),
            paint,
          );
        }
      }
      
      // 恢复画布状态
      canvas.restore();
    } catch (e) {
      _errorCount++;
      // 记录错误，但限制频率
      final now = DateTime.now();
      if (now.difference(_lastErrorTime).inSeconds > 5) {
        _lastErrorTime = now;
        debugPrint('爆炸效果渲染错误: $e');
      }
      
      if (_errorCount > 3) {
        _hasRenderError = true;
      }
      
      // 尝试恢复画布状态
      try {
        canvas.restore();
      } catch (_) {
        // 忽略恢复失败
      }
      
      // 使用简化渲染
      _renderSimplified(canvas);
    }
  }
  
  // 简化版渲染，在出错时使用
  void _renderSimplified(Canvas canvas) {
    try {
      // 安全设置颜色
      final safeOpacity = _opacity.clamp(0.0, 1.0);
      final simplePaint = Paint()
        ..color = Colors.orange.withOpacity(safeOpacity)
        ..style = PaintingStyle.fill;
      
      // 简单绘制一个圆形
      canvas.drawCircle(
        Offset(position.x, position.y),
        _currentRadius,
        simplePaint
      );
    } catch (_) {
      // 忽略所有错误
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 更新存活时间和动画时间
    _timeAlive += dt;
    _elapsedTime += dt;
    
    // 检查是否应该移除
    if (_timeAlive >= duration) {
      removeFromParent();
      return;
    }
    
    // 计算生命周期比例
    final lifeRatio = _timeAlive / duration;
    
    // 更新不透明度 - 使用平滑的渐变式淡出
    _opacity = 1.0 - (lifeRatio * lifeRatio);
    
    // 更新半径 - 快速扩张然后减速
    final expansionCurve = lifeRatio < 0.3 
        ? lifeRatio / 0.3  // 前30%时间快速扩张到最大
        : 1.0;  // 之后保持最大
    
    _currentRadius = initialRadius + (maxRadius - initialRadius) * expansionCurve;
    
    // 更新组件尺寸以匹配当前半径
    size = Vector2.all(_currentRadius * 2);
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
  
  // 渲染错误标记
  bool _hasRenderError = false;
  
  // 安全设置透明度的辅助方法
  Color withSafeOpacity(Color baseColor, double opacity) {
    // 确保透明度在有效范围内 (0.0-1.0)
    final safeOpacity = opacity.clamp(0.0, 1.0);
    try {
      return baseColor.withOpacity(safeOpacity);
    } catch (e) {
      // 如果颜色处理出错，返回一个安全的默认颜色
      return Colors.white.withOpacity(safeOpacity);
    }
  }
  
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
    // 如果之前出现过错误，使用简化渲染
    if (_hasRenderError) {
      _renderSimplified(canvas);
      return;
    }
    
    try {
      // 确保透明度在有效范围内
      final safeOpacity = _opacity.clamp(0.0, 1.0);
      
      // 创建画笔
      final paint = Paint()
        ..color = withSafeOpacity(color, safeOpacity)
        ..style = PaintingStyle.fill;
      
      // 绘制像素风格的火花粒子
      // 使用小方块代替圆形
      final pixelSize = size * 0.8;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(position.x, position.y),
          width: pixelSize,
          height: pixelSize,
        ),
        paint,
      );
      
      // 为较大的火花添加十字形状的亮点
      if (size > 2.0 && _opacity > 0.3) {
        final crossSize = size * 0.6;
        
        // 亮点的颜色，确保透明度有效
        paint.color = withSafeOpacity(Colors.white, safeOpacity * 0.7);
        
        // 水平线
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(position.x, position.y),
            width: crossSize,
            height: crossSize / 3,
          ),
          paint,
        );
        
        // 垂直线
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(position.x, position.y),
            width: crossSize / 3,
            height: crossSize,
          ),
          paint,
        );
      }
    } catch (e) {
      _hasRenderError = true;
      _renderSimplified(canvas);
    }
  }
  
  // 简化版渲染
  void _renderSimplified(Canvas canvas) {
    try {
      // 确保透明度在有效范围内
      final safeOpacity = _opacity.clamp(0.0, 1.0);
      final paint = Paint()
        ..color = Colors.white.withOpacity(safeOpacity)
        ..style = PaintingStyle.fill;
      
      // 简单绘制一个小矩形
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(position.x, position.y),
          width: size * 0.5,
          height: size * 0.5,
        ),
        paint,
      );
    } catch (_) {
      // 忽略所有错误
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