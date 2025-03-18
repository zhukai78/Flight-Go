import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../flight_go_game.dart';
import 'player_component.dart';

/// 能量道具类型
enum PowerUpType {
  weapon,  // 武器升级
  shield,  // 护盾
  health,  // 恢复生命
}

/// 能量道具组件
class PowerUpComponent extends PositionComponent with HasGameRef<FlightGoGame>, CollisionCallbacks {
  // 道具类型
  final PowerUpType type;
  
  // 移动速度
  final double speed;
  
  // 动画状态
  double _animationTime = 0;
  
  // 旋转角度
  double _rotation = 0;
  
  // 脉冲缩放因子
  double _pulseScale = 1.0;
  
  // 随机数生成器
  final Random _random = Random();
  
  // 构造函数
  PowerUpComponent({
    required Vector2 position,
    required this.type,
    this.speed = 50.0,
  }) : super(
    position: position,
    size: Vector2.all(24),
    anchor: Anchor.center,
  );
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 添加碰撞检测
    add(CircleHitbox());
    
    // 随机初始旋转角度
    _rotation = _random.nextDouble() * pi * 2;
  }
  
  @override
  void render(Canvas canvas) {
    // 保存画布状态
    canvas.save();
    
    // 道具尺寸
    final size = this.size.x;
    final pixelSize = size / 8;  // 像素粒度
    
    // 计算缩放和旋转 - 使用更平滑的旋转和缩放
    canvas.translate(size / 2, size / 2);
    // 减少旋转角度的变化速度
    canvas.rotate(_rotation * 0.7);
    // 使用更小的缩放范围，减少视觉抖动
    canvas.scale(_pulseScale);
    canvas.translate(-size / 2, -size / 2);
    
    // 画笔 - 使用抗锯齿
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    
    // 根据道具类型绘制不同的外观
    switch (type) {
      case PowerUpType.weapon:
        // 武器升级 - 蓝色，子弹形状
        
        // 外框 - 深蓝色
        paint.color = Colors.blue.shade900;
        canvas.drawRect(
          Rect.fromLTWH(
            size / 2 - pixelSize * 3,
            size / 2 - pixelSize * 3,
            pixelSize * 6,
            pixelSize * 6
          ),
          paint
        );
        
        // 内部 - 亮蓝色
        paint.color = Colors.blue.shade400;
        canvas.drawRect(
          Rect.fromLTWH(
            size / 2 - pixelSize * 2,
            size / 2 - pixelSize * 2,
            pixelSize * 4,
            pixelSize * 4
          ),
          paint
        );
        
        // 中心 - 最亮
        paint.color = Colors.lightBlueAccent;
        canvas.drawRect(
          Rect.fromLTWH(
            size / 2 - pixelSize,
            size / 2 - pixelSize,
            pixelSize * 2,
            pixelSize * 2
          ),
          paint
        );
        
        // 武器标志 - 子弹形状
        paint.color = Colors.white;
        
        // 垂直线
        canvas.drawRect(
          Rect.fromLTWH(
            size / 2 - pixelSize / 2,
            size / 2 - pixelSize * 2,
            pixelSize,
            pixelSize * 4
          ),
          paint
        );
        
        // 水平线
        canvas.drawRect(
          Rect.fromLTWH(
            size / 2 - pixelSize * 2,
            size / 2 - pixelSize / 2,
            pixelSize * 4,
            pixelSize
          ),
          paint
        );
        break;
        
      case PowerUpType.shield:
        // 护盾 - 紫色，盾牌形状
        
        // 外框 - 深紫色
        paint.color = Colors.purple.shade900;
        canvas.drawRect(
          Rect.fromLTWH(
            size / 2 - pixelSize * 3,
            size / 2 - pixelSize * 3,
            pixelSize * 6,
            pixelSize * 6
          ),
          paint
        );
        
        // 内部 - 紫色
        paint.color = Colors.purple;
        canvas.drawRect(
          Rect.fromLTWH(
            size / 2 - pixelSize * 2,
            size / 2 - pixelSize * 2,
            pixelSize * 4,
            pixelSize * 4
          ),
          paint
        );
        
        // 中心 - 亮紫色
        paint.color = Colors.purpleAccent;
        canvas.drawRect(
          Rect.fromLTWH(
            size / 2 - pixelSize,
            size / 2 - pixelSize,
            pixelSize * 2,
            pixelSize * 2
          ),
          paint
        );
        
        // 盾牌标志
        paint.color = Colors.white;
        // 盾牌上半部分
        canvas.drawRect(
          Rect.fromLTWH(
            size / 2 - pixelSize * 1.5,
            size / 2 - pixelSize * 1.5,
            pixelSize * 3,
            pixelSize
          ),
          paint
        );
        
        // 盾牌中间
        canvas.drawRect(
          Rect.fromLTWH(
            size / 2 - pixelSize / 2,
            size / 2 - pixelSize / 2,
            pixelSize,
            pixelSize * 2
          ),
          paint
        );
        break;
        
      case PowerUpType.health:
        // 生命 - 绿色，十字形状
        
        // 外框 - 深绿色
        paint.color = Colors.green.shade900;
        canvas.drawRect(
          Rect.fromLTWH(
            size / 2 - pixelSize * 3,
            size / 2 - pixelSize * 3,
            pixelSize * 6,
            pixelSize * 6
          ),
          paint
        );
        
        // 内部 - 绿色
        paint.color = Colors.green;
        canvas.drawRect(
          Rect.fromLTWH(
            size / 2 - pixelSize * 2,
            size / 2 - pixelSize * 2,
            pixelSize * 4,
            pixelSize * 4
          ),
          paint
        );
        
        // 中心 - 亮绿色
        paint.color = Colors.lightGreenAccent;
        canvas.drawRect(
          Rect.fromLTWH(
            size / 2 - pixelSize,
            size / 2 - pixelSize,
            pixelSize * 2,
            pixelSize * 2
          ),
          paint
        );
        
        // 十字标志 - 生命
        paint.color = Colors.white;
        
        // 垂直线
        canvas.drawRect(
          Rect.fromLTWH(
            size / 2 - pixelSize / 2,
            size / 2 - pixelSize * 1.5,
            pixelSize,
            pixelSize * 3
          ),
          paint
        );
        
        // 水平线
        canvas.drawRect(
          Rect.fromLTWH(
            size / 2 - pixelSize * 1.5,
            size / 2 - pixelSize / 2,
            pixelSize * 3,
            pixelSize
          ),
          paint
        );
        break;
    }
    
    // 恢复画布状态
    canvas.restore();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 使用更小的dt值以减少动画变化的突变
    final smoothDt = dt * 0.8;
    
    // 更新动画时间
    _animationTime += smoothDt;
    
    // 更新旋转 - 减少旋转速度
    _rotation += smoothDt * 0.4;
    
    // 更新脉冲缩放 - 使用更小的幅度变化
    _pulseScale = 1.0 + 0.15 * sin(_animationTime * 3);
    
    // 向下移动
    position.y += speed * dt;
    
    // 如果超出屏幕底部，移除
    if (position.y > gameRef.size.y + size.y) {
      removeFromParent();
    }
  }
  
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    // 与玩家碰撞
    if (other is PlayerComponent) {
      // 根据道具类型给玩家加强
      switch (type) {
        case PowerUpType.weapon:
          // 升级武器
          other.powerUp();
          break;
          
        case PowerUpType.shield:
          // 添加护盾
          other.addShield();
          break;
          
        case PowerUpType.health:
          // 恢复生命
          other.heal();
          break;
      }
      
      // 播放道具音效
      gameRef.audioService.playPowerupSound();
      
      // 移除道具
      removeFromParent();
    }
  }
} 