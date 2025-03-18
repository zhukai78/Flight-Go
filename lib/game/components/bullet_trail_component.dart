import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flight_go_game.dart';

/// 子弹轨迹组件
class BulletTrailComponent extends Component with HasGameRef<FlightGoGame> {
  // 基本属性
  Vector2 position;
  Vector2 velocity;
  Paint paint;
  
  // 颜色
  final Color color;
  
  // 持续时间(秒)
  final double duration;
  double _timeAlive = 0;
  double _alpha = 1.0;
  
  // 初始尺寸和当前尺寸
  final double initialSize;
  double _currentSize;
  
  // 淡出因子
  final double fadeOutFactor;
  
  // 旋转角度
  final double rotation;
  
  // 是否为玩家子弹轨迹
  final bool isPlayerBullet;
  
  // 错误状态标记
  bool _hasRenderError = false;
  
  // 安全设置透明度的辅助方法
  Color withSafeOpacity(Color baseColor, double opacity) {
    // 确保透明度在有效范围内 (0.0-1.0)
    final safeOpacity = opacity.clamp(0.0, 1.0);
    try {
      return baseColor.withOpacity(safeOpacity);
    } catch (e) {
      // 如果颜色处理出错，返回一个安全的默认颜色
      debugPrint('子弹轨迹颜色错误: $e, baseColor=$baseColor, opacity=$opacity');
      return Colors.white.withOpacity(safeOpacity);
    }
  }
  
  // 构造函数
  BulletTrailComponent({
    required this.position,
    required this.velocity,
    required this.color,
    required this.initialSize,
    this.duration = 0.35, // 减少持续时间
    this.fadeOutFactor = 1.4, // 增加淡出速度
    this.rotation = 0.0,
    this.isPlayerBullet = false,
  }) : 
    _currentSize = initialSize,
    paint = Paint()..color = color,
    super(
      priority: -1, // 更低的优先级，确保轨迹总是绘制在其他游戏元素之下
    );
    
  @override
  void update(double dt) {
    // 更新存活时间
    _timeAlive += dt;
    
    // 检查是否应该移除
    if (_timeAlive >= duration) {
      removeFromParent();
      return;
    }
    
    // 计算剩余寿命比例
    final lifePercentage = 1.0 - (_timeAlive / duration);
    
    // 更新透明度 - 使用平滑的淡出
    _alpha = lifePercentage * lifePercentage; // 使用二次方衰减效果更平滑
    
    // 更新大小 - 在生命周期内平滑缩小
    _currentSize = initialSize * lifePercentage;
    
    // 更新位置
    position += velocity * dt;
  }
  
  @override
  void render(Canvas canvas) {
    // 如果之前渲染出现过错误，使用简化渲染
    if (_hasRenderError) {
      _renderSimplified(canvas);
      return;
    }
    
    // 防止过度透明时绘制
    if (_alpha < 0.02) return;
    
    try {
      // 设置颜色和透明度
      paint.color = withSafeOpacity(color, _alpha);
      
      // 保存画布状态
      canvas.save();
      canvas.translate(position.x, position.y);
      if (rotation != 0) {
        canvas.rotate(rotation);
      }
      
      // 绘制子弹轨迹
      if (isPlayerBullet) {
        // 玩家子弹轨迹 - 光线效果
        _renderPlayerTrail(canvas);
      } else {
        // 敌人子弹轨迹 - 简单的像素点
        _renderEnemyTrail(canvas);
      }
      
      // 恢复画布状态
      canvas.restore();
    } catch (e) {
      // 捕获渲染错误
      _hasRenderError = true;
      debugPrint('子弹轨迹渲染错误: $e');
      
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
      // 安全设置颜色
      final safeOpacity = _alpha.clamp(0.0, 1.0);
      final safePaint = Paint()
        ..color = Colors.white.withOpacity(safeOpacity)
        ..style = PaintingStyle.fill;
      
      // 绘制一个简单的矩形
      canvas.drawRect(
        Rect.fromLTWH(
          position.x - initialSize / 4,
          position.y - initialSize / 4,
          initialSize / 2,
          initialSize / 2
        ),
        safePaint
      );
    } catch (_) {
      // 忽略所有错误
    }
  }
  
  // 绘制玩家子弹轨迹
  void _renderPlayerTrail(Canvas canvas) {
    // 轨迹大小
    final size = _currentSize;
    
    // 绘制主体轨迹 - 像素风格
    final pixelSize = (size / 5).floorToDouble();
    
    // 基本矩形轨迹
    paint.style = PaintingStyle.fill;
    
    // 绘制方块阵列而不是渐变，以实现像素风格
    int pixelCount = 5;
    double opacity = _alpha;
    
    for (int i = 0; i < pixelCount; i++) {
      // 减小透明度，确保在有效范围内
      final pixelOpacity = (opacity * (1 - i / pixelCount)).clamp(0.0, 1.0);
      paint.color = withSafeOpacity(color, pixelOpacity);
      
      // 绘制像素
      canvas.drawRect(
        Rect.fromLTWH(
          -pixelSize / 2, 
          i * pixelSize, 
          pixelSize, 
          pixelSize
        ),
        paint
      );
    }
    
    // 为玩家子弹添加发光效果，但强度降低
    if (isPlayerBullet && _alpha > 0.3) {
      // 轻微光晕效果 - 减少强度
      final glowOpacity = (_alpha * 0.3).clamp(0.0, 1.0);
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = withSafeOpacity(color, glowOpacity);
      
      canvas.drawRect(
        Rect.fromLTWH(
          -pixelSize, 
          0, 
          pixelSize * 2, 
          pixelSize * 2
        ),
        glowPaint
      );
    }
  }
  
  // 绘制敌人子弹轨迹
  void _renderEnemyTrail(Canvas canvas) {
    // 轨迹大小
    final size = _currentSize;
    
    // 绘制主体轨迹 - 像素风格
    final pixelSize = (size / 3).floorToDouble();
    
    // 基本矩形轨迹
    paint.style = PaintingStyle.fill;
    
    // 绘制单个像素点
    canvas.drawRect(
      Rect.fromLTWH(
        -pixelSize / 2, 
        -pixelSize / 2, 
        pixelSize, 
        pixelSize
      ),
      paint
    );
  }
} 