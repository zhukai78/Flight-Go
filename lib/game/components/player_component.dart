import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;
import '../flight_go_game.dart';
import 'bullet_component.dart';
import 'enemy_component.dart';
import 'engine_flame_component.dart';
import 'explosion_component.dart';
import 'power_up_component.dart';
import 'bullet_trail_component.dart';

/// 玩家飞机组件
class PlayerComponent extends PositionComponent with HasGameRef<FlightGoGame>, CollisionCallbacks {
  // 玩家生命值
  int _health = 3;
  int get health => _health;
  set health(int value) {
    _health = value;
    // 生命值为0时游戏结束
    if (_health <= 0) {
      _die();
    }
  }
  
  // 移动速度
  final double _speed = 5.0;
  double get speed => _speed;
  
  // 最大移动速度
  double maxSpeed = 400.0;
  
  // 当前移动向量
  Vector2 _velocity = Vector2.zero();
  
  // 射击冷却时间
  double _shootCooldown = 0.0;
  
  // 武器等级 (1-3)
  int _weaponLevel = 1;
  int get weaponLevel => _weaponLevel;
  set weaponLevel(int value) {
    _weaponLevel = value.clamp(1, 3);
    
    // 级别提高时播放升级效果
    if (value > _weaponLevel) {
      // 使用自定义闪烁效果替代ColorEffect
      _flashColor = Colors.blue;
      _flashIntensity = 0.8;
      _flashTime = 0;
    }
  }
  
  // 无敌时间
  double _invincibleTime = 0.0;
  bool get isInvincible => _invincibleTime > 0;
  
  // 动画计时器
  double _animationTime = 0.0;
  
  // 引擎特效计时器
  double _engineEffectTime = 0.0;
  
  // 随机数生成器
  final Random _random = Random();
  
  // 引擎粒子
  final List<_EngineParticle> _engineParticles = [];
  
  // 自定义画笔
  late Paint _shipPaint;
  
  // 透明度 (用于无敌效果和护盾闪烁)
  double opacity = 1.0;
  
  // 护盾是否激活
  final bool _shieldActive = false;
  
  // 闪烁效果控制变量
  Color _flashColor = Colors.transparent;
  double _flashIntensity = 0.0;
  double _flashTime = 0.0;
  
  // 震动相关变量
  bool _isShaking = false;
  double _shakeTime = 0.0;
  double _shakeDuration = 0.0;
  Vector2 _shakeOffset = Vector2.zero();
  int _shakeCount = 0;
  double _shakeAmount = 0.0;
  
  PlayerComponent() : super(size: Vector2(48, 48)) {
    anchor = Anchor.center;
    // 初始化画笔
    _shipPaint = Paint()..color = Colors.blue;
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 设置玩家位置在屏幕底部中央
    position = Vector2(
      gameRef.size.x / 2,
      gameRef.size.y - 100,
    );
    
    // 不再尝试加载精灵图，直接使用自定义绘制
    
    // 添加碰撞检测 - 修改为active类型，让玩家能主动检测碰撞
    add(
      RectangleHitbox()
        ..collisionType = CollisionType.active
    );
    
    // 初始化引擎粒子
    for (int i = 0; i < 20; i++) {
      _engineParticles.add(_EngineParticle());
    }
    
    // 开始自动射击
    add(
      TimerComponent(
        period: 0.2,
        repeat: true,
        onTick: _autoShoot,
      ),
    );
  }
  
  @override
  void render(Canvas canvas) {
    try {
      // 保存画布状态
      canvas.save();
      
      // 应用震动偏移
      if (_isShaking) {
        canvas.translate(_shakeOffset.x, _shakeOffset.y);
      }
      
      // 应用透明度
      final paint = Paint()
        ..color = Colors.blue.withOpacity(opacity);
      
      // 绘制主飞船
      _drawSpaceship(canvas, paint);
      
      // 绘制引擎效果
      _renderEngineEffect(canvas);
      
      // 应用闪烁效果
      if (_flashIntensity > 0) {
        final flashPaint = Paint()
          ..color = _flashColor.withOpacity(_flashIntensity * 0.7)
          ..style = PaintingStyle.fill;
        
        // 绘制闪烁效果
        canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), flashPaint);
      }
      
      // 恢复画布状态
      canvas.restore();
    } catch (e) {
      // 捕获渲染错误
      debugPrint('玩家飞船渲染错误: $e');
      
      // 尝试恢复画布状态
      try {
        canvas.restore();
      } catch (_) {
        // 忽略恢复失败
      }
      
      // 尝试使用降级的渲染方式
      try {
        // 非常简单的降级渲染
        final simplePaint = Paint()
          ..color = Colors.blue.withOpacity(0.8)
          ..style = PaintingStyle.fill;
        
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.x, size.y),
          simplePaint,
        );
      } catch (_) {
        // 忽略所有错误，确保不会崩溃
      }
    }
  }
  
  // 绘制自定义飞机
  void _drawSpaceship(Canvas canvas, Paint paint) {
    try {
      // 飞机尺寸
      final shipWidth = size.x;
      final shipHeight = size.y;
      final pixelSize = shipWidth / 16; // 像素大小
      
      // 使用传入的画笔
      final mainPaint = Paint()
        ..color = Colors.blue.shade600.withOpacity(opacity);
      
      // 飞机主体
      canvas.drawRect(
        Rect.fromLTWH(
          shipWidth / 2 - pixelSize * 2,
          pixelSize * 2,
          pixelSize * 4,
          shipHeight - pixelSize * 6
        ),
        mainPaint,
      );
      
      // 机翼 - 浅蓝色
      final wingPaint = Paint()
        ..color = Colors.blue.shade400.withOpacity(opacity);
      
      // 左机翼
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          shipHeight * 0.4,
          pixelSize * 6,
          pixelSize * 3
        ),
        wingPaint,
      );
      
      // 右机翼
      canvas.drawRect(
        Rect.fromLTWH(
          shipWidth - pixelSize * 6,
          shipHeight * 0.4,
          pixelSize * 6,
          pixelSize * 3
        ),
        wingPaint,
      );
      
      // 机头 - 亮蓝色
      final cockpitPaint = Paint()
        ..color = Colors.lightBlue.withOpacity(opacity);
      
      canvas.drawRect(
        Rect.fromLTWH(
          shipWidth / 2 - pixelSize * 1.5,
          0,
          pixelSize * 3,
          pixelSize * 4
        ),
        cockpitPaint,
      );
      
      // 引擎 - 黄色
      final enginePaint = Paint()
        ..color = Colors.orange.withOpacity(opacity);
      
      // 中央引擎
      canvas.drawRect(
        Rect.fromLTWH(
          shipWidth / 2 - pixelSize,
          shipHeight - pixelSize * 4,
          pixelSize * 2,
          pixelSize * 4
        ),
        enginePaint,
      );
      
      // 武器 - 根据武器等级显示不同数量
      final weaponPaint = Paint()
        ..color = Colors.cyanAccent.withOpacity(opacity);
      
      // 武器等级对应显示的武器数量
      for (int i = 0; i < _weaponLevel; i++) {
        // 武器的位置根据等级和索引计算
        double weaponX;
        if (_weaponLevel == 1) {
          weaponX = shipWidth / 2 - pixelSize;
        } else if (_weaponLevel == 2) {
          weaponX = (i == 0) ? pixelSize * 2 : shipWidth - pixelSize * 4;
        } else {
          if (i == 0) {
            weaponX = pixelSize * 2;
          } else if (i == 1) {
            weaponX = shipWidth / 2 - pixelSize;
          } else {
            weaponX = shipWidth - pixelSize * 4;
          }
        }
        
        canvas.drawRect(
          Rect.fromLTWH(
            weaponX,
            pixelSize * 2,
            pixelSize * 2,
            pixelSize * 2
          ),
          weaponPaint,
        );
      }
      
      // 如果护盾激活，绘制护盾
      if (_shieldActive) {
        final shieldPaint = Paint()
          ..color = Colors.lightBlueAccent.withOpacity(0.4 + sin(_animationTime * 5) * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        
        canvas.drawCircle(
          Offset(shipWidth / 2, shipHeight / 2),
          shipWidth * 0.75,
          shieldPaint,
        );
      }
    } catch (e) {
      debugPrint('绘制飞船错误: $e');
      
      // 降级渲染 - 只绘制一个简单的矩形表示飞船
      try {
        final fallbackPaint = Paint()
          ..color = Colors.blue.withOpacity(opacity);
        
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.x, size.y),
          fallbackPaint,
        );
      } catch (_) {
        // 忽略任何错误
      }
    }
  }
  
  // 渲染引擎效果
  void _renderEngineEffect(Canvas canvas) {
    try {
      // 引擎位置
      final engineX = size.x / 2;
      final engineY = size.y * 0.8;
      final engineWidth = size.x * 0.2;
      
      // 绘制所有粒子
      for (final particle in _engineParticles) {
        if (particle.isActive) {
          // 计算粒子实际位置
          final x = engineX + (particle.offset.x * engineWidth) - particle.size / 2;
          final y = engineY + particle.position * size.y * 0.3;
          
          // 基于生命周期设置不透明度
          final particleOpacity = (1.0 - particle.position) * 0.8;
          
          final paint = Paint()
            ..color = particle.color.withOpacity(particleOpacity * opacity);
          
          // 绘制粒子
          canvas.drawCircle(
            Offset(x, y),
            particle.size,
            paint,
          );
        }
      }
      
      // 引擎光晕 - 脉动效果
      final glowIntensity = (sin(_engineEffectTime * 10) + 1) * 0.3 + 0.4;
      
      // 绘制多层光晕以模拟辉光
      for (int i = 1; i <= 3; i++) {
        final radius = engineWidth * (0.5 + i * 0.5) * glowIntensity;
        final glowOpacity = 0.3 * glowIntensity / i;
        
        final glowPaint = Paint()
          ..color = Colors.blue.withOpacity(glowOpacity * opacity)
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(
          Offset(engineX, engineY),
          radius,
          glowPaint,
        );
      }
    } catch (e) {
      // 捕获引擎粒子渲染错误但不输出日志，避免过多日志
    }
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
      
      // 无敌闪烁效果
      opacity = (sin(_invincibleTime * 15) * 0.5 + 0.5);
    } else {
      opacity = 1.0;
    }
    
    // 更新武器特效
    _animationTime += dt;
    
    // 更新引擎效果
    _engineEffectTime += dt;
    if (_engineEffectTime >= 0.05) {
      _engineEffectTime = 0;
      _addEngineParticle();
    }
    
    // 更新引擎粒子
    for (int i = _engineParticles.length - 1; i >= 0; i--) {
      final particle = _engineParticles[i];
      particle.update(dt);
      if (particle.isDead) {
        _engineParticles.removeAt(i);
      }
    }
    
    // 更新闪烁效果
    if (_flashIntensity > 0) {
      _flashTime += dt;
      _flashIntensity *= (1 - dt * 5); // 逐渐衰减闪烁强度
      if (_flashIntensity < 0.05) {
        _flashIntensity = 0;
      }
    }
    
    // 更新震动效果
    if (_isShaking) {
      _shakeTime += dt;
      if (_shakeTime > _shakeDuration) {
        _isShaking = false;
        _shakeOffset = Vector2.zero();
      } else {
        // 计算震动偏移
        final progress = _shakeTime / _shakeDuration;
        final intensity = sin(progress * _shakeCount * pi * 2) * _shakeAmount * (1 - progress);
        _shakeOffset.x = intensity;
      }
    }
    
    // 应用惯性移动
    if (_velocity.length > 0) {
      // 平滑移动
      position += _velocity * dt;
      
      // 缓慢减速 (摩擦力) - 增加阻尼使移动停止更快
      _velocity *= (0.9 - dt * 2).clamp(0.7, 0.99);
      
      // 如果速度很小，设为零
      if (_velocity.length < 0.5) {
        _velocity = Vector2.zero();
      }
      
      // 确保不超出屏幕边界
      _clampPosition();
    }
  }
  
  // 处理碰撞
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    // 如果无敌，忽略碰撞
    if (isInvincible) return;
    
    // 与敌人子弹碰撞
    if (other is BulletComponent && !other.isPlayerBullet) {
      _takeDamage(other.damage);
      other.destroy();
    }
    // 与敌人碰撞
    else if (other is EnemyComponent) {
      _takeDamage(1);
      // 对敌人也造成伤害
      other.hit(1);
    }
    // 与能量道具碰撞
    else if (other is PowerUpComponent) {
      // PowerUpComponent会在其onCollision中处理
    }
  }
  
  // 收集能量道具
  void _collectPowerUp(PowerUpComponent powerUp) {
    // 根据道具类型应用效果
    switch (powerUp.type) {
      case PowerUpType.health:
        health = min(health + 1, 5);  // 最大生命值为5
        break;
      case PowerUpType.weapon:
        weaponLevel = min(weaponLevel + 1, 3);  // 最大武器等级为3
        break;
      case PowerUpType.shield:
        // 激活护盾 (3秒无敌)
        _invincibleTime = 3.0;
        break;
    }
    
    // 播放收集音效
    gameRef.audioService.playPowerupSound();
  }
  
  // 激活炸弹
  void _activateBomb() {
    // 为所有敌人施加伤害
    final enemies = gameRef.children.query<EnemyComponent>();
    for (final enemy in enemies) {
      enemy.hit(10);  // 对大多数敌人是致命的
    }
    
    // 添加炸弹特效 - 全屏闪烁
    gameRef.add(
      ScreenFlashEffect(
        color: Colors.white,
        duration: 0.3,
      ),
    );
  }
  
  // 承受伤害
  void _takeDamage(int amount) {
    // 扣除生命值
    health -= amount;
    
    // 替换ColorEffect为自定义闪烁效果
    _flashColor = Colors.red;
    _flashIntensity = 1.0;
    _flashTime = 0;
    
    // 短暂无敌
    _invincibleTime = 1.5;
    
    // 使用自定义震动效果替代MoveEffect
    _startShake();
    
    // 播放受伤音效
    gameRef.audioService.playExplosionSound();
  }
  
  // 玩家死亡
  void _die() {
    // 播放爆炸特效
    gameRef.add(
      ExplosionEffect(
        position: position.clone(),
        size: size * 2,
        color: Colors.orange,
      ),
    );
    
    // 播放死亡音效
    gameRef.audioService.playExplosionSound();
    
    // 移除组件
    removeFromParent();
    
    // 游戏结束
    gameRef.gameState = GameState.gameOver;
  }
  
  // 移动飞机 (由FlightGoGame调用)
  void move(Vector2 delta) {
    // 计算目标速度，但限制最大速度
    _velocity += delta * 10; // 降低惯性系数，使移动更精确
    if (_velocity.length > maxSpeed) {
      _velocity = _velocity.normalized() * maxSpeed;
    }
    
    // 同时直接移动一部分距离，这样飞机会更紧密地跟随手指
    position += delta * 0.5;
    
    // 限制玩家不超出屏幕边界
    _clampPosition();
  }
  
  // 直接移动飞机到指定位置（绝对位置）
  void absoluteMove(Vector2 targetPosition) {
    // 平滑插值到目标位置
    final oldPos = position.clone();
    position = Vector2(
      lerpDouble(position.x, targetPosition.x, 0.5) ?? position.x, 
      lerpDouble(position.y, targetPosition.y, 0.5) ?? position.y
    );
    
    // 更新速度矢量，便于移动结束后还有平滑的惯性
    _velocity = (position - oldPos) * 10;
    
    // 限制玩家不超出屏幕边界
    _clampPosition();
  }
  
  // 辅助方法：限制飞机位置在屏幕内
  void _clampPosition() {
    position.x = position.x.clamp(
      size.x / 2,
      gameRef.size.x - size.x / 2,
    );
    position.y = position.y.clamp(
      size.y / 2,
      gameRef.size.y - size.y / 2,
    );
  }
  
  // 自动射击
  void _autoShoot() {
    // 只在游戏进行中且冷却结束时射击
    if (gameRef.gameState != GameState.playing || _shootCooldown > 0) {
      return;
    }
    
    // 根据武器等级发射不同模式的子弹
    switch (_weaponLevel) {
      case 1:
        // 单发直射
        _fireBullet(Vector2(0, -1));
        break;
      
      case 2:
        // 双发平行射击
        _fireBullet(Vector2(-0.1, -1), Vector2(position.x - 10, position.y));
        _fireBullet(Vector2(0.1, -1), Vector2(position.x + 10, position.y));
        break;
      
      case 3:
        // 三发散射
        _fireBullet(Vector2(-0.2, -1), Vector2(position.x - 15, position.y));
        _fireBullet(Vector2(0, -1));
        _fireBullet(Vector2(0.2, -1), Vector2(position.x + 15, position.y));
        break;
    }
    
    // 设置射击冷却，冷却时间随武器等级减少
    _shootCooldown = 0.3 / _weaponLevel;
  }
  
  // 发射子弹
  void _fireBullet(Vector2 direction, [Vector2? shootPosition]) {
    // 设置发射位置
    final bulletPosition = shootPosition ?? Vector2(position.x, position.y - size.y * 0.5);
    
    // 获取子弹
    final bullet = gameRef.getPlayerBullet(
      position: bulletPosition,
      direction: direction.normalized(),
      speed: 600.0,
      damage: _weaponLevel, // 伤害随武器等级增加
    );
    
    // 子弹尾迹
    gameRef.add(
      BulletTrailComponent(
        position: bulletPosition.clone(),
        velocity: direction.normalized() * 600.0 * 0.5,
        color: Colors.blue,
        initialSize: 4.0,
        isPlayerBullet: true,
      ),
    );
  }

  // 升级武器
  void powerUp() {
    weaponLevel = min(weaponLevel + 1, 3);  // 最大武器等级为3
  }
  
  // 添加护盾
  void addShield() {
    // 激活护盾（3秒无敌）
    _invincibleTime = 3.0;
  }
  
  // 恢复生命
  void heal() {
    health = min(health + 1, 5);  // 最大生命值为5
  }

  // 公开的受伤方法
  void takeDamage([int amount = 1]) {
    _takeDamage(amount);
  }

  // 开始震动效果
  void _startShake({double amount = 5.0, double duration = 0.4, int count = 4}) {
    _isShaking = true;
    _shakeTime = 0.0;
    _shakeDuration = duration;
    _shakeCount = count;
    _shakeAmount = amount;
  }

  // 添加引擎粒子
  void _addEngineParticle() {
    final particleSize = 1.0 + _random.nextDouble() * 2.0;
    final particleSpeed = 0.5 + _random.nextDouble() * 0.5;
    final colorValue = _random.nextDouble();
    final color = colorValue < 0.7 
      ? Colors.blue.shade300
      : Colors.white;
      
    // 创建引擎粒子
    final particle = _EngineParticle();
    particle.activate();
    particle.size = particleSize;
    particle.speed = particleSpeed;
    particle.color = color;
    particle.offset = Vector2(
      (_random.nextDouble() - 0.5) * 0.8,
      0,
    );
    
    // 添加到粒子列表
    _engineParticles.add(particle);
  }
}

/// 引擎粒子 - 用于引擎特效
class _EngineParticle {
  // 粒子位置 (0-1)
  double position = 0.0;
  
  // 粒子大小
  double size = 1.0;
  
  // 粒子颜色
  Color color = Colors.white;
  
  // 粒子水平偏移
  Vector2 offset = Vector2.zero();
  
  // 粒子是否激活
  bool isActive = false;
  
  // 粒子速度
  double speed = 1.0;
  
  // 粒子是否已经死亡
  bool isDead = false;
  
  // 随机数生成器
  static final Random _random = Random();
  
  // 更新粒子
  void update(double dt) {
    if (isActive) {
      // 向下移动
      position += speed * dt * 2;
      
      // 如果超出范围，重置
      if (position > 1.0) {
        reset();
      }
    } else if (_random.nextDouble() < 0.1) {
      // 有10%概率激活休眠的粒子
      activate();
    }
  }
  
  // 重置粒子
  void reset() {
    isActive = false;
    position = 0.0;
  }
  
  // 激活粒子
  void activate() {
    isActive = true;
    position = 0.0;
    size = 1.0 + _random.nextDouble() * 2.0;
    
    // 随机颜色 - 蓝色和白色
    final colorValue = _random.nextDouble();
    color = colorValue < 0.7 
      ? Colors.blue.shade300
      : Colors.white;
    
    // 随机水平偏移
    offset = Vector2(
      _random.nextDouble() - 0.5,
      0,
    );
    
    // 随机速度
    speed = 0.5 + _random.nextDouble() * 0.5;
  }
  
  // 绘制粒子
  void render(Canvas canvas) {
    // 该方法不再需要实现，由PlayerComponent中的_renderEngineEffect处理
  }
}

/// 全屏闪烁特效
class ScreenFlashEffect extends Component with HasGameRef<FlightGoGame> {
  // 颜色
  final Color color;
  
  // 持续时间
  final double duration;
  
  // 当前时间
  double _time = 0.0;
  
  ScreenFlashEffect({
    required this.color,
    required this.duration,
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
  
  @override
  void render(Canvas canvas) {
    // 计算不透明度
    final opacity = 1.0 - (_time / duration);
    
    // 绘制全屏矩形
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y),
      Paint()..color = color.withOpacity(opacity),
    );
  }
}

/// 爆炸特效
class ExplosionEffect extends Component with HasGameRef<FlightGoGame> {
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
  
  // 粒子列表
  final List<_ExplosionParticle> _particles = [];
  
  // 随机数生成器
  final Random _random = Random();
  
  // 渲染错误标志
  bool _hasRenderError = false;
  
  ExplosionEffect({
    required this.position,
    required this.size,
    this.color = Colors.orange,
    this.duration = 0.5,
  }) {
    // 创建爆炸粒子
    for (int i = 0; i < 30; i++) {
      _particles.add(_ExplosionParticle(
        position: Vector2.zero(),
        velocity: Vector2(
          (_random.nextDouble() - 0.5) * 200,
          (_random.nextDouble() - 0.5) * 200,
        ),
        size: 1.0 + _random.nextDouble() * 3.0,
        color: _getRandomExplosionColor(),
      ));
    }
  }
  
  // 获取随机爆炸颜色
  Color _getRandomExplosionColor() {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      color,
    ];
    return colors[_random.nextInt(colors.length)];
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 更新时间
    _time += dt;
    
    // 更新粒子
    for (final particle in _particles) {
      particle.update(dt);
    }
    
    // 完成后移除
    if (_time >= duration) {
      removeFromParent();
    }
  }
  
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
  
  @override
  void render(Canvas canvas) {
    // 如果之前渲染出现过错误，采用简化渲染
    if (_hasRenderError) {
      _renderSimplified(canvas);
      return;
    }
    
    try {
      // 保存画布状态
      canvas.save();
      
      // 移动到爆炸中心
      canvas.translate(position.x, position.y);
      
      // 绘制爆炸光晕
      final glowOpacity = (1.0 - (_time / duration)).clamp(0.0, 1.0);
      
      // 绘制多层光晕以模拟模糊效果
      for (int i = 1; i <= 3; i++) {
        final radius = size.x * (0.5 + _time / duration * 0.5) * (1 + (i-1) * 0.3);
        final layerOpacity = (glowOpacity * 0.7 / i).clamp(0.0, 1.0);
        
        final glowPaint = Paint()
          ..color = withSafeOpacity(color, layerOpacity)
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(
          Offset.zero,
          radius,
          glowPaint,
        );
      }
      
      // 绘制粒子
      for (final particle in _particles) {
        final particleOpacity = glowOpacity.clamp(0.0, 1.0);
        final paint = Paint()
          ..color = withSafeOpacity(particle.color, particleOpacity);
        
        canvas.drawCircle(
          Offset(particle.position.x, particle.position.y),
          particle.size,
          paint,
        );
      }
      
      // 恢复画布
      canvas.restore();
    } catch (e) {
      _hasRenderError = true;
      debugPrint('爆炸特效渲染错误: $e');
      
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
      final safeOpacity = (1.0 - (_time / duration)).clamp(0.0, 1.0);
      final simplePaint = Paint()
        ..color = Colors.orange.withOpacity(safeOpacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(position.x, position.y),
        size.x * 0.3,
        simplePaint,
      );
    } catch (_) {
      // 忽略所有错误，确保不会崩溃
    }
  }
}

/// 爆炸粒子
class _ExplosionParticle {
  // 位置
  final Vector2 position;
  
  // 速度
  final Vector2 velocity;
  
  // 大小
  final double size;
  
  // 颜色
  final Color color;
  
  _ExplosionParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
  });
  
  // 更新粒子
  void update(double dt) {
    // 应用速度
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;
    
    // 减慢速度 (摩擦力)
    velocity.scale(0.95);
  }
}