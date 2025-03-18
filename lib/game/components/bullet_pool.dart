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
      // 由于BulletComponent的属性是final的，我们无法修改它们
      // 所以为了重用对象，我们需要把旧的从池中移除，然后创建一个新的
      _playerBulletPool.removeLast();
    }
    
    // 创建新的子弹实例
    return BulletComponent(
      position: position,
      direction: bulletDirection,
      isPlayerBullet: true,
      speed: speed,
      damage: damage,
      size: Vector2(4, 8), // 设置子弹大小
      color: Colors.blue, // 玩家子弹颜色
    );
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
      // 同样，我们也不能修改敌人子弹的属性
      _enemyBulletPool.removeLast();
    }
    
    // 创建新的子弹实例
    return BulletComponent(
      position: position,
      direction: bulletDirection,
      isPlayerBullet: false,
      speed: speed,
      damage: damage,
      size: Vector2(6, 6), // 设置敌人子弹大小
      color: Colors.red, // 敌人子弹颜色
    );
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