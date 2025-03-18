import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/input.dart';
import 'components/background_component.dart';
import 'components/player_component.dart';
import 'components/enemy_spawner.dart';
import 'components/game_hud.dart';
import 'components/enemy_component.dart';
import 'components/bullet_component.dart';
import 'components/bullet_pool.dart';
import 'components/explosion_component.dart';
import 'components/bullet_trail_component.dart';
import 'services/audio_service.dart';

/// 游戏主类，继承自FlameGame，实现碰撞检测和输入处理
class FlightGoGame extends FlameGame with HasCollisionDetection, TapCallbacks, DragCallbacks {
  // 游戏状态
  GameState _gameState = GameState.playing;
  GameState get gameState => _gameState;
  
  // 玩家组件
  late final PlayerComponent player;
  
  // 游戏分数
  int score = 0;
  
  // 游戏难度
  Difficulty difficulty = Difficulty.normal;
  
  // 敌人生成器
  late final EnemySpawner enemySpawner;
  
  // 子弹对象池
  late final BulletPool bulletPool;
  
  // 音频服务
  late final AudioService audioService;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 初始化子弹池
    bulletPool = BulletPool();
    await add(bulletPool);
    
    // 添加视差背景
    await add(BackgroundComponent());
    
    // 添加玩家
    player = PlayerComponent();
    await add(player);
    
    // 添加敌人生成器
    enemySpawner = EnemySpawner();
    await add(enemySpawner);
    
    // 添加HUD
    await add(GameHud());
    
    // 添加音频服务
    audioService = AudioService();
    await add(audioService);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 根据游戏状态更新游戏
    switch (_gameState) {
      case GameState.playing:
        // 正常游戏逻辑
        break;
      case GameState.paused:
        // 暂停状态，不更新游戏逻辑
        break;
      case GameState.gameOver:
        // 游戏结束状态
        break;
    }
  }
  
  // 处理拖动事件，用于移动玩家飞机
  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_gameState == GameState.playing) {
      player.move(event.localDelta);
    }
  }
  
  // 处理点击事件，用于暂停游戏或使用特殊能力
  @override
  void onTapUp(TapUpEvent event) {
    // 获取点击位置
    final position = event.canvasPosition;
    
    // 检查是否点击了屏幕右上角的"暂停区域"
    if (position.x > size.x - 50 && position.y < 50) {
      // 切换游戏状态 (暂停/恢复)
      if (_gameState == GameState.playing) {
        pauseGame();
      } else if (_gameState == GameState.paused) {
        resumeGame();
      }
    } else if (_gameState == GameState.gameOver) {
      // 如果游戏结束，点击任意位置重新开始
      restartGame();
    } else if (_gameState == GameState.playing) {
      // 游戏中的其他点击操作（如使用特殊能力等）
    }
  }
  
  // 重新开始游戏
  void restartGame() {
    // 重置分数
    score = 0;
    
    // 移除所有敌人和子弹
    children.query<EnemyComponent>().forEach((enemy) => enemy.removeFromParent());
    children.query<BulletComponent>().forEach((bullet) => bullet.removeFromParent());
    
    // 重新添加玩家（如果已移除）
    if (!player.isMounted) {
      player = PlayerComponent();
      add(player);
    } else {
      // 如果玩家已存在，重置状态
      player.health = 3;
      player.weaponLevel = 1;
      player.position = Vector2(
        size.x / 2,
        size.y - player.size.y - 50,
      );
    }
    
    // 将游戏状态设为正在进行
    _gameState = GameState.playing;
  }
  
  // 暂停游戏
  void pauseGame() {
    _gameState = GameState.paused;
    audioService.pauseAllAudio();
  }
  
  // 恢复游戏
  void resumeGame() {
    _gameState = GameState.playing;
    audioService.resumeAllAudio();
  }
  
  // 游戏结束
  void gameOver() {
    _gameState = GameState.gameOver;
    audioService.stopBackgroundMusic();
    // 播放游戏结束音效
  }
  
  // 增加分数
  void addScore(int points) {
    score += points;
  }
  
  // 获取玩家子弹
  BulletComponent getPlayerBullet({
    required Vector2 position,
    Vector2? direction,
    double speed = 300,
    int damage = 1,
  }) {
    final bullet = bulletPool.getPlayerBullet(
      position: position,
      direction: direction,
      speed: speed,
      damage: damage,
    );
    add(bullet);
    
    // 播放激光音效
    audioService.playLaserSound();
    
    return bullet;
  }
  
  // 获取敌人子弹
  BulletComponent getEnemyBullet({
    required Vector2 position,
    Vector2? direction,
    double speed = 150,
    int damage = 1,
  }) {
    final bullet = bulletPool.getEnemyBullet(
      position: position,
      direction: direction,
      speed: speed,
      damage: damage,
    );
    add(bullet);
    return bullet;
  }
}

// 游戏状态枚举
enum GameState { playing, paused, gameOver }

// 游戏难度枚举
enum Difficulty { easy, normal, hard }