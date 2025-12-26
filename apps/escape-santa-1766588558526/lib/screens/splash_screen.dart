import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';
import '../services/app_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  late AppConfig _config;
  bool _configLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    _config = await AppConfig.getInstance();
    setState(() {
      _configLoaded = true;
    });
    _startLoading();
  }

  void _startLoading() {
    Timer.periodic(Duration(milliseconds: _config.loadingProgressSpeed), (timer) {
      setState(() {
        _progress += _config.loadingProgressIncrement;
        if (_progress >= 1.0) {
          timer.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_configLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              _config.splashBackgroundImage,
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon
              SizedBox(
                height: 80,
                child: ClipRRect(
                  child: Image.asset(
                    _config.splashLoadingTextImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.gamepad,
                        size: 80,
                        color: Colors.deepPurple,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Loading Icon with Progress Bar
              Stack(
                alignment: Alignment.center,
                children: [
                  // Loading Icon
                  SizedBox(
                    width: 350,
                    child: ClipRRect(
                      child: Image.asset(
                        _config.splashLoadingEmptyImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.gamepad,
                            size: 80,
                            color: Colors.deepPurple,
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Loading Bar
                  Container(
                    width: _config.splashProgressBarWidth,
                    height: _config.splashProgressBarHeight,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0),
                      borderRadius: BorderRadius.circular(_config.splashProgressBarBorderRadius),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_config.splashProgressBarBorderRadius),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(_config.primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
