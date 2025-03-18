import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import '../flight_go_game.dart';

/// 游戏音频服务类，用于管理游戏中的音效和音乐
class AudioService extends Component with HasGameRef<FlightGoGame> {
  // 是否启用音效
  bool _soundEnabled = true;
  
  // 是否启用音乐
  bool _musicEnabled = true;
  
  // 音量大小（0.0到1.0）
  double _soundVolume = 0.7;
  double _musicVolume = 0.5;
  
  // 音频缓存
  final Map<String, String> _audioCache = {
    'laser': 'audio/laser.mp3',
    'explosion': 'audio/explosion.mp3',
    'powerup': 'audio/powerup.mp3',
    'music': 'audio/game_music.mp3',
  };
  
  // 获取音效状态
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get soundVolume => _soundVolume;
  double get musicVolume => _musicVolume;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    try {
      // 预加载音效文件
      await FlameAudio.audioCache.loadAll([
        _audioCache['laser']!,
        _audioCache['explosion']!,
        _audioCache['powerup']!,
        _audioCache['music']!,
      ]);
      
      // 初始化完成后自动播放背景音乐
      playBackgroundMusic();
    } catch (e) {
      debugPrint('Audio initialization error: $e');
      // 错误处理 - 在发布版本中禁用音频
      _soundEnabled = false;
      _musicEnabled = false;
    }
  }
  
  /// 播放激光音效
  void playLaserSound() {
    if (_soundEnabled) {
      try {
        FlameAudio.play(
          _audioCache['laser']!,
          volume: _soundVolume,
        );
      } catch (e) {
        debugPrint('Error playing laser sound: $e');
      }
    }
  }
  
  /// 播放爆炸音效
  void playExplosionSound() {
    if (_soundEnabled) {
      try {
        FlameAudio.play(
          _audioCache['explosion']!,
          volume: _soundVolume,
        );
      } catch (e) {
        debugPrint('Error playing explosion sound: $e');
      }
    }
  }
  
  /// 播放能量道具音效
  void playPowerupSound() {
    if (_soundEnabled) {
      try {
        FlameAudio.play(
          _audioCache['powerup']!,
          volume: _soundVolume,
        );
      } catch (e) {
        debugPrint('Error playing powerup sound: $e');
      }
    }
  }
  
  /// 播放背景音乐
  void playBackgroundMusic() {
    if (_musicEnabled) {
      try {
        FlameAudio.bgm.play(
          _audioCache['music']!,
          volume: _musicVolume,
        );
      } catch (e) {
        debugPrint('Error playing background music: $e');
      }
    }
  }
  
  /// 停止背景音乐
  void stopBackgroundMusic() {
    try {
      FlameAudio.bgm.stop();
    } catch (e) {
      debugPrint('Error stopping background music: $e');
    }
  }
  
  /// 暂停所有音频
  void pauseAllAudio() {
    try {
      // 暂停背景音乐
      FlameAudio.bgm.pause();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }
  
  /// 恢复所有音频
  void resumeAllAudio() {
    try {
      // 恢复背景音乐
      if (_musicEnabled) {
        FlameAudio.bgm.resume();
      }
    } catch (e) {
      debugPrint('Error resuming audio: $e');
    }
  }
  
  /// 启用/禁用音效
  void toggleSound() {
    _soundEnabled = !_soundEnabled;
  }
  
  /// 启用/禁用音乐
  void toggleMusic() {
    _musicEnabled = !_musicEnabled;
    
    if (_musicEnabled) {
      playBackgroundMusic();
    } else {
      stopBackgroundMusic();
    }
  }
  
  /// 设置音效音量
  void setSoundVolume(double volume) {
    _soundVolume = volume.clamp(0.0, 1.0);
  }
  
  /// 设置音乐音量
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    
    // 更新当前播放的背景音乐音量
    try {
      FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
    } catch (e) {
      debugPrint('Error setting music volume: $e');
    }
  }
  
  @override
  void onRemove() {
    // 在组件被移除时释放资源
    stopBackgroundMusic();
    
    super.onRemove();
  }
} 