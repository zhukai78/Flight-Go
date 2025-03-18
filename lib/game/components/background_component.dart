import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../flight_go_game.dart';

/// 简单的背景组件，创建滚动星空背景
class BackgroundComponent extends Component with HasGameRef<FlightGoGame> {
  // 星星列表
  final List<StarComponent> _stars = [];
  
  // 星云列表
  final List<NebulaeComponent> _nebulae = [];
  
  // 随机数生成器
  final Random _random = Random();
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 等待游戏尺寸初始化完成
    await Future.delayed(Duration.zero);
    
    try {
      // 创建背景矩形
      final background = RectangleComponent(
        size: gameRef.size,
        paint: Paint()..color = Color.fromARGB(255, 0, 0, 25),
      );
      
      add(background);
      
      // 创建星云
      for (int i = 0; i < 3; i++) {
        final nebula = NebulaeComponent(
          position: Vector2(
            _random.nextDouble() * gameRef.size.x,
            _random.nextDouble() * gameRef.size.y,
          ),
          radius: 50 + _random.nextDouble() * 100,
          speed: 5 + _random.nextDouble() * 10,
          color: [
            Colors.purple.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
            Colors.cyan.withOpacity(0.1),
          ][_random.nextInt(3)],
        );
        
        _nebulae.add(nebula);
        add(nebula);
      }
      
      // 创建不同大小和亮度的星星
      // 远景星星 - 较小较暗
      for (int i = 0; i < 30; i++) {
        final star = StarComponent(
          position: Vector2(
            _random.nextDouble() * gameRef.size.x,
            _random.nextDouble() * gameRef.size.y,
          ),
          radius: 0.5 + _random.nextDouble() * 1.0,
          speed: 10 + _random.nextDouble() * 20,
          color: Colors.white.withOpacity(0.3 + _random.nextDouble() * 0.3),
          twinkle: _random.nextBool(),
        );
        
        _stars.add(star);
        add(star);
      }
      
      // 中景星星 - 中等大小和亮度
      for (int i = 0; i < 15; i++) {
        final star = StarComponent(
          position: Vector2(
            _random.nextDouble() * gameRef.size.x,
            _random.nextDouble() * gameRef.size.y,
          ),
          radius: 1.0 + _random.nextDouble() * 1.5,
          speed: 30 + _random.nextDouble() * 30,
          color: Colors.white.withOpacity(0.5 + _random.nextDouble() * 0.3),
          twinkle: _random.nextBool(),
        );
        
        _stars.add(star);
        add(star);
      }
      
      // 近景星星 - 较大较亮
      for (int i = 0; i < 5; i++) {
        final star = StarComponent(
          position: Vector2(
            _random.nextDouble() * gameRef.size.x,
            _random.nextDouble() * gameRef.size.y,
          ),
          radius: 1.5 + _random.nextDouble() * 2.0,
          speed: 50 + _random.nextDouble() * 30,
          color: Colors.white.withOpacity(0.7 + _random.nextDouble() * 0.3),
          twinkle: true,
        );
        
        _stars.add(star);
        add(star);
      }
    } catch (e) {
      debugPrint('Background error: $e');
    }
  }
}

/// 星星组件，用于在背景中显示星星
class StarComponent extends PositionComponent {
  final double radius;
  final Color color;
  final double speed;
  final bool twinkle;
  
  // 随机数生成器
  final _random = Random();
  
  // 闪烁相关
  double _twinkleTime = 0;
  double _brightness = 1.0;
  
  StarComponent({
    required Vector2 position,
    required this.radius,
    required this.speed,
    required this.color,
    this.twinkle = false,
  }) : super(position: position, size: Vector2.all(radius * 2));
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final paint = Paint()
      ..color = color.withOpacity(_brightness)
      ..style = PaintingStyle.fill;
    
    // 绘制星星
    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      paint,
    );
    
    // 为较大的星星添加光晕
    if (radius > 1.0) {
      final glowPaint = Paint()
        ..color = color.withOpacity(_brightness * 0.5)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(radius, radius),
        radius * 1.5,
        glowPaint,
      );
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    try {
      // 星星向下移动，创造宇宙飞行的感觉
      position.y += speed * dt;
      
      // 获取游戏实例，如果找不到则退出
      final game = findGame();
      if (game is! FlightGoGame) return;
      
      // 如果星星移出屏幕底部，重新放置到顶部
      if (position.y > game.size.y) {
        position.y = -size.y;
        position.x = _random.nextDouble() * game.size.x;
      }
      
      // 星星闪烁效果
      if (twinkle) {
        _twinkleTime += dt * (1 + _random.nextDouble() * 2);
        _brightness = 0.7 + (sin(_twinkleTime) * 0.3);
      }
    } catch (e) {
      // 错误处理
      debugPrint('Star update error: $e');
    }
  }
}

/// 星云组件，创建彩色的星云背景
class NebulaeComponent extends PositionComponent {
  final double radius;
  final Color color;
  final double speed;
  
  // 随机数生成器
  final _random = Random();
  
  NebulaeComponent({
    required Vector2 position,
    required this.radius,
    required this.speed,
    required this.color,
  }) : super(
    position: position,
    size: Vector2.all(radius * 2),
    anchor: Anchor.center,
  );
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // 创建径向渐变
    final gradient = RadialGradient(
      colors: [
        color.withOpacity(0.5),
        color.withOpacity(0.3),
        color.withOpacity(0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    
    // 创建着色器
    final shader = gradient.createShader(
      Rect.fromCircle(
        center: Offset(radius, radius),
        radius: radius,
      ),
    );
    
    // 绘制星云
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      paint,
    );
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    try {
      // 星云缓慢向下移动
      position.y += speed * dt;
      
      // 获取游戏实例，如果找不到则退出
      final game = findGame();
      if (game is! FlightGoGame) return;
      
      // 如果星云移出屏幕底部，重新放置到顶部
      if (position.y - radius > game.size.y) {
        position.y = -radius;
        position.x = _random.nextDouble() * game.size.x;
      }
    } catch (e) {
      // 错误处理
      debugPrint('Nebulae update error: $e');
    }
  }
}