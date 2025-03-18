import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flight_go_game.dart';
import 'bullet_component.dart';

/// 子弹对象池，用于优化子弹的创建和销毁
class BulletPool extends Component with HasGameRef<FlightGoGame> {
  // 最大池大小
  final int maxPoolSize;
  
  // 子弹池
  final List<BulletComponent> _playerBulletPool = [];
  final List<BulletComponent> _enemyBulletPool = [];
  
  BulletPool({this.maxPoolSize = 100});
  
  /// 获取一个玩家子弹
  BulletComponent getPlayerBullet({
    required Vector2 position,
    Vector2? direction,
    double speed = 300,
    int damage = 1,
  }) {
    final bulletDirection = direction ?? Vector2(0, -1);
    
    if (_playerBulletPool.isNotEmpty) {
      final bullet = _playerBulletPool.removeLast();
      bullet.position = position;
      bullet.direction = bulletDirection;
      bullet.speed = speed;
      bullet.damage = damage;
      bullet.angle = bulletDirection.angleToSigned(Vector2(0, -1));
      return bullet;
    } else {
      return BulletComponent(
        position: position,
        direction: bulletDirection,
        isPlayerBullet: true,
        speed: speed,
        damage: damage,
      );
    }
  }
  
  /// 获取一个敌人子弹
  BulletComponent getEnemyBullet({
    required Vector2 position,
    Vector2? direction,
    double speed = 150,
    int damage = 1,
  }) {
    final bulletDirection = direction ?? Vector2(0, 1);
    
    if (_enemyBulletPool.isNotEmpty) {
      final bullet = _enemyBulletPool.removeLast();
      bullet.position = position;
      bullet.direction = bulletDirection;
      bullet.speed = speed;
      bullet.damage = damage;
      bullet.angle = bulletDirection.angleToSigned(Vector2(0, -1));
      return bullet;
    } else {
      return BulletComponent(
        position: position,
        direction: bulletDirection,
        isPlayerBullet: false,
        speed: speed,
        damage: damage,
      );
    }
  }
  
  /// 回收子弹到对象池
  void returnBullet(BulletComponent bullet) {
    if (bullet.isPlayerBullet) {
      if (_playerBulletPool.length < maxPoolSize) {
        _playerBulletPool.add(bullet);
      }
    } else {
      if (_enemyBulletPool.length < maxPoolSize) {
        _enemyBulletPool.add(bullet);
      }
    }
  }
} 