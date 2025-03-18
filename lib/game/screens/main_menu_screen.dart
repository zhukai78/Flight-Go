import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../flight_go_game.dart';

/// 主菜单屏幕
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 游戏标题
            const Text(
              'FLIGHT GO',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.blue,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            
            // 开始游戏按钮
            _buildButton(
              context,
              'Start Game',
              () => _startGame(context, Difficulty.normal),
            ),
            const SizedBox(height: 20),
            
            // 难度选择按钮
            _buildButton(
              context,
              'Easy Mode',
              () => _startGame(context, Difficulty.easy),
            ),
            const SizedBox(height: 10),
            _buildButton(
              context,
              'Normal Mode',
              () => _startGame(context, Difficulty.normal),
            ),
            const SizedBox(height: 10),
            _buildButton(
              context,
              'Hard Mode',
              () => _startGame(context, Difficulty.hard),
            ),
            const SizedBox(height: 20),
            
            // 退出按钮
            _buildButton(
              context,
              'Exit',
              () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  // 构建按钮
  Widget _buildButton(BuildContext context, String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        textStyle: const TextStyle(fontSize: 18),
      ),
      child: Text(text),
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