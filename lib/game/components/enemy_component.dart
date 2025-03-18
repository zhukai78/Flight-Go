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
import 'power_up_component.dart';

/// 敌人类型枚举
enum EnemyType { normal, elite, boss }

/// 敌人移动模式枚举
enum MovementPattern { straight, zigzag, circular, homing }

/// 敌人组件
class EnemyComponent extends PositionComponent with HasGameRef<FlightGoGame>, CollisionCallbacks {
  // 敌人精灵图
  Sprite? sprite;
  
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
  
  // 是否已被击败
  bool _defeated = false;
  
  // 随机数生成器
  final Random _random = Random();
  
  // 自定义画笔
  late Paint _enemyPaint;
  
  // 闪烁效果变量
  Color _flashColor = Colors.transparent;
  double _flashIntensity = 0.0;
  double _flashTime = 0.0;
  
  // 护盾数值
  final int _shieldAmount = 0;
  
  // 透明度
  double opacity = 1.0;
  
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
    _enemyPaint = Paint()..color = _getEnemyColor();
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
    
    // 设置碰撞检测
    add(RectangleHitbox()
      ..collisionType = CollisionType.active
    );
    
    // 初始化敌人画笔
    _enemyPaint = Paint()..color = _getEnemyColor();
    
    // 如果是能射击的敌人，添加射击定时器
    if (type != EnemyType.normal || _random.nextBool()) {
      add(TimerComponent(
        period: shootInterval,
        repeat: true,
        onTick: _shoot,
      ));
    }
  }
  
  // 获取敌人主色
  Color _getEnemyColor() {
    switch (type) {
      case EnemyType.normal:
        return Colors.red.shade700;
      case EnemyType.elite:
        return Colors.purple.shade700;
      case EnemyType.boss:
        return Colors.green.shade700;
    }
  }
  
  @override
  void render(Canvas canvas) {
    // 保存画布状态
    canvas.save();
    
    // 应用透明度
    final paint = Paint()..color = Colors.white.withOpacity(opacity);
    
    // 绘制敌人
    _drawEnemy(canvas);
    
    // 绘制护盾效果
    if (_shieldAmount > 0) {
      _drawShield(canvas);
    }
    
    // 应用闪烁效果
    if (_flashIntensity > 0) {
      final flashPaint = Paint()
        ..color = Colors.white.withOpacity(_flashIntensity * 0.5);
      
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), flashPaint);
    }
    
    // 恢复画布状态
    canvas.restore();
  }
  
  // 绘制敌人
  void _drawEnemy(Canvas canvas) {
    final enemyWidth = size.x;
    final enemyHeight = size.y;
    final pixelSize = enemyWidth / 16; // 像素大小
    
    // 获取基本画笔
    final paint = Paint()..color = _getEnemyColor();
    
    // 根据敌人类型绘制不同形状
    switch (type) {
      case EnemyType.normal:
        // 普通敌人 - 红色小型战机
        
        // 主体 - 深红色
        paint.color = Colors.red.shade900;
        canvas.drawRect(
          Rect.fromLTWH(
            enemyWidth / 2 - pixelSize * 2,
            0,
            pixelSize * 4,
            enemyHeight * 0.8
          ),
          paint
        );
        
        // 机翼 - 红色
        paint.color = Colors.red;
        
        // 左机翼
        canvas.drawRect(
          Rect.fromLTWH(
            0,
            enemyHeight * 0.3,
            pixelSize * 4,
            pixelSize * 2
          ),
          paint
        );
        
        // 右机翼
        canvas.drawRect(
          Rect.fromLTWH(
            enemyWidth - pixelSize * 4,
            enemyHeight * 0.3,
            pixelSize * 4,
            pixelSize * 2
          ),
          paint
        );
        
        // 引擎火焰 - 橙色
        paint.color = Colors.orange;
        canvas.drawRect(
          Rect.fromLTWH(
            enemyWidth / 2 - pixelSize,
            enemyHeight * 0.8,
            pixelSize * 2,
            pixelSize * 2
          ),
          paint
        );
        
        break;
        
      case EnemyType.elite:
        // 精英敌人 - 紫色中型战机
        
        // 主体 - 深紫色
        paint.color = Colors.purple.shade900;
        canvas.drawRect(
          Rect.fromLTWH(
            enemyWidth / 2 - pixelSize * 2,
            0,
            pixelSize * 4,
            enemyHeight * 0.7
          ),
          paint
        );
        
        // 机翼 - 紫色
        paint.color = Colors.purple;
        
        // 左机翼
        canvas.drawRect(
          Rect.fromLTWH(
            0,
            enemyHeight * 0.2,
            pixelSize * 5,
            pixelSize * 3
          ),
          paint
        );
        
        // 右机翼
        canvas.drawRect(
          Rect.fromLTWH(
            enemyWidth - pixelSize * 5,
            enemyHeight * 0.2,
            pixelSize * 5,
            pixelSize * 3
          ),
          paint
        );
        
        // 武器
        paint.color = Colors.purpleAccent;
        
        // 左武器
        canvas.drawRect(
          Rect.fromLTWH(
            pixelSize * 2,
            enemyHeight * 0.5,
            pixelSize * 2,
            pixelSize * 4
          ),
          paint
        );
        
        // 右武器
        canvas.drawRect(
          Rect.fromLTWH(
            enemyWidth - pixelSize * 4,
            enemyHeight * 0.5,
            pixelSize * 2,
            pixelSize * 4
          ),
          paint
        );
        
        // 引擎火焰 - 亮紫色
        paint.color = Colors.purpleAccent;
        canvas.drawRect(
          Rect.fromLTWH(
            enemyWidth / 2 - pixelSize * 2,
            enemyHeight * 0.7,
            pixelSize * 4,
            pixelSize * 3
          ),
          paint
        );
        
        break;
        
      case EnemyType.boss:
        // Boss敌人 - 绿色大型战机
        
        // 主体 - 深绿色
        paint.color = Colors.green.shade900;
        canvas.drawRect(
          Rect.fromLTWH(
            enemyWidth / 2 - pixelSize * 4,
            pixelSize * 2,
            pixelSize * 8,
            enemyHeight * 0.8
          ),
          paint
        );
        
        // 机翼 - 绿色
        paint.color = Colors.green;
        
        // 左机翼
        canvas.drawRect(
          Rect.fromLTWH(
            0,
            enemyHeight * 0.3,
            pixelSize * 6,
            pixelSize * 5
          ),
          paint
        );
        
        // 右机翼
        canvas.drawRect(
          Rect.fromLTWH(
            enemyWidth - pixelSize * 6,
            enemyHeight * 0.3,
            pixelSize * 6,
            pixelSize * 5
          ),
          paint
        );
        
        // 武器 - 黄绿色
        paint.color = Colors.lightGreen;
        
        // 左武器1
        canvas.drawRect(
          Rect.fromLTWH(
            pixelSize * 2,
            pixelSize * 2,
            pixelSize * 2,
            pixelSize * 4
          ),
          paint
        );
        
        // 右武器1
        canvas.drawRect(
          Rect.fromLTWH(
            enemyWidth - pixelSize * 4,
            pixelSize * 2,
            pixelSize * 2,
            pixelSize * 4
          ),
          paint
        );
        
        // 左武器2
        canvas.drawRect(
          Rect.fromLTWH(
            pixelSize * 4,
            pixelSize * 6,
            pixelSize * 2,
            pixelSize * 6
          ),
          paint
        );
        
        // 右武器2
        canvas.drawRect(
          Rect.fromLTWH(
            enemyWidth - pixelSize * 6,
            pixelSize * 6,
            pixelSize * 2,
            pixelSize * 6
          ),
          paint
        );
        
        // 头部 - 绿色
        paint.color = Colors.greenAccent;
        canvas.drawRect(
          Rect.fromLTWH(
            enemyWidth / 2 - pixelSize * 3,
            0,
            pixelSize * 6,
            pixelSize * 4
          ),
          paint
        );
        
        // 引擎火焰 - 黄色
        paint.color = Colors.yellow;
        canvas.drawRect(
          Rect.fromLTWH(
            enemyWidth / 2 - pixelSize * 3,
            enemyHeight * 0.8,
            pixelSize * 6,
            pixelSize * 4
          ),
          paint
        );
        
        break;
    }
  }
  
  // 绘制护盾效果
  void _drawShield(Canvas canvas) {
    final shieldRadius = max(size.x, size.y) * 0.6;
    final shieldOpacity = 0.3 + (sin(_movementTime * 5) + 1) * 0.1;
    
    // 绘制多层护盾
    for (int i = 1; i <= 3; i++) {
      final radius = shieldRadius * (1 + (i-1) * 0.1);
      final layerOpacity = shieldOpacity / i;
      
      final shieldPaint = Paint()
        ..color = Colors.lightBlue.withOpacity(layerOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        radius,
        shieldPaint,
      );
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 已击败的敌人不再更新
    if (_defeated) return;
    
    // 更新移动
    _updateMovement(dt);
    
    // 更新射击逻辑
    _updateShooting(dt);
    
    // 更新闪烁效果
    if (_flashIntensity > 0) {
      _flashTime += dt;
      _flashIntensity *= (1 - dt * 10); // 快速衰减
      if (_flashIntensity < 0.05) {
        _flashIntensity = 0;
      }
    }
  }
  
  // 更新移动
  void _updateMovement(double dt) {
    try {
      if (gameRef.gameState != GameState.playing) return;
      
      // 更新移动时间
      _movementTime += dt;
      
      // 根据移动模式更新方向
      _updateDirection(dt);
      
      // 移动敌人
      position += _direction * speed * dt;
      
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
  
  // 更新射击逻辑
  void _updateShooting(double dt) {
    if (gameRef.gameState != GameState.playing) return;
    if (_shootCooldown > 0) {
      _shootCooldown -= dt;
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
  
  /// 敌人被击败
  void defeat() {
    // 标记为已被击败
    _defeated = true;
    
    // 增加玩家分数
    gameRef.score += scoreValue;
    
    // 创建爆炸效果
    gameRef.add(
      ExplosionComponent(
        position: position.clone(),
        primaryColor: _getExplosionColor(),
        secondaryColor: Colors.yellow,
        initialRadius: size.x / 3,
        maxRadius: size.x * 1.5,
        duration: 0.8,
      ),
    );
    
    // 随机掉落能量道具（根据敌人类型有不同概率）
    double powerUpChance;
    switch (type) {
      case EnemyType.normal:
        powerUpChance = 0.05; // 5%几率
        break;
      case EnemyType.elite:
        powerUpChance = 0.15; // 15%几率
        break;
      case EnemyType.boss:
        powerUpChance = 1.0; // 100%几率，Boss必定掉落
        break;
    }
    
    if (_random.nextDouble() < powerUpChance) {
      // 随机能量道具类型
      PowerUpType powerUpType;
      
      // Boss会掉落随机道具，其他敌人根据一定权重掉落
      if (type == EnemyType.boss) {
        powerUpType = PowerUpType.values[_random.nextInt(PowerUpType.values.length)];
      } else {
        // 简单加权随机：武器升级占50%，护盾30%，生命20%
        final roll = _random.nextDouble();
        if (roll < 0.5) {
          powerUpType = PowerUpType.weapon;
        } else if (roll < 0.8) {
          powerUpType = PowerUpType.shield;
        } else {
          powerUpType = PowerUpType.health;
        }
      }
      
      // 生成能量道具
      gameRef.spawnPowerUp(position.clone(), type: powerUpType);
    }
    
    // 播放爆炸音效
    gameRef.audioService.playExplosionSound();
    
    // 延迟一帧移除组件，以便完成当前帧的逻辑
    Future.delayed(Duration.zero, removeFromParent);
  }
  
  /// 获取敌人爆炸颜色
  Color _getExplosionColor() {
    switch (type) {
      case EnemyType.normal:
        return Colors.red.shade700;
      case EnemyType.elite:
        return Colors.purple.shade700;
      case EnemyType.boss:
        return Colors.green.shade700;
    }
  }
  
  /// 击中敌人
  void hit(int damage) {
    health -= damage;
    
    // 替换ColorEffect为自定义闪烁效果
    _flashColor = Colors.white;
    _flashIntensity = 0.8;
    _flashTime = 0;
    
    if (health <= 0) {
      // 敌人被击败
      defeat();
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
      other.takeDamage(1);
    }
  }
}