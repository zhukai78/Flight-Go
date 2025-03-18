import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'game/screens/main_menu_screen.dart';

// 全局异常处理
void _handleError(Object error, StackTrace stackTrace) {
  debugPrint('捕获到未处理的异常: $error');
  debugPrint('堆栈: $stackTrace');
}

void main() async {
  // 设置全局错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter错误: ${details.exception}');
    debugPrint('堆栈: ${details.stack}');
  };
  
  // 处理异步错误
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    _handleError(error, stack);
    return true;
  };
  
  // 包装整个应用程序
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // 初始化Flame
    await Flame.device.fullScreen();
    await Flame.device.setPortrait();
    
    // 预热引擎
    await _preloadResources();
    
    runApp(const MyApp());
  }, (error, stackTrace) {
    _handleError(error, stackTrace);
  });
}

// 预加载资源
Future<void> _preloadResources() async {
  debugPrint('预加载游戏资源...');
  
  // 可以在这里添加资源预加载代码
  // 例如：预加载图像、音效等
  
  // 模拟等待，以确保系统初始化完成
  await Future.delayed(const Duration(milliseconds: 100));
  
  debugPrint('资源预加载完成');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flight Go',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
      debugShowCheckedModeBanner: false,
      // 添加错误处理构建器
      builder: (context, widget) {
        // 添加错误边界
        ErrorWidget.builder = (FlutterErrorDetails details) {
          debugPrint('渲染错误: ${details.exception}');
          // 返回自定义错误小部件而不是崩溃
          return Container(
            color: Colors.black,
            child: const Center(
              child: Text(
                '游戏渲染出现问题，请重启应用',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        };
        return widget ?? const SizedBox.shrink();
      },
    );
  }
}
