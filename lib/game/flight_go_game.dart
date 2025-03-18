import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/input.dart';
import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'components/background_component.dart';
import 'components/player_component.dart';
import 'components/enemy_spawner.dart';
import 'components/game_hud.dart';
import 'components/enemy_component.dart';
import 'components/bullet_component.dart';
import 'components/bullet_pool.dart';
import 'components/explosion_component.dart';
import 'components/bullet_trail_component.dart';
import 'components/power_up_component.dart';
import 'services/audio_service.dart';

/// 游戏状态枚举
enum GameState {
  menu,    // 菜单
  playing, // 游戏中
  paused,  // 暂停
  gameOver // 结束
}

/// 游戏主类，继承自FlameGame，实现碰撞检测和输入处理
class FlightGoGame extends FlameGame with HasCollisionDetection, TapCallbacks, DragCallbacks {
  // 游戏状态
  GameState _gameState = GameState.menu;
  GameState get gameState => _gameState;
  set gameState(GameState value) {
    _gameState = value;
  }
  
  @override
  Color backgroundColor() => const Color.fromARGB(255, 0, 0, 25);
  
  // 玩家组件
  late final PlayerComponent player;
  
  // 游戏分数
  int score = 0;
  
  // 游戏难度
  Difficulty _difficulty = Difficulty.normal;
  Difficulty get difficulty => _difficulty;
  set difficulty(Difficulty value) {
    _difficulty = value;
  }
  
  // 获取当前难度系数
  double get difficultyMultiplier {
    switch (_difficulty) {
      case Difficulty.easy:
        return 0.8;
      case Difficulty.normal:
        return 1.0;
      case Difficulty.hard:
        return 1.5;
    }
  }
  
  // 敌人生成器
  late final EnemySpawner enemySpawner;
  
  // 子弹对象池
  late final BulletPool bulletPool;
  
  // 音频服务
  late final AudioService audioService;
  
  // 随机数生成器
  final Random _random = Random();
  
  // 游戏时间
  double gameTime = 0.0;
  
  // 敌人生成累积时间
  double _enemySpawnAccumulator = 0.0;
  
  // 能量道具生成累积时间
  double _powerUpSpawnAccumulator = 0.0;
  
  // 下一个Boss生成时间
  double _nextBossTime = 60.0;
  
  // 是否激活Boss
  bool _bossActive = false;
  
  // 背景速度
  double backgroundSpeed = 100.0;
  
  // 背景组件
  BackgroundComponent? _backgroundComponent;
  
  // 渲染性能监控
  final double _lastFrameTime = 0;
  int _consecutiveSlowFrames = 0;
  bool _hasRenderedFirstFrame = false;
  int _frameCount = 0;
  int _errorCount = 0;
  bool _hasLogged = false;
  DateTime _lastFrameDateTime = DateTime.now();
  DateTime _lastErrorTime = DateTime.now();
  bool _isRecovering = false;
  bool _hasForcedGC = false;
  
  // 最后一次渲染错误
  String? _lastRenderError;
  
  // 跟踪拖动状态
  bool _isDragging = false;
  Vector2 _dragStartPosition = Vector2.zero();
  Vector2 _lastDragPosition = Vector2.zero();
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    debugPrint('游戏初始化开始');
    
    // 初始化音频服务
    audioService = AudioService();
    await add(audioService);
    
    // 初始化子弹池
    bulletPool = BulletPool();
    await add(bulletPool);
    
    // 添加视差背景
    _backgroundComponent = BackgroundComponent();
    await add(_backgroundComponent!);
    
    // 添加玩家
    player = PlayerComponent();
    await add(player);
    
    // 添加敌人生成器
    enemySpawner = EnemySpawner();
    await add(enemySpawner);
    
    // 添加HUD
    await add(GameHud());
    
    // 设置初始游戏状态
    gameState = GameState.menu;
    
    debugPrint('游戏初始化完成');
  }
  
  @override
  void update(double dt) {
    try {
      // 记录帧间时间
      final now = DateTime.now();
      final timeSinceLastFrame = now.difference(_lastFrameDateTime).inMilliseconds;
      _lastFrameDateTime = now;
      
      // 检测帧率过低的情况
      if (timeSinceLastFrame > 50 && _hasRenderedFirstFrame) { // 低于20fps
        _consecutiveSlowFrames++;
        
        if (_consecutiveSlowFrames > 5 && !_hasLogged) {
          debugPrint('游戏帧率过低: ${1000 / timeSinceLastFrame}fps, dt=$dt, 累计慢帧=$_consecutiveSlowFrames');
          _hasLogged = true;
          
          // 如果连续多帧低帧率，尝试优化措施
          if (_consecutiveSlowFrames > 10) {
            _tryRecoverFromLowFramerate();
          }
        }
      } else {
        _consecutiveSlowFrames = 0;
        _hasLogged = false;
      }
      
      // 使用小一点的dt值来减少过大的位置变化
      final smoothDt = min(dt, 0.016);  // 限制最大dt值为16ms (约60fps)
      
      if (gameState == GameState.playing) {
        // 更新时间
        gameTime += smoothDt;
        
        // 根据时间增加游戏难度
        updateDifficulty();
        
        // 随机生成敌人
        trySpawnEnemies(smoothDt);
        
        // 随机生成能量道具
        trySpawnPowerUps(smoothDt);
        
        // 更新背景速度
        updateBackgroundSpeed(smoothDt);
      }
      
      _frameCount++;
      if (_frameCount % 600 == 0) { // 每600帧记录一次（约10秒）
        debugPrint('游戏运行中: 帧数=$_frameCount, 时间=${gameTime.toStringAsFixed(1)}s, 错误数=$_errorCount');
      }
      
      super.update(smoothDt);
      
      // 标记已渲染第一帧
      _hasRenderedFirstFrame = true;
    } catch (e, stackTrace) {
      debugPrint('游戏更新错误: $e');
      debugPrint('堆栈跟踪: $stackTrace');
    }
  }
  
  // 尝试从低帧率中恢复
  void _tryRecoverFromLowFramerate() {
    if (!_isRecovering) {
      _isRecovering = true;
      
      // 打印当前状态
      debugPrint('尝试恢复游戏性能...');
      debugPrint('组件数量: ${children.length}');
      
      // 可以在这里添加一些性能恢复措施
      // 1. 暂时减少特效
      // 2. 降低粒子效果
      // 3. 清理远离视图的对象
      
      // 清理远离视图的子弹和敌人
      children.query<BulletComponent>().forEach((bullet) {
        if (bullet.position.y < -100 || bullet.position.y > size.y + 100 ||
            bullet.position.x < -100 || bullet.position.x > size.x + 100) {
          bullet.removeFromParent();
        }
      });
      
      // 强制GC
      if (!_hasForcedGC) {
        debugPrint('触发内存回收...');
        // Flutter没有直接的GC调用，但可以通过下面的方式触发
        SystemChannels.platform.invokeMethod('System.gc');
        _hasForcedGC = true;
      }
      
      Future.delayed(const Duration(seconds: 3), () {
        _isRecovering = false;
        _hasForcedGC = false;
        debugPrint('性能恢复措施完成');
      });
    }
  }
  
  @override
  void render(Canvas canvas) {
    try {
      // 保存画布状态
      canvas.save();
      
      // 执行正常渲染
      super.render(canvas);
      
      // 恢复画布状态
      canvas.restore();
      
      // 重置异常计数
      _lastRenderError = null;
    } catch (e, stackTrace) {
      _errorCount++;
      
      // 限制错误日志频率，避免日志爆炸
      final now = DateTime.now();
      if (now.difference(_lastErrorTime).inSeconds >= 5) { // 每5秒最多记录一次错误
        _lastErrorTime = now;
        _lastRenderError = e.toString();
        debugPrint('游戏渲染错误: $e');
        
        // 仅在错误不频繁时打印堆栈
        if (_errorCount < 10 || _errorCount % 50 == 0) {
          debugPrint('堆栈跟踪: $stackTrace');
        }
        
        // 尝试通过Canvas重置来恢复渲染
        try {
          canvas.save();
          canvas.restore();
        } catch (_) {
          // 忽略恢复Canvas时的错误
        }
      }
      
      // 如果渲染错误过多，尝试进行更激进的恢复
      if (_errorCount > 50 && _errorCount % 100 == 0) {
        _tryRecoverFromRenderErrors();
      }
    }
  }
  
  // 从渲染错误中恢复的方法
  void _tryRecoverFromRenderErrors() {
    debugPrint('尝试从渲染错误中恢复...');
    
    // 在这里可以实现更多的恢复逻辑，例如:
    // 1. 减少渲染的组件数量
    // 2. 暂停复杂的渲染效果
    // 3. 重置某些资源
    
    // 记录重要的游戏状态
    debugPrint('当前游戏状态: $_gameState, 得分: $score, 游戏时间: ${gameTime.toStringAsFixed(1)}s');
    debugPrint('画面尺寸: ${size.x}x${size.y}, 组件数量: ${children.length}');
    debugPrint('上次渲染错误: $_lastRenderError');
    
    // 重置一些可能导致问题的状态
    _isRecovering = true;
    
    // 延迟执行，避免在同一帧中进行太多操作
    Future.delayed(const Duration(seconds: 2), () {
      _isRecovering = false;
      debugPrint('渲染恢复措施完成');
    });
  }
  
  // 处理拖动开始事件
  @override
  void onDragStart(DragStartEvent event) {
    if (_gameState == GameState.playing) {
      _isDragging = true;
      _dragStartPosition = event.canvasPosition.clone();
      _lastDragPosition = event.canvasPosition.clone();
    }
  }
  
  // 处理拖动更新事件，用于移动玩家飞机
  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_gameState == GameState.playing && _isDragging) {
      // 增加对拖拽偏移的跟踪，处理拖动中断的情况
      final currentPosition = event.canvasPosition;
      
      // 使用相对位移的方式移动
      player.move(event.localDelta);
      
      // 同时也考虑绝对位置，以便在拖动暂停后重新开始时能够准确定位
      if ((currentPosition - _lastDragPosition).length > 20) {
        // 当位置变化较大时，使用绝对定位，避免飞机与手指脱节
        player.absoluteMove(currentPosition);
      }
      
      // 更新上一次拖动位置
      _lastDragPosition = currentPosition.clone();
    }
  }
  
  // 处理拖动结束事件
  @override
  void onDragEnd(DragEndEvent event) {
    if (_gameState == GameState.playing) {
      _isDragging = false;
    }
  }
  
  // 处理点击事件，用于暂停游戏或使用特殊能力
  @override
  void onTapUp(TapUpEvent event) {
    // 获取点击位置
    final position = event.canvasPosition;
    final pauseButtonSize = 60.0;
    final isPauseButtonArea = position.x > size.x - pauseButtonSize - 10 && 
                             position.y < pauseButtonSize + 10;
    
    // 检查游戏状态
    switch (_gameState) {
      case GameState.menu:
        // 点击任意位置开始游戏
        startGame();
        break;
        
      case GameState.playing:
        // 检查是否点击了暂停按钮
        if (isPauseButtonArea) {
          pauseGame();
        }
        break;
        
      case GameState.paused:
        // 暂停时，点击任意位置恢复游戏，除非点击在角落区域
        if (position.x < 50 && position.y < 50) {
          // 左上角区域可以用来放置其他控制按钮，避免恢复游戏
          return;
        }
        
        // 点击暂停按钮或屏幕其他区域都可以恢复游戏
        resumeGame();
        break;
        
      case GameState.gameOver:
        // 点击任意位置重新开始
        restartGame();
        break;
    }
  }
  
  // 检查点击位置是否在屏幕中央区域
  bool _isScreenCenterArea(Vector2 position) {
    // 定义屏幕中央区域
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final areaSize = size.x * 0.5; // 中心区域宽度为屏幕宽度的50%
    
    return (position.x > centerX - areaSize / 2 &&
            position.x < centerX + areaSize / 2 &&
            position.y > centerY - areaSize / 2 &&
            position.y < centerY + areaSize / 2);
  }
  
  // 开始新游戏
  void startGame() {
    // 重置游戏状态
    score = 0;
    gameTime = 0.0;
    _enemySpawnAccumulator = 0.0;
    _powerUpSpawnAccumulator = 0.0;
    _nextBossTime = 60.0;
    _bossActive = false;
    
    // 重置性能监控状态
    _frameCount = 0;
    _errorCount = 0;
    _hasRenderedFirstFrame = false;
    _consecutiveSlowFrames = 0;
    _isRecovering = false;
    _hasForcedGC = false;
    
    // 设置游戏状态为进行中
    _gameState = GameState.playing;
    
    // 播放背景音乐
    audioService.playBackgroundMusic();
    
    debugPrint('游戏开始');
  }
  
  // 重新开始游戏
  void restartGame() {
    debugPrint('重新开始游戏');
    
    // 重置分数
    score = 0;
    gameTime = 0.0;
    
    // 移除所有敌人和子弹
    children.query<EnemyComponent>().forEach((enemy) => enemy.removeFromParent());
    children.query<BulletComponent>().forEach((bullet) => bullet.removeFromParent());
    children.query<PowerUpComponent>().forEach((powerUp) => powerUp.removeFromParent());
    
    // 处理玩家组件 - 必须小心处理，因为它是late final
    if (!children.contains(player)) {
      // 如果player不在children列表中，我们需要重新添加它
      try {
        add(player); // 尝试添加现有实例
      } catch (e) {
        // 如果发生错误，需要更复杂的重置逻辑
        debugPrint('无法重新添加player: $e');
        // 这种情况下，可能需要关闭游戏然后重新启动
        // 或者使用特殊的重置机制
      }
    }
    
    // 重置玩家状态
    player.health = 3;
    player.weaponLevel = 1;
    player.position = Vector2(
      size.x / 2,
      size.y - player.size.y - 50,
    );
    
    // 重置性能监控状态
    _frameCount = 0;
    _errorCount = 0;
    _hasRenderedFirstFrame = false;
    _consecutiveSlowFrames = 0;
    _isRecovering = false;
    _hasForcedGC = false;
    
    // 将游戏状态设为正在进行
    _gameState = GameState.playing;
    
    // 播放背景音乐
    audioService.playBackgroundMusic();
  }
  
  // 暂停游戏
  void pauseGame() {
    _gameState = GameState.paused;
    audioService.pauseAllAudio();
    debugPrint('游戏暂停');
  }
  
  // 恢复游戏
  void resumeGame() {
    _gameState = GameState.playing;
    audioService.resumeAllAudio();
    debugPrint('游戏恢复');
  }
  
  // 游戏结束
  void gameOver() {
    _gameState = GameState.gameOver;
    audioService.stopBackgroundMusic();
    debugPrint('游戏结束，最终得分: $score');
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
  
  /// 创建能量道具
  void spawnPowerUp(Vector2 position, {PowerUpType? type}) {
    // 如果未指定类型，则随机生成一种道具类型
    type ??= PowerUpType.values[_random.nextInt(PowerUpType.values.length)];
    
    final powerUp = PowerUpComponent(
      position: position,
      type: type,
    );
    
    add(powerUp);
  }
  
  // 更新游戏难度
  void updateDifficulty() {
    // 根据游戏时间逐渐增加难度系数
    final baseMultiplier = difficultyMultiplier;
    final timeMultiplier = 1.0 + (gameTime / 60.0); // 每60秒增加1.0
    final totalMultiplier = baseMultiplier * timeMultiplier;
    
    // 限制最大难度
    difficulty = _difficulty; // 保持原有难度等级不变
  }
  
  // 生成敌人
  void trySpawnEnemies(double dt) {
    // 累积dt以形成更稳定的生成频率
    _enemySpawnAccumulator += dt;
    
    // 只有当累积时间达到阈值时才考虑生成
    if (_enemySpawnAccumulator >= 0.1) {  // 每0.1秒检查一次
      _enemySpawnAccumulator = 0;
      
      // 敌人生成概率 - 基于难度的平滑概率
      final baseSpawnChance = min(0.05 + (difficultyMultiplier * 0.01), 0.3);
      
      // 普通敌人
      if (_random.nextDouble() < baseSpawnChance) {
        spawnEnemy();
      }
      
      // 精英敌人 - 更低的生成频率
      if (_random.nextDouble() < baseSpawnChance * 0.3) {
        spawnEliteEnemy();
      }
      
      // Boss敌人 - 基于时间和积分的生成
      if (gameTime > _nextBossTime && !_bossActive) {
        spawnBossEnemy();
        _bossActive = true;
        _nextBossTime = gameTime + 60.0; // 60秒后再生成下一个Boss
      }
    }
  }
  
  // 生成普通敌人
  void spawnEnemy() {
    // 在屏幕顶部随机位置生成敌人
    final x = _random.nextDouble() * size.x;
    
    final enemy = EnemyComponent(
      type: EnemyType.normal,
      position: Vector2(x, -50),
      size: Vector2(48, 48),
      movementPattern: _random.nextBool() ? MovementPattern.straight : MovementPattern.zigzag,
    );
    
    add(enemy);
  }
  
  // 生成精英敌人
  void spawnEliteEnemy() {
    // 在屏幕顶部随机位置生成精英敌人
    final x = _random.nextDouble() * size.x;
    
    final enemy = EnemyComponent(
      type: EnemyType.elite,
      position: Vector2(x, -50),
      size: Vector2(64, 64),
      movementPattern: MovementPattern.circular,
    );
    
    add(enemy);
  }
  
  // 生成Boss敌人
  void spawnBossEnemy() {
    // 在屏幕顶部中央生成Boss敌人
    final x = size.x / 2;
    
    final enemy = EnemyComponent(
      type: EnemyType.boss,
      position: Vector2(x, -100),
      size: Vector2(128, 128),
      movementPattern: MovementPattern.homing,
    );
    
    add(enemy);
    
    // 播放Boss音效
    audioService.playExplosionSound();
  }
  
  // 生成能量道具
  void trySpawnPowerUps(double dt) {
    // 累积dt以形成更稳定的生成频率
    _powerUpSpawnAccumulator += dt;
    
    // 只有当累积时间达到阈值时才考虑生成
    if (_powerUpSpawnAccumulator >= 0.2) {  // 每0.2秒检查一次
      _powerUpSpawnAccumulator = 0;
      
      // 能量道具生成概率 - 极低概率随机生成
      final spawnChance = 0.01 * difficultyMultiplier;  // 基础概率随难度增加
      if (_random.nextDouble() < spawnChance) {
        spawnRandomPowerUp();
      }
    }
  }
  
  // 生成随机能量道具
  void spawnRandomPowerUp() {
    // 在屏幕顶部随机位置生成
    final x = _random.nextDouble() * size.x;
    spawnPowerUp(Vector2(x, -20));
  }
  
  // 更新背景速度
  void updateBackgroundSpeed(double dt) {
    // 根据难度设置目标背景速度
    final targetSpeed = 100.0 + (difficultyMultiplier * 50.0);
    
    // 确保背景组件存在
    if (_backgroundComponent != null) {
      // 平滑更新背景速度，避免突变
      _backgroundComponent!.speed = lerpDouble(_backgroundComponent!.speed, targetSpeed, 0.1) ?? targetSpeed;
    }
  }
}

// 游戏难度枚举
enum Difficulty { easy, normal, hard }