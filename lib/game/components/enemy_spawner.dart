import 'dart:math';
import 'package:flame/components.dart';
import '../flight_go_game.dart';
import 'enemy_component.dart';

/// 敌人生成器组件
class EnemySpawner extends Component with HasGameRef<FlightGoGame> {
  // 生成间隔
  double _spawnInterval = 2.0;
  double _spawnCooldown = 0;
  
  // 波次计数
  int _waveCount = 0;
  int _enemiesInWave = 0;
  int _maxEnemiesPerWave = 5;
  
  // 随机数生成器
  final Random _random = Random();
  
  // 当前关卡
  int _currentLevel = 1;
  
  @override
  void update(double dt) {
    if (gameRef.gameState != GameState.playing) return;
    
    // 更新生成冷却
    _spawnCooldown -= dt;
    
    // 检查是否需要生成新敌人
    if (_spawnCooldown <= 0) {
      _spawnEnemy();
      
      // 根据游戏难度设置下一次生成间隔
      _adjustSpawnInterval();
      
      // 重置生成冷却
      _spawnCooldown = _spawnInterval;
    }
  }
  
  // 生成敌人
  void _spawnEnemy() {
    // 增加当前波次敌人计数
    _enemiesInWave++;
    
    // 检查是否需要生成Boss
    if (_waveCount > 0 && _waveCount % 5 == 0 && _enemiesInWave == _maxEnemiesPerWave) {
      _spawnBoss();
      _startNextWave();
      return;
    }
    
    // 检查是否完成当前波次
    if (_enemiesInWave >= _maxEnemiesPerWave) {
      _startNextWave();
    }
    
    // 根据难度和关卡确定敌人类型
    EnemyType enemyType;
    if (_random.nextDouble() < 0.2 + (_currentLevel * 0.05)) {
      enemyType = EnemyType.elite;
    } else {
      enemyType = EnemyType.normal;
    }
    
    // 随机位置（屏幕顶部）
    final x = _random.nextDouble() * gameRef.size.x;
    final position = Vector2(x, -50);
    
    // 随机移动模式
    MovementPattern movementPattern = _getRandomMovementPattern();
    
    // 创建敌人
    final enemy = EnemyComponent(
      type: enemyType,
      position: position,
      movementPattern: movementPattern,
    );
    
    // 添加到游戏
    gameRef.add(enemy);
  }
  
  // 生成Boss敌人
  void _spawnBoss() {
    // Boss出现在屏幕中央顶部
    final position = Vector2(gameRef.size.x / 2, -100);
    
    // 创建Boss敌人
    final boss = EnemyComponent(
      type: EnemyType.boss,
      position: position,
      movementPattern: MovementPattern.circular,
    );
    
    // 添加到游戏
    gameRef.add(boss);
  }
  
  // 开始下一波敌人
  void _startNextWave() {
    _waveCount++;
    _enemiesInWave = 0;
    
    // 每5波增加难度
    if (_waveCount % 5 == 0) {
      _increaseLevel();
    }
    
    // 每波增加敌人数量
    _maxEnemiesPerWave = 5 + _waveCount;
    if (_maxEnemiesPerWave > 15) {
      _maxEnemiesPerWave = 15;
    }
  }
  
  // 增加关卡难度
  void _increaseLevel() {
    _currentLevel++;
  }
  
  // 根据难度调整生成间隔
  void _adjustSpawnInterval() {
    switch (gameRef.difficulty) {
      case Difficulty.easy:
        _spawnInterval = 2.5 - (_currentLevel * 0.1);
        break;
      case Difficulty.normal:
        _spawnInterval = 2.0 - (_currentLevel * 0.1);
        break;
      case Difficulty.hard:
        _spawnInterval = 1.5 - (_currentLevel * 0.1);
        break;
    }
    
    // 确保间隔不会太小
    if (_spawnInterval < 0.5) {
      _spawnInterval = 0.5;
    }
  }
  
  // 获取随机移动模式
  MovementPattern _getRandomMovementPattern() {
    final value = _random.nextDouble();
    
    if (value < 0.5) {
      return MovementPattern.straight;
    } else if (value < 0.7) {
      return MovementPattern.zigzag;
    } else if (value < 0.9) {
      return MovementPattern.circular;
    } else {
      return MovementPattern.homing;
    }
  }
}