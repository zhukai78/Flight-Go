import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../flight_go_game.dart';
import 'bullet_component.dart';
import 'player_component.dart';
import 'explosion_component.dart';
import 'package:flame/game.dart';

/// 敌人类型枚举
enum EnemyType { normal, elite, boss }

/// 敌人移动模式枚举
enum MovementPattern { straight, zigzag, circular, homing }

/// 敌人组件
class EnemyComponent extends SpriteComponent with HasGameRef<FlightGoGame>, CollisionCallbacks {
  // 敌人类型
  final EnemyType type;
  
  // 敌人生命值
  int health;
  
  // 敌人速度
  final double speed;
  
  // 敌人得分
  final int scoreValue;
  
  // 移动模式
  final MovementPattern movementPattern;
  
  // 射击间隔
  final double shootInterval;
  double _shootCooldown = 0;
  
  // 移动相关变量
  double _movementTime = 0;
  Vector2 _direction;
  
  // 随机数生成器
  final Random _random = Random();
  
  // 绘制相关
  late Paint _enemyPaint;
  
  EnemyComponent({
    required this.type,
    required Vector2 position,
    Vector2? size,
    this.movementPattern = MovementPattern.straight,
  }) : 
    health = _getHealthByType(type),
    speed = _getSpeedByType(type),
    scoreValue = _getScoreByType(type),
    shootInterval = _getShootIntervalByType(type),
    _direction = Vector2(0, 1), // 默认向下移动
    super(
      position: position,
      size: size ?? _getSizeByType(type),
    ) {
    // 初始化画笔
    _enemyPaint = Paint()..color = _getColorByType(type);
  }
  
  // 根据敌人类型获取生命值
  static int _getHealthByType(EnemyType type) {
    switch (type) {
      case EnemyType.normal: return 1;
      case EnemyType.elite: return 3;
      case EnemyType.boss: return 20;
    }
  }
  
  // 根据敌人类型获取速度
  static double _getSpeedByType(EnemyType type) {
    switch (type) {
      case EnemyType.normal: return 100;
      case EnemyType.elite: return 80;
      case EnemyType.boss: return 40;
    }
  }
  
  // 根据敌人类型获取分数
  static int _getScoreByType(EnemyType type) {
    switch (type) {
      case EnemyType.normal: return 10;
      case EnemyType.elite: return 50;
      case EnemyType.boss: return 500;
    }
  }
  
  // 根据敌人类型获取尺寸
  static Vector2 _getSizeByType(EnemyType type) {
    switch (type) {
      case EnemyType.normal: return Vector2(48, 48);
      case EnemyType.elite: return Vector2(64, 64);
      case EnemyType.boss: return Vector2(128, 128);
    }
  }
  
  // 根据敌人类型获取射击间隔
  static double _getShootIntervalByType(EnemyType type) {
    switch (type) {
      case EnemyType.normal: return 2.0;
      case EnemyType.elite: return 1.5;
      case EnemyType.boss: return 1.0;
    }
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 加载敌人精灵图
    try {
      switch (type) {
        case EnemyType.normal:
          sprite = await Sprite.load('images/enemies/enemy_normal.png');
          break;
        case EnemyType.elite:
          sprite = await Sprite.load('images/enemies/enemy_elite.png');
          break;
        case EnemyType.boss:
          sprite = await Sprite.load('images/enemies/enemy_boss.png');
          break;
      }
    } catch (e) {
      // 图片未加载成功，我们将在render方法中绘制
      debugPrint('无法加载敌人精灵图: $e');
      
      // 创建一个基于自绘形状的精灵
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      _renderEnemyShape(canvas);
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.x.toInt(), size.y.toInt());
      sprite = Sprite(image);
    }
    
    // 添加碰撞检测
    add(RectangleHitbox()
      ..collisionType = CollisionType.active
    );
    
    // 如果是能射击的敌人，添加射击定时器
    if (type != EnemyType.normal || _random.nextBool()) {
      add(TimerComponent(
        period: shootInterval,
        repeat: true,
        onTick: _shoot,
      ));
    }
  }
  
  @override
  void render(Canvas canvas) {
    if (sprite == null) {
      // 如果精灵图未加载，绘制一个简单的敌人形状
      _renderEnemyShape(canvas);
    } else {
      super.render(canvas);
    }
  }
  
  // 绘制简单的敌人形状
  void _renderEnemyShape(Canvas canvas) {
    // 中心点
    final center = size / 2;
    
    switch (type) {
      case EnemyType.normal:
        // 普通敌人 - 简单的三角形
        final path = Path()
          ..moveTo(center.x, 0) // 顶部
          ..lineTo(size.x, size.y) // 右下角
          ..lineTo(0, size.y) // 左下角
          ..close();
        
        canvas.drawPath(path, _enemyPaint);
        break;
        
      case EnemyType.elite:
        // 精英敌人 - 六边形
        final radius = size.x / 2;
        final path = Path();
        
        for (int i = 0; i < 6; i++) {
          final angle = i * pi / 3;
          final x = center.x + radius * cos(angle);
          final y = center.y + radius * sin(angle);
          
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        
        path.close();
        canvas.drawPath(path, _enemyPaint);
        
        // 添加细节
        final detailPaint = Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        
        canvas.drawCircle(
          Offset(center.x, center.y),
          radius * 0.6,
          detailPaint,
        );
        break;
        
      case EnemyType.boss:
        // Boss敌人 - 大圆形和复杂形状
        // 主体
        canvas.drawCircle(
          Offset(center.x, center.y),
          size.x * 0.4,
          _enemyPaint,
        );
        
        // 外壳
        final outerPaint = Paint()
          ..color = Colors.purpleAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5;
        
        canvas.drawCircle(
          Offset(center.x, center.y),
          size.x * 0.45,
          outerPaint,
        );
        
        // 武器突起
        for (int i = 0; i < 4; i++) {
          final angle = i * pi / 2;
          final x1 = center.x + size.x * 0.5 * cos(angle);
          final y1 = center.y + size.x * 0.5 * sin(angle);
          final x2 = center.x + size.x * 0.3 * cos(angle);
          final y2 = center.y + size.x * 0.3 * sin(angle);
          
          final weaponPaint = Paint()..color = Colors.purple;
          
          canvas.drawLine(
            Offset(x2, y2),
            Offset(x1, y1),
            weaponPaint..strokeWidth = 8,
          );
        }
        break;
    }
  }
  
  // 获取敌人颜色
  Color _getColorByType(EnemyType type) {
    switch (type) {
      case EnemyType.normal: return Colors.red;
      case EnemyType.elite: return Colors.orange;
      case EnemyType.boss: return Colors.purple;
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    try {
      if (gameRef.gameState != GameState.playing) return;
      
      // 更新移动时间
      _movementTime += dt;
      
      // 根据移动模式更新方向
      _updateDirection(dt);
      
      // 移动敌人
      position += _direction * speed * dt;
      
      // 更新射击冷却
      if (_shootCooldown > 0) {
        _shootCooldown -= dt;
      }
      
      // 检查是否超出屏幕底部，如果是则移除
      if (position.y > gameRef.size.y + size.y) {
        removeFromParent();
      }
    } catch (e) {
      debugPrint('Enemy update error: $e');
      // 安全移除
      try { removeFromParent(); } catch (_) {}
    }
  }
  
  // 更新移动方向
  void _updateDirection(double dt) {
    try {
      switch (movementPattern) {
        case MovementPattern.straight:
          // 直线移动，保持当前方向
          break;
        case MovementPattern.zigzag:
          // 之字形移动
          _direction.x = sin(_movementTime * 2) * 0.5;
          _direction.y = 1;
          _direction = _direction.normalized();
          break;
        case MovementPattern.circular:
          // 圆形移动
          _direction.x = sin(_movementTime) * 0.8;
          _direction.y = 0.6 + cos(_movementTime) * 0.4;
          break;
        case MovementPattern.homing:
          // 追踪玩家
          if (gameRef.player.isMounted) {
            final toPlayer = gameRef.player.position - position;
            if (toPlayer.length > 0) {
              _direction = toPlayer.normalized();
            }
          }
          break;
      }
    } catch (e) {
      // 如果出错，回退到直线移动
      _direction = Vector2(0, 1);
      debugPrint('Enemy direction update error: $e');
    }
  }
  
  // 射击方法
  void _shoot() {
    if (gameRef.gameState != GameState.playing) return;
    if (_shootCooldown > 0) return;
    
    // 重置射击冷却
    _shootCooldown = shootInterval;
    
    // 创建子弹
    switch (type) {
      case EnemyType.normal:
        // 普通敌人 - 单发直射
        gameRef.getEnemyBullet(
          position: position + Vector2(0, size.y / 2),
          direction: Vector2(0, 1),
        );
        break;
      case EnemyType.elite:
        // 精英敌人 - 三发扇形
        gameRef.getEnemyBullet(
          position: position + Vector2(0, size.y / 2),
          direction: Vector2(0, 1),
        );
        gameRef.getEnemyBullet(
          position: position + Vector2(-10, size.y / 2),
          direction: Vector2(-0.2, 0.8).normalized(),
        );
        gameRef.getEnemyBullet(
          position: position + Vector2(10, size.y / 2),
          direction: Vector2(0.2, 0.8).normalized(),
        );
        break;
      case EnemyType.boss:
        // Boss敌人 - 环形弹幕
        for (int i = 0; i < 8; i++) {
          final angle = i * pi / 4;
          final direction = Vector2(sin(angle), cos(angle));
          gameRef.getEnemyBullet(
            position: position + direction * size.y / 2,
            direction: direction,
            speed: 150,
          );
        }
        break;
    }
  }
  
  /// 击中敌人
  void hit(int damage) {
    health -= damage;
    
    // 闪烁效果
    add(
      ColorEffect(
        Colors.white,
        EffectController(duration: 0.1),
        opacityTo: 0.5,
      ),
    );
    
    if (health <= 0) {
      // 击败敌人，增加分数
      gameRef.addScore(scoreValue);
      
      // 播放爆炸音效
      gameRef.audioService.playExplosionSound();
      
      // 创建爆炸效果
      gameRef.add(
        ExplosionComponent(
          position: position.clone(),
          primaryColor: Colors.orange,
          secondaryColor: Colors.yellow,
          initialRadius: size.x / 2,
          maxRadius: size.x * 1.2,
        ),
      );
      
      // 移除敌人
      removeFromParent();
    }
  }
  
  // 碰撞检测回调
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    if (other is BulletComponent && other.isPlayerBullet) {
      // 被玩家子弹击中
      hit(other.damage);
      other.removeFromParent();
    } else if (other is PlayerComponent) {
      // 与玩家碰撞，玩家受伤
      other.takeDamage();
    }
  }
}