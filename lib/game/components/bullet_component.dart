import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../flight_go_game.dart';
import 'enemy_component.dart';
import 'player_component.dart';

/// 子弹组件类
class BulletComponent extends PositionComponent with HasGameRef<FlightGoGame>, CollisionCallbacks {
  // 是否是玩家子弹
  final bool isPlayerBullet;
  
  // 移动方向
  final Vector2 direction;
  
  // 移动速度
  final double speed;
  
  // 伤害值
  final int damage;
  
  // 子弹颜色
  final Color color;
  
  // 是否已被销毁
  bool _isDestroyed = false;
  
  // 子弹画笔
  late Paint _paint;
  
  // 动画计时器
  double _animationTime = 0;
  
  // 随机数生成器
  final Random _random = Random();
  
  BulletComponent({
    required Vector2 position,
    required this.isPlayerBullet,
    required this.direction,
    required Vector2 size,
    this.speed = 300,
    this.damage = 1,
    this.color = Colors.white,
  }) : super(position: position, size: size) {
    // 注册优先级 (让子弹在敌人之上)
    priority = 5;
    
    // 设置锚点为中心点
    anchor = Anchor.center;
    
    // 初始化画笔
    _paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 添加碰撞检测 - 修改敌人子弹的碰撞类型也为active
    add(
      RectangleHitbox()
        ..collisionType = CollisionType.active
    );
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 更新动画时间
    _animationTime += dt;
    
    // 移动子弹
    position += direction * speed * dt;
    
    // 如果子弹超出屏幕边界，移除
    if (position.y < -size.y || 
        position.y > gameRef.size.y + size.y ||
        position.x < -size.x || 
        position.x > gameRef.size.x + size.x) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    // 如果已被销毁，不绘制
    if (_isDestroyed) return;
    
    // 保存画布状态
    canvas.save();
    
    // 子弹类型不同，外观也不同
    if (isPlayerBullet) {
      _renderPlayerBullet(canvas);
    } else {
      _renderEnemyBullet(canvas);
    }
    
    // 恢复画布状态
    canvas.restore();
  }
  
  // 绘制玩家子弹
  void _renderPlayerBullet(Canvas canvas) {
    // 子弹中心点
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    
    // 子弹脉动效果
    final pulseValue = sin(_animationTime * 10) * 0.2 + 1.0;
    
    // 子弹主体 - 发光矩形或圆形
    if (damage > 1) {
      // 高伤害子弹 - 更大的发光效果，使用多层绘制替代模糊滤镜
      
      // 绘制多层光晕以模拟发光效果
      for (int i = 1; i <= 3; i++) {
        final radius = size.x * 0.6 * pulseValue * (1 + (i-1) * 0.4);
        final layerOpacity = 0.5 / i;
        
        final glowPaint = Paint()
          ..color = color.withOpacity(layerOpacity)
          ..style = PaintingStyle.fill;
        
        // 绘制发光层
        canvas.drawCircle(
          Offset(centerX, centerY),
          radius,
          glowPaint,
        );
      }
      
      // 绘制核心
      canvas.drawCircle(
        Offset(centerX, centerY),
        size.x * 0.3,
        _paint,
      );
      
      // 如果是高级子弹，添加轨迹线
      if (damage >= 3) {
        final trailPaint = Paint()
          ..color = color.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        
        final path = Path()
          ..moveTo(centerX, centerY + size.y * 0.3)
          ..lineTo(centerX, centerY + size.y);
        
        canvas.drawPath(path, trailPaint);
      }
    } else {
      // 普通子弹 - 简单圆形
      canvas.drawCircle(
        Offset(centerX, centerY),
        size.x * 0.4,
        _paint,
      );
    }
  }
  
  // 绘制敌人子弹
  void _renderEnemyBullet(Canvas canvas) {
    // 子弹中心点
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    
    // 敌人子弹使用不同的颜色和形状
    // 一般是红色或黄色
    final enemyBulletPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    // 敌人子弹呈菱形
    final path = Path()
      ..moveTo(centerX, centerY - size.y * 0.4) // 上
      ..lineTo(centerX + size.x * 0.4, centerY) // 右
      ..lineTo(centerX, centerY + size.y * 0.4) // 下
      ..lineTo(centerX - size.x * 0.4, centerY) // 左
      ..close();
    
    canvas.drawPath(path, enemyBulletPaint);
    
    // 添加边框
    final borderPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawPath(path, borderPaint);
  }
  
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    // 如果已被销毁，忽略碰撞
    if (_isDestroyed) return;
    
    // 玩家子弹与敌人碰撞
    if (isPlayerBullet && other is EnemyComponent) {
      // 敌人受到伤害
      other.hit(damage);
      destroy();
    }
    // 敌人子弹与玩家碰撞
    else if (!isPlayerBullet && other is PlayerComponent && !other.isInvincible) {
      // 玩家受到伤害
      other.takeDamage(damage);
      // 销毁子弹
      destroy();
    }
  }
  
  // 销毁子弹
  void destroy() {
    if (_isDestroyed) return;
    
    _isDestroyed = true;
    
    // 播放子弹击中音效
    // gameRef.audioService.playHitSound();
    
    // 添加一个简单的爆炸效果
    _addImpactEffect();
    
    // 移除组件
    removeFromParent();
  }
  
  // 添加撞击效果
  void _addImpactEffect() {
    // 在子弹位置创建小型爆炸特效
    gameRef.add(
      BulletImpactEffect(
        position: position.clone(),
        size: Vector2.all(size.x * 2),
        color: isPlayerBullet ? color : Colors.red,
      ),
    );
  }
}

/// 子弹撞击特效
class BulletImpactEffect extends Component with HasGameRef<FlightGoGame> {
  // 位置
  final Vector2 position;
  
  // 大小
  final Vector2 size;
  
  // 颜色
  final Color color;
  
  // 持续时间
  final double duration;
  
  // 当前时间
  double _time = 0.0;
  
  // 随机数生成器
  final Random _random = Random();
  
  // 错误标记
  bool _hasRenderError = false;
  
  BulletImpactEffect({
    required this.position,
    required this.size,
    required this.color,
    this.duration = 0.2,
  });
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 更新时间
    _time += dt;
    
    // 完成后移除
    if (_time >= duration) {
      removeFromParent();
    }
  }
  
  // 安全设置透明度的辅助方法
  Color withSafeOpacity(Color baseColor, double opacity) {
    // 确保透明度在有效范围内 (0.0-1.0)
    final safeOpacity = opacity.clamp(0.0, 1.0);
    
    // 检查颜色是否有效
    if (baseColor == Colors.transparent) {
      return Colors.white.withOpacity(safeOpacity);
    }
    
    try {
      return baseColor.withOpacity(safeOpacity);
    } catch (e) {
      // 如果颜色处理出错，返回一个安全的默认颜色
      debugPrint('子弹特效颜色错误: $e, baseColor=$baseColor, opacity=$opacity');
      
      // 尝试使用固定颜色
      try {
        return Colors.white.withOpacity(safeOpacity);
      } catch (_) {
        // 如果仍然失败，返回最安全的颜色
        return Colors.white;
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    // 如果之前渲染出现过错误，采用简化渲染
    if (_hasRenderError) {
      _renderSimplified(canvas);
      return;
    }
    
    try {
      // 计算当前比例
      final progress = _time / duration;
      final currentSize = size.x * (1.0 - progress);
      
      // 保存画布状态
      canvas.save();
      
      // 移动到爆炸中心
      canvas.translate(position.x, position.y);
      
      // 绘制外环
      final outerOpacity = (0.7 - progress * 0.7).clamp(0.0, 1.0);
      final outerPaint = Paint()
        ..color = withSafeOpacity(color, outerOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawCircle(
        Offset.zero,
        currentSize * 0.8 + size.x * 0.3 * progress,
        outerPaint,
      );
      
      // 绘制内部闪光
      final innerOpacity = (0.8 - progress * 0.8).clamp(0.0, 1.0);
      final innerPaint = Paint()
        ..color = withSafeOpacity(Colors.white, innerOpacity);
      
      canvas.drawCircle(
        Offset.zero,
        currentSize * 0.3,
        innerPaint,
      );
      
      // 绘制一些粒子
      final particleOpacity = (0.5 - progress * 0.5).clamp(0.0, 1.0);
      final particlePaint = Paint()
        ..color = withSafeOpacity(color, particleOpacity);
      
      for (int i = 0; i < 6; i++) {
        final angle = i * (pi * 2 / 6) + _random.nextDouble() * 0.5;
        final distance = currentSize * (0.3 + progress * 0.7);
        final particleSize = currentSize * 0.15 * (1.0 - progress);
        
        canvas.drawCircle(
          Offset(
            cos(angle) * distance,
            sin(angle) * distance,
          ),
          particleSize,
          particlePaint,
        );
      }
      
      // 恢复画布状态
      canvas.restore();
    } catch (e) {
      // 捕获渲染错误
      _hasRenderError = true;
      debugPrint('子弹撞击特效渲染错误: $e, color=$color, time=$_time, duration=$duration');
      
      // 尝试恢复画布状态
      try {
        canvas.restore();
      } catch (_) {
        // 忽略恢复失败
      }
      
      // 降级到简化渲染
      _renderSimplified(canvas);
    }
  }
  
  // 简化版渲染，在出错时使用
  void _renderSimplified(Canvas canvas) {
    try {
      // 计算当前比例
      final progress = _time / duration;
      final currentSize = size.x * (1.0 - progress);
      
      // 安全设置颜色
      final safeColor = Colors.white;
      final safeOpacity = (1.0 - progress).clamp(0.0, 1.0);
      
      final paint = Paint()
        ..color = safeColor.withOpacity(safeOpacity)
        ..style = PaintingStyle.fill;
      
      // 绘制一个简单的圆形
      canvas.drawCircle(
        Offset(position.x, position.y),
        currentSize * 0.5,
        paint,
      );
    } catch (_) {
      // 忽略所有错误，防止级联故障
    }
  }
}