import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../flight_go_game.dart';
import '../components/pixel_text.dart';
import '../components/pixel_icon.dart';
import '../components/pixel_background.dart';

/// 主菜单屏幕
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 背景渐变层
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  Colors.blue.shade900,
                  Colors.black,
                ],
              ),
            ),
          ),
          
          // 像素网格背景
          const PixelBackground(
            gridColor: Colors.blue,
            gridSize: 24.0,
            gridOpacity: 0.1,
          ),
          
          // 内容层
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 游戏标题 - 使用像素文本组件
                const PixelText(
                  text: 'FLIGHT GO',
                  fontSize: 48,
                  shadowColor: Colors.blue,
                  isTitle: true,
                ),
                const SizedBox(height: 30),
                
                // 使用自定义像素火箭图标
                const PixelIcon(
                  iconType: IconType.rocket,
                  size: 80,
                  primaryColor: Colors.white,
                  secondaryColor: Colors.red,
                ),
                
                const SizedBox(height: 20),
                
                // 游戏说明 - 像素风格
                const PixelText(
                  text: '太空射击游戏',
                  fontSize: 18,
                  shadowColor: Colors.purpleAccent,
                ),
                const SizedBox(height: 30),
                
                // 开始游戏按钮 - 使用像素按钮组件
                PixelButton(
                  text: 'Start Game',
                  icon: Icons.play_arrow,
                  onPressed: () => _startGame(context, Difficulty.normal),
                ),
                const SizedBox(height: 10),
                
                // 难度选择按钮 - 每个按钮旁边添加对应的像素图标
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const PixelIcon(
                      iconType: IconType.heart,
                      size: 40,
                      primaryColor: Colors.white,
                      secondaryColor: Colors.green,
                    ),
                    const SizedBox(width: 10),
                    PixelButton(
                      text: 'Easy Mode',
                      icon: Icons.sentiment_satisfied_alt,
                      onPressed: () => _startGame(context, Difficulty.easy),
                      color: Colors.green,
                      width: 180.0,
                    ),
                  ],
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const PixelIcon(
                      iconType: IconType.star,
                      size: 40,
                      primaryColor: Colors.white,
                      secondaryColor: Colors.blue,
                    ),
                    const SizedBox(width: 10),
                    PixelButton(
                      text: 'Normal Mode',
                      icon: Icons.star,
                      onPressed: () => _startGame(context, Difficulty.normal),
                      color: Colors.blue,
                      width: 180.0,
                    ),
                  ],
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const PixelIcon(
                      iconType: IconType.shield,
                      size: 40, 
                      primaryColor: Colors.white,
                      secondaryColor: Colors.red,
                    ),
                    const SizedBox(width: 10),
                    PixelButton(
                      text: 'Hard Mode',
                      icon: Icons.whatshot,
                      onPressed: () => _startGame(context, Difficulty.hard),
                      color: Colors.red,
                      width: 180.0,
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // 退出按钮
                PixelButton(
                  text: 'Exit',
                  icon: Icons.exit_to_app,
                  onPressed: () => Navigator.of(context).pop(),
                  color: Colors.grey,
                  width: 180.0,
                ),
                
                // 添加像素风格的版权信息
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const PixelIcon(
                      iconType: IconType.coin,
                      size: 30,
                      primaryColor: Colors.white,
                      secondaryColor: Colors.amber,
                    ),
                    const SizedBox(width: 10),
                    PixelText(
                      text: '© 2023 PIXEL GAMES',
                      fontSize: 12,
                      shadowColor: Colors.blue.withOpacity(0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 开始游戏
  void _startGame(BuildContext context, Difficulty difficulty) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameWidget(
          game: FlightGoGame()..difficulty = difficulty,
        ),
      ),
    );
  }
}