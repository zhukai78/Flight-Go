import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../flight_go_game.dart';

/// 背景组件 - 使用视差滚动实现更好的深度感
class BackgroundComponent extends PositionComponent with HasGameRef<FlightGoGame> {
  // 背景滚动速度
  double _speed = 100.0;
  
  // 获取/设置滚动速度
  double get speed => _speed;
  set speed(double value) {
    _speed = value;
  }
  
  // 星星列表
  final List<StarComponent> _stars = [];
  
  // 星云列表
  final List<NebulaeComponent> _nebulae = [];
  
  // 随机数生成器
  final Random _random = Random();
  
  // 错误跟踪
  int _renderErrorCount = 0;
  DateTime _lastErrorTime = DateTime.now();
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 设置位置和大小
    position = Vector2.zero();
    size = gameRef.size;
    
    // 创建星云
    for (int i = 0; i < 3; i++) {
      _createNebulae();
    }
    
    // 创建不同大小的星星
    
    // 背景星星 (很小)
    for (int i = 0; i < 30; i++) {
      _createStar(
        size: _random.nextDouble() * 1.5 + 0.5,
        speed: _random.nextDouble() * 20 + 15,
        color: _getRandomStarColor(0.7),
      );
    }
    
    // 中等星星
    for (int i = 0; i < 15; i++) {
      _createStar(
        size: _random.nextDouble() * 2.0 + 1.5,
        speed: _random.nextDouble() * 30 + 20,
        color: _getRandomStarColor(0.9),
        twinkleSpeed: _random.nextDouble() * 0.5 + 0.8,
      );
    }
    
    // 前景亮星星 (大且有辉光)
    for (int i = 0; i < 5; i++) {
      _createStar(
        size: _random.nextDouble() * 3.0 + 2.0,
        speed: _random.nextDouble() * 40 + 25,
        color: _getRandomStarColor(1.0),
        twinkleSpeed: _random.nextDouble() * 0.7 + 1.0,
        glowIntensity: _random.nextDouble() * 2.0 + 1.0,
      );
    }
  }
  
  // 创建星星
  void _createStar({
    required double size,
    required double speed,
    required Color color,
    double? twinkleSpeed,
    double? glowIntensity,
  }) {
    // 随机位置
    final position = Vector2(
      _random.nextDouble() * gameRef.size.x,
      _random.nextDouble() * gameRef.size.y,
    );
    
    // 创建星星
    final star = StarComponent(
      position: position,
      starSize: size,
      speed: speed,
      color: color,
      twinkleSpeed: twinkleSpeed,
      glowIntensity: glowIntensity,
    );
    
    // 添加到列表和游戏中
    _stars.add(star);
    add(star);
  }
  
  // 创建星云
  void _createNebulae() {
    // 随机位置
    final position = Vector2(
      _random.nextDouble() * (gameRef.size.x - 150),
      _random.nextDouble() * gameRef.size.y,
    );
    
    // 随机大小
    final size = Vector2(
      _random.nextDouble() * 200 + 100,
      _random.nextDouble() * 200 + 100,
    );
    
    // 随机颜色
    final color = _getRandomNebulaeColor();
    
    // 随机速度 (星云移动较慢)
    final speed = _random.nextDouble() * 10 + 5;
    
    // 创建星云
    final nebulae = NebulaeComponent(
      position: position,
      size: size,
      color: color,
      speed: speed,
    );
    
    // 添加到列表和游戏中
    _nebulae.add(nebulae);
    add(nebulae);
  }
  
  // 获取随机星星颜色
  Color _getRandomStarColor(double brightness) {
    final colors = [
      Color.fromARGB((255 * brightness).toInt(), 255, 255, 255), // 白色
      Color.fromARGB((255 * brightness).toInt(), 200, 200, 255), // 蓝白色
      Color.fromARGB((255 * brightness).toInt(), 255, 230, 200), // 黄白色
      Color.fromARGB((255 * brightness).toInt(), 200, 255, 230), // 青白色
    ];
    
    return colors[_random.nextInt(colors.length)];
  }
  
  // 获取随机星云颜色
  Color _getRandomNebulaeColor() {
    final colors = [
      Color.fromARGB(255, 100, 50, 200), // 紫色
      Color.fromARGB(255, 50, 100, 200), // 蓝色
      Color.fromARGB(255, 200, 100, 50), // 橙色
      Color.fromARGB(255, 50, 150, 100), // 绿色
      Color.fromARGB(255, 150, 50, 150), // 粉色
    ];
    
    return colors[_random.nextInt(colors.length)];
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 根据游戏难度调整星星速度
    if (gameRef.gameState == GameState.playing) {
      final speedMultiplier = gameRef.difficultyMultiplier;
      
      for (final star in _stars) {
        star.speed = star.speed * 0.99 + (star.speed * speedMultiplier * 0.01);
      }
      
      for (final nebulae in _nebulae) {
        nebulae.speed = nebulae.speed * 0.99 + (nebulae.speed * speedMultiplier * 0.01);
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    try {
      // 保存画布状态
      canvas.save();
      
      // 调用父类的render方法
      super.render(canvas);
      
      // 恢复画布状态
      canvas.restore();
    } catch (e) {
      _renderErrorCount++;
      
      // 限制错误日志频率
      final now = DateTime.now();
      if (now.difference(_lastErrorTime).inSeconds >= 10) { // 每10秒最多记录一次
        _lastErrorTime = now;
        debugPrint('背景渲染错误: $e');
        debugPrint('背景组件错误计数: $_renderErrorCount');
      }
      
      // 尝试恢复状态
      try {
        canvas.restore();
      } catch (_) {
        // 忽略恢复时的错误
      }
    }
  }
}

/// 星星组件
class StarComponent extends PositionComponent with HasGameRef<FlightGoGame> {
  // 星星大小
  final double starSize;
  
  // 移动速度
  double speed;
  
  // 颜色
  final Color color;
  
  // 闪烁计时器
  double _twinkleTime = 0;
  
  // 亮度
  double _brightness = 1.0;
  
  // 闪烁速度
  final double _twinkleSpeed;
  
  // 透明度
  double _opacity = 1.0;
  
  // 辉光强度
  final double _glowIntensity;
  
  // 错误状态追踪
  bool _hadRenderError = false;
  int _errorCount = 0;
  
  StarComponent({
    required Vector2 position,
    required this.starSize,
    required this.speed,
    required this.color,
    double? twinkleSpeed,
    double? glowIntensity,
  }) : 
    _twinkleSpeed = twinkleSpeed ?? 1.0,
    _glowIntensity = glowIntensity ?? 0.0,
    super(position: position, size: Vector2.all(starSize));
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 仅在游戏进行时更新位置
    if (gameRef.gameState == GameState.playing) {
      // 向下移动
      position.y += speed * dt;
      
      // 超出屏幕底部时，重新生成在屏幕顶部
      if (position.y > gameRef.size.y) {
        position.y = -starSize;
        position.x = Random().nextDouble() * gameRef.size.x;
        
        // 重置错误状态
        _hadRenderError = false;
        _errorCount = 0;
      }
    }
    
    // 闪烁效果 - 即使在暂停时也保持
    _twinkleTime += dt * _twinkleSpeed;
    _brightness = 0.7 + (sin(_twinkleTime * 3) + 1) * 0.15;
    _opacity = 0.7 + (sin(_twinkleTime * 2) + 1) * 0.15;
  }
  
  @override
  void render(Canvas canvas) {
    // 如果之前有渲染错误，减少渲染复杂度
    if (_hadRenderError) {
      _renderSimplified(canvas);
      return;
    }
    
    try {
      // 绘制星星
      final paint = Paint()
        ..color = color.withOpacity(_opacity * _brightness);
      
      // 保存画布状态
      canvas.save();
      
      // 绘制星星核心
      canvas.drawCircle(
        Offset(starSize/2, starSize/2),
        starSize/2 * _brightness,
        paint,
      );
      
      // 如果有辉光效果
      if (_glowIntensity > 0) {
        // 绘制多层辉光效果（不使用MaskFilter）
        for (int i = 1; i <= 3; i++) {
          final glowRadius = starSize/2 * (1 + i * 0.5) * _glowIntensity;
          final glowOpacity = _opacity * 0.3 * _glowIntensity / i;
          
          final glowPaint = Paint()
            ..color = color.withOpacity(glowOpacity)
            ..style = PaintingStyle.fill;
          
          canvas.drawCircle(
            Offset(starSize/2, starSize/2),
            glowRadius,
            glowPaint,
          );
        }
      }
      
      // 恢复画布状态
      canvas.restore();
    } catch (e) {
      _errorCount++;
      if (_errorCount > 2) {
        _hadRenderError = true;
      }
      
      // 恢复画布状态
      try {
        canvas.restore();
      } catch (_) {
        // 忽略
      }
      
      // 尝试降级渲染
      _renderSimplified(canvas);
    }
  }
  
  // 简化版本的渲染，用于错误恢复
  void _renderSimplified(Canvas canvas) {
    try {
      // 使用更简单的绘制方法
      final paint = Paint()
        ..color = color.withOpacity(_opacity * 0.7);
      
      // 绘制一个简单的矩形，而不是圆形
      canvas.drawRect(
        Rect.fromLTWH(0, 0, starSize, starSize),
        paint,
      );
    } catch (_) {
      // 忽略任何渲染错误，防止级联故障
    }
  }
}

/// 星云组件
class NebulaeComponent extends PositionComponent with HasGameRef<FlightGoGame> {
  // 星云颜色
  final Color color;
  
  // 移动速度
  double speed;
  
  // 不透明度
  double opacity = 0.1;
  
  // 旋转角度
  double _rotation = 0;
  
  // 随机数生成器
  final Random _random = Random();
  
  // 星云形状点
  final List<Vector2> _points = [];
  
  // 脉动效果
  double _pulseTime = 0;
  double _pulseIntensity = 0;
  
  // 错误状态跟踪
  bool _hadRenderError = false;
  int _errorCount = 0;
  
  NebulaeComponent({
    required Vector2 position,
    required Vector2 size,
    required this.color,
    required this.speed,
  }) : super(position: position, size: size) {
    // 随机旋转角度
    _rotation = _random.nextDouble() * 2 * pi;
    
    // 随机脉动强度
    _pulseIntensity = 0.05 + _random.nextDouble() * 0.1;
    
    // 生成星云形状点
    final numPoints = 5 + _random.nextInt(5);
    for (int i = 0; i < numPoints; i++) {
      _points.add(Vector2(
        _random.nextDouble() * size.x,
        _random.nextDouble() * size.y,
      ));
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 仅在游戏进行时更新位置
    if (gameRef.gameState == GameState.playing) {
      // 向下移动
      position.y += speed * dt;
      
      // 缓慢旋转
      _rotation += dt * 0.05;
      
      // 超出屏幕底部时，重新生成在屏幕顶部
      if (position.y > gameRef.size.y + size.y) {
        position.y = -size.y;
        position.x = _random.nextDouble() * (gameRef.size.x - size.x);
        
        // 重置错误状态
        _hadRenderError = false;
        _errorCount = 0;
      }
    }
    
    // 脉动效果 - 即使在暂停时也保持
    _pulseTime += dt;
    opacity = 0.08 + sin(_pulseTime * 0.5) * _pulseIntensity;
  }
  
  @override
  void render(Canvas canvas) {
    // 如果之前有渲染错误，减少渲染复杂度
    if (_hadRenderError) {
      _renderSimplified(canvas);
      return;
    }
    
    try {
      // 保存画布状态
      canvas.save();
      
      // 移动到组件位置
      canvas.translate(position.x, position.y);
      
      // 旋转画布
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(_rotation);
      canvas.translate(-size.x / 2, -size.y / 2);
      
      // 绘制星云 - 移除模糊滤镜，改用渐变效果
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      // 创建路径
      final path = Path();
      for (int i = 0; i < _points.length; i++) {
        final point = _points[i];
        if (i == 0) {
          path.moveTo(point.x, point.y);
        } else {
          path.lineTo(point.x, point.y);
        }
      }
      path.close();
      
      // 绘制填充路径
      canvas.drawPath(path, paint);
      
      // 绘制多个半透明圆形以模拟模糊效果
      for (final point in _points) {
        final radius = 10.0 + _random.nextDouble() * 20.0;
        final cloudPaint = Paint()
          ..color = color.withOpacity(opacity * 0.5)
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(
          Offset(point.x, point.y),
          radius,
          cloudPaint,
        );
      }
      
      // 恢复画布状态
      canvas.restore();
    } catch (e) {
      _errorCount++;
      if (_errorCount > 2) {
        _hadRenderError = true;
        
        // 只在第一次错误时记录日志
        if (_errorCount == 3) {
          debugPrint('星云渲染错误，切换到简化渲染: $e');
        }
      }
      
      // 尝试恢复Canvas状态
      try {
        canvas.restore();
      } catch (_) {
        // 忽略恢复失败
      }
      
      // 尝试降级渲染
      _renderSimplified(canvas);
    }
  }
  
  // 简化版本的渲染，用于错误恢复
  void _renderSimplified(Canvas canvas) {
    try {
      // 简单绘制一个矩形，避免复杂的路径和变换
      final paint = Paint()
        ..color = color.withOpacity(opacity * 0.5)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(
        Rect.fromLTWH(position.x, position.y, size.x, size.y),
        paint,
      );
    } catch (_) {
      // 忽略任何渲染错误
    }
  }
}