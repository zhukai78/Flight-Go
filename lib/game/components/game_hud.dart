import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flight_go_game.dart';

/// 游戏HUD组件，显示游戏状态、分数和生命值
class GameHud extends PositionComponent with HasGameRef<FlightGoGame> {
  // 文本组件
  late final TextComponent _scoreText;
  late final TextComponent _healthText;
  late final TextComponent _gameStateText;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 设置HUD位置和大小
    position = Vector2(10, 10);
    size = Vector2(gameRef.size.x - 20, 50);
    
    // 创建分数文本
    _scoreText = TextComponent(
      text: 'Score: 0',
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 20, color: Colors.white),
      ),
      position: Vector2(0, 0),
    );
    
    // 创建生命值文本
    _healthText = TextComponent(
      text: 'Health: 3',
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 20, color: Colors.white),
      ),
      position: Vector2(0, 25),
    );
    
    // 创建游戏状态文本（仅在暂停或游戏结束时显示）
    _gameStateText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 40, color: Colors.white),
      ),
      position: Vector2(gameRef.size.x / 2, gameRef.size.y / 2),
      anchor: Anchor.center,
    );
    
    // 添加文本组件
    add(_scoreText);
    add(_healthText);
    add(_gameStateText);
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
        case GameState.playing:
          _gameStateText.text = '';
          break;
        case GameState.paused:
          _gameStateText.text = 'PAUSED';
          break;
        case GameState.gameOver:
          _gameStateText.text = 'GAME OVER\nScore: ${gameRef.score}';
          break;
      }
    } catch (e) {
      debugPrint('GameHud update error: $e');
    }
  }
}