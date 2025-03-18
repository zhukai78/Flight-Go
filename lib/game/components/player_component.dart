import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math';
import '../flight_go_game.dart';
import 'bullet_component.dart';
import 'enemy_component.dart';
import 'engine_flame_component.dart';
import 'explosion_component.dart';

/// 玩家飞机组件
class PlayerComponent extends SpriteComponent with HasGameRef<FlightGoGame>, CollisionCallbacks {
  // 玩家生命值
  int health = 3;
  
  // 玩家移动速度
  final double speed = 300;
  
  // 射击冷却时间
  double _shootCooldown = 0;
  final double shootInterval = 0.5; // 射击间隔，秒
  
  // 无敌时间（被击中后短暂无敌）
  double _invincibleTime = 0;
  final double invincibleDuration = 1.5; // 无敌持续时间，秒
  
  // 是否无敌
  bool get isInvincible => _invincibleTime > 0;
  
  // 武器等级
  int weaponLevel = 1;
  
  // 自定义画笔
  late Paint _shipPaint;
  
  PlayerComponent() : super(size: Vector2(64, 64)) {
    // 初始化画笔
    _shipPaint = Paint()..color = Colors.blue;
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 设置初始位置在屏幕底部中央
    position = Vector2(
      gameRef.size.x / 2,
      gameRef.size.y - size.y - 50,
    );
    
    // 添加碰撞检测
    add(RectangleHitbox()
      ..collisionType = CollisionType.active
    );
    
    // 添加射击定时器
    add(TimerComponent(
      period: shootInterval,
      repeat: true,
      onTick: _shoot,
    ));
    
    // 添加引擎火焰
    final engineFlame = EngineFlameComponent(
      position: Vector2(0, size.y),
      size: Vector2(size.x * 0.6, size.y * 0.5),
      baseColor: Colors.blue,
    );
    
    add(engineFlame);
    
    // 尝试加载玩家飞机精灵图
    try {
      sprite = await Sprite.load('images/player.png');
    } catch (e) {
      // 图片未加载成功，我们将在render方法中绘制
      debugPrint('无法加载玩家精灵图: $e');
      
      // 创建一个基于自绘形状的精灵
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      _renderShipShape(canvas);
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.x.toInt(), size.y.toInt());
      sprite = Sprite(image);
    }
  }
  
  @override
  void render(Canvas canvas) {
    if (sprite == null) {
      // 如果精灵图未加载，绘制一个简单的飞机形状
      _renderShipShape(canvas);
    } else {
      super.render(canvas);
    }
  }
  
  // 绘制简单的飞机形状
  void _renderShipShape(Canvas canvas) {
    // 中心点
    final center = size / 2;
    
    // 主要飞机颜色
    final mainPaint = Paint()..color = Colors.blue.shade700;
    
    // 飞机机身
    final bodyPath = Path()
      ..moveTo(center.x, 0) // 机头
      ..lineTo(size.x, size.y * 0.8) // 右下角
      ..lineTo(size.x * 0.7, size.y) // 右后角
      ..lineTo(size.x * 0.3, size.y) // 左后角
      ..lineTo(0, size.y * 0.8) // 左下角
      ..close();
    
    // 绘制飞机主体
    canvas.drawPath(bodyPath, mainPaint);
    
    // 机翼高亮
    final highlightPaint = Paint()..color = Colors.lightBlue.shade300;
    
    // 左机翼高亮
    final leftWingPath = Path()
      ..moveTo(center.x, center.y * 0.6)
      ..lineTo(0, size.y * 0.8)
      ..lineTo(size.x * 0.3, size.y * 0.8)
      ..close();
    
    // 右机翼高亮
    final rightWingPath = Path()
      ..moveTo(center.x, center.y * 0.6)
      ..lineTo(size.x, size.y * 0.8)
      ..lineTo(size.x * 0.7, size.y * 0.8)
      ..close();
    
    canvas.drawPath(leftWingPath, highlightPaint);
    canvas.drawPath(rightWingPath, highlightPaint);
    
    // 飞机驾驶舱
    final cockpitPaint = Paint()..color = Colors.lightBlue.shade100;
    final cockpitPath = Path()
      ..moveTo(center.x, center.y * 0.2)
      ..lineTo(center.x + center.x * 0.4, center.y * 0.8)
      ..lineTo(center.x - center.x * 0.4, center.y * 0.8)
      ..close();
    
    canvas.drawPath(cockpitPath, cockpitPaint);
    
    // 飞机边缘
    final edgePaint = Paint()
      ..color = Colors.blue.shade900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawPath(bodyPath, edgePaint);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 更新射击冷却
    if (_shootCooldown > 0) {
      _shootCooldown -= dt;
    }
    
    // 更新无敌时间
    if (_invincibleTime > 0) {
      _invincibleTime -= dt;
      // 无敌状态闪烁效果
      opacity = _invincibleTime % 0.2 > 0.1 ? 0.5 : 1.0;
    } else {
      opacity = 1.0;
    }
    
    // 确保玩家不会移出屏幕
    position.clamp(
      Vector2(size.x / 2, size.y / 2),
      Vector2(gameRef.size.x - size.x / 2, gameRef.size.y - size.y / 2),
    );
  }
  
  // 移动玩家飞机
  void move(Vector2 delta) {
    position.add(delta);
  }
  
  // 射击方法
  void _shoot() {
    if (gameRef.gameState != GameState.playing) return;
    
    // 根据武器等级创建不同数量和类型的子弹
    switch (weaponLevel) {
      case 1:
        // 单发直射子弹
        gameRef.getPlayerBullet(
          position: position + Vector2(0, -size.y / 2),
          direction: Vector2(0, -1),
        );
        break;
      case 2:
        // 双发子弹
        gameRef.getPlayerBullet(
          position: position + Vector2(-10, -size.y / 2),
          direction: Vector2(0, -1),
        );
        gameRef.getPlayerBullet(
          position: position + Vector2(10, -size.y / 2),
          direction: Vector2(0, -1),
        );
        break;
      case 3:
        // 三发子弹（直射+斜射）
        gameRef.getPlayerBullet(
          position: position + Vector2(0, -size.y / 2),
          direction: Vector2(0, -1),
        );
        gameRef.getPlayerBullet(
          position: position + Vector2(-10, -size.y / 2),
          direction: Vector2(-0.2, -0.8).normalized(),
        );
        gameRef.getPlayerBullet(
          position: position + Vector2(10, -size.y / 2),
          direction: Vector2(0.2, -0.8).normalized(),
        );
        break;
    }
  }
  
  // 受到伤害
  void takeDamage() {
    // 无敌状态下不受伤害
    if (isInvincible) return;
    
    // 减少生命值
    health--;
    
    // 播放受伤音效
    gameRef.audioService.playExplosionSound();
    
    // 添加闪烁效果
    add(
      ColorEffect(
        Colors.red,
        EffectController(
          duration: 0.1,
          reverseDuration: 0.1,
          repeatCount: 5,
        ),
        opacityTo: 0.5,
      ),
    );
    
    // 设置无敌状态
    _invincibleTime = invincibleDuration;
    
    // 如果生命值为0，游戏结束
    if (health <= 0) {
      gameRef.add(
        ExplosionComponent(
          position: position.clone(),
          primaryColor: Colors.blue,
          secondaryColor: Colors.lightBlueAccent,
          initialRadius: size.x / 2,
          maxRadius: size.x * 2,
          duration: 1.2,
        ),
      );
      
      // 延迟调用游戏结束，让爆炸效果完成
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (gameRef.isMounted) {
          gameRef.gameOver();
        }
      });
      
      removeFromParent();
    }
  }
  
  // 升级武器
  void upgradeWeapon() {
    if (weaponLevel < 3) {
      weaponLevel++;
    }
  }
  
  // 碰撞检测回调
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    if (other is BulletComponent && !other.isPlayerBullet) {
      // 被敌人子弹击中
      takeDamage();
      other.removeFromParent();
    } else if (other is EnemyComponent) {
      // 与敌人碰撞
      takeDamage();
    }
  }
  
  void powerUp() {
    // 提升武器等级
    if (weaponLevel < 3) {
      weaponLevel++;
    } else {
      // 如果已经是最高级武器，恢复一点生命值
      if (health < 3) {
        health++;
      }
    }
    
    // 播放能量道具音效
    gameRef.audioService.playPowerupSound();
    
    // 添加闪烁效果
    add(
      ColorEffect(
        Colors.green,
        EffectController(
          duration: 0.1,
          reverseDuration: 0.1,
          repeatCount: 3,
        ),
        opacityTo: 0.7,
      ),
    );
  }
}