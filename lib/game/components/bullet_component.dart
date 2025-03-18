import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../flight_go_game.dart';
import 'bullet_trail_component.dart';
import 'dart:math';

/// 子弹组件
class BulletComponent extends SpriteComponent with HasGameRef<FlightGoGame>, CollisionCallbacks {
  // 子弹方向
  Vector2 direction;
  
  // 子弹速度
  double speed;
  
  // 是否是玩家的子弹
  final bool isPlayerBullet;
  
  // 子弹伤害
  int damage;
  
  // 画笔
  late Paint _bulletPaint;
  
  final Random _random = Random();
  
  BulletComponent({
    required Vector2 position,
    required this.direction,
    required this.isPlayerBullet,
    this.speed = 300,
    this.damage = 1,
    Vector2? size,
  }) : super(
    position: position,
    size: size ?? Vector2(8, 16),
  ) {
    // 初始化画笔
    _bulletPaint = Paint()..color = isPlayerBullet ? Colors.blue : Colors.red;
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 尝试加载子弹精灵图
    try {
      final spriteImage = await Sprite.load(isPlayerBullet ? 'images/bullets/player_bullet.png' : 'images/bullets/enemy_bullet.png');
      sprite = spriteImage;
    } catch (e) {
      // 图片未加载成功，我们将在render方法中绘制
      debugPrint('无法加载子弹精灵图: $e');
      // 确保sprite始终有值，即使是空白的
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      _renderBulletShape(canvas);
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.x.toInt(), size.y.toInt());
      sprite = Sprite(image);
    }
    
    // 根据方向旋转子弹
    angle = direction.angleToSigned(Vector2(0, -1));
    
    // 添加碰撞检测
    add(RectangleHitbox()
      ..collisionType = CollisionType.active
    );
  }
  
  @override
  void render(Canvas canvas) {
    if (sprite == null) {
      // 如果精灵图未加载，绘制一个简单的子弹形状
      _renderBulletShape(canvas);
    } else {
      super.render(canvas);
    }
  }
  
  // 绘制简单的子弹形状
  void _renderBulletShape(Canvas canvas) {
    // 保存当前画布状态
    canvas.save();
    
    // 旋转画布，使子弹朝向正确的方向
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(angle);
    canvas.translate(-size.x / 2, -size.y / 2);
    
    // 子弹形状
    if (isPlayerBullet) {
      // 玩家子弹 - 椭圆形
      canvas.drawOval(
        Rect.fromLTWH(0, 0, size.x, size.y),
        _bulletPaint,
      );
      
      // 子弹光效
      final glowPaint = Paint()
        ..color = Colors.lightBlue.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawOval(
        Rect.fromLTWH(2, 2, size.x - 4, size.y - 4),
        glowPaint,
      );
    } else {
      // 敌人子弹 - 菱形
      final path = Path()
        ..moveTo(size.x / 2, 0)
        ..lineTo(size.x, size.y / 2)
        ..lineTo(size.x / 2, size.y)
        ..lineTo(0, size.y / 2)
        ..close();
      
      canvas.drawPath(path, _bulletPaint);
    }
    
    // 恢复画布状态
    canvas.restore();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    try {
      if (gameRef.gameState != GameState.playing) return;
      
      // 移动子弹
      position += direction * speed * dt;
      
      // 添加拖尾效果 - 每隔一小段时间添加一个，降低生成概率
      if (_random.nextDouble() < 0.15) {  // 从0.3降低到0.15，减少拖尾生成频率
        gameRef.add(BulletTrailComponent(
          position: position.clone(),
          initialSize: size.x * 0.8,
          color: isPlayerBullet ? Colors.blue : Colors.red,
          isPlayerBullet: isPlayerBullet,
        ));
      }
      
      // 检查是否超出屏幕，如果是则移除
      if (position.y < -size.y || 
          position.y > gameRef.size.y + size.y ||
          position.x < -size.x ||
          position.x > gameRef.size.x + size.x) {
        removeFromParent();
      }
    } catch (e) {
      debugPrint('Bullet update error: $e');
      // 安全移除
      try { removeFromParent(); } catch (_) {}
    }
  }
  
  @override
  void onRemove() {
    // 返回到对象池
    try {
      if (gameRef.bulletPool != null && isMounted) {
        gameRef.bulletPool.returnBullet(this);
      }
    } catch (e) {
      debugPrint('Error returning bullet to pool: $e');
    }
    super.onRemove();
  }
}