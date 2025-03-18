import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flight_go_game.dart';

/// 游戏HUD组件，显示游戏状态、分数和生命值
class GameHud extends PositionComponent with HasGameRef<FlightGoGame> {
  // 文本组件
  late final TextComponent _scoreText;
  late final TextComponent _healthText;
  late final TextComponent _gameStateText;

  // 暂停/继续按钮
  late final RectangleComponent _pauseButton;
  
  // 按钮大小
  static const double buttonSize = 50.0;
  static const double buttonPadding = 10.0;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 设置HUD位置和大小
    position = Vector2.zero();
    size = Vector2(gameRef.size.x, gameRef.size.y);
    
    // 创建分数文本
    _scoreText = TextComponent(
      text: 'Score: 0',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20, 
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 1))]
        ),
      ),
      position: Vector2(10, 10),
    );
    
    // 创建生命值文本
    _healthText = TextComponent(
      text: 'Health: 3',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20, 
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 1))]
        ),
      ),
      position: Vector2(10, 40),
    );
    
    // 创建游戏状态文本（仅在暂停或游戏结束时显示）
    _gameStateText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 40, color: Colors.white, shadows: [
          Shadow(color: Colors.black, blurRadius: 5, offset: Offset(2, 2))
        ]),
      ),
      position: Vector2(gameRef.size.x / 2, gameRef.size.y / 2),
      anchor: Anchor.center,
    );
    
    // 创建暂停按钮
    _pauseButton = RectangleComponent(
      position: Vector2(gameRef.size.x - buttonSize - buttonPadding, buttonPadding),
      size: Vector2(buttonSize, buttonSize),
      paint: Paint()..color = Colors.transparent,
    );
    
    // 添加文本组件
    add(_scoreText);
    add(_healthText);
    add(_gameStateText);
    add(_pauseButton);
  }
  
  @override
  void render(Canvas canvas) {
    // 绘制暂停/继续按钮图标
    final buttonX = gameRef.size.x - buttonSize - buttonPadding;
    final buttonY = buttonPadding;
    
    // 绘制按钮背景 - 半透明圆形
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(buttonX + buttonSize/2, buttonY + buttonSize/2), 
      buttonSize/2, 
      bgPaint
    );
    
    // 设置按钮图标画笔
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 3;
    
    // 根据游戏状态绘制不同的图标
    if (gameRef.gameState == GameState.playing) {
      // 绘制暂停图标（两条竖线）
      canvas.drawRect(
        Rect.fromLTWH(buttonX + buttonSize * 0.3, buttonY + buttonSize * 0.25, buttonSize * 0.15, buttonSize * 0.5),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(buttonX + buttonSize * 0.55, buttonY + buttonSize * 0.25, buttonSize * 0.15, buttonSize * 0.5),
        paint,
      );
    } else if (gameRef.gameState == GameState.paused) {
      // 绘制继续图标（三角形）
      final path = Path();
      path.moveTo(buttonX + buttonSize * 0.35, buttonY + buttonSize * 0.25);
      path.lineTo(buttonX + buttonSize * 0.35, buttonY + buttonSize * 0.75);
      path.lineTo(buttonX + buttonSize * 0.75, buttonY + buttonSize * 0.5);
      path.close();
      canvas.drawPath(path, paint);
    }
    
    // 如果是暂停状态，在屏幕中央绘制提示文本
    if (gameRef.gameState == GameState.paused) {
      final textPaint = TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          shadows: [Shadow(color: Colors.black, blurRadius: 3)]
        )
      );
      
      textPaint.render(
        canvas,
        'TAP TO RESUME',
        Vector2(gameRef.size.x / 2, gameRef.size.y / 2 + 80),
        anchor: Anchor.center,
      );
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    try {
      // 更新分数文本
      _scoreText.text = 'Score: ${gameRef.score}';
      
      // 更新生命值文本
      if (gameRef.player.isMounted) {
        _healthText.text = 'Health: ${gameRef.player.health}';
      }
      
      // 更新游戏状态文本
      switch (gameRef.gameState) {
        case GameState.menu:
          _gameStateText.text = 'PRESS START';
          break;
        case GameState.playing:
          _gameStateText.text = '';
          break;
        case GameState.paused:
          _gameStateText.text = 'PAUSED';
          break;
        case GameState.gameOver:
          _gameStateText.text = 'GAME OVER\nScore: ${gameRef.score}\nTap to Restart';
          break;
      }
    } catch (e) {
      debugPrint('GameHud update error: $e');
    }
  }
}