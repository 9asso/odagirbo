import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/app_config.dart';
import '../services/admob_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  WebViewController? _controller;
  late AppConfig _config;
  bool _configLoaded = false;
  bool _isLoading = true;
  bool _showMenu = false;
  bool _showSplash = false; // Show splash screen after loading
  late AnimationController _menuAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _splashAnimationController;
  late AnimationController _bounceAnimationController;
  Offset _fabPosition = const Offset(20, 20); // Position from bottom-right
  final List<String> _pageHistory = []; // Track all visited pages
  Timer? _interstitialTimer;
  int _countdown = 0;
  bool _showCountdown = false;

  @override
  void initState() {
    super.initState();
    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _splashAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _loadConfig();
  }

  @override
  void dispose() {
    _menuAnimationController.dispose();
    _fabAnimationController.dispose();
    _splashAnimationController.dispose();
    _bounceAnimationController.dispose();
    _interstitialTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    _config = await AppConfig.getInstance();
    setState(() {
      _configLoaded = true;
    });
    _initializeWebView();
  }

  void _startInterstitialTimer() {
    if (!_config.gameInterstitialEnabled) return;
    
    _interstitialTimer?.cancel();
    _interstitialTimer = Timer(Duration(seconds: _config.gameInterstitialInterval), () {
      _showCountdownAndAd();
    });
  }

  void _showCountdownAndAd() async {
    setState(() {
      _countdown = 3;
      _showCountdown = true;
    });

    // Countdown from 3 to 1
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _showCountdown = false;
        });
        // Show interstitial ad
        _showInterstitialAd();
      }
    });
  }

  Future<void> _showInterstitialAd() async {
    if (!_config.admobEnabled || !_config.gameInterstitialEnabled || !AdMobService.isSupported) {
      return;
    }

    final adMobService = await AdMobService.getInstance();
    await adMobService.showInterstitialAd(
      onAdDismissed: () {
        // Restart timer after ad is closed
        _startInterstitialTimer();
      },
      onAdFailedToShow: () {
        // Restart timer even if ad failed
        _startInterstitialTimer();
      },
    );
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation requests (including redirects)
            // print('🔗 Navigation requested: ${request.url}');
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            // Log page to history
            _pageHistory.add(url);
            // print('📄 Page started: $url');
            // print('📚 History count: ${_pageHistory.length}');
            // print('📋 Full history: $_pageHistory');
            
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            // print('✅ Page finished loading: $url');
            setState(() {
              _isLoading = false;
              _showSplash = _config.gameLoaderEnabled; // Show splash based on config
            });
            
            if (_config.gameLoaderEnabled) {
              _splashAnimationController.forward();
              
              // Hide splash screen after configured duration
              Future.delayed(Duration(seconds: _config.gameLoaderDuration), () {
                if (mounted) {
                  setState(() {
                    _showSplash = false;
                  });
                  // Start interstitial timer after splash is hidden
                  _startInterstitialTimer();
                }
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView error: ${error.description}');
            print('Error code: ${error.errorCode}');
            print('Error type: ${error.errorType}');
          },
        ),
      )
      ..loadRequest(Uri.parse(_config.gameUrl));
  }

  void _toggleMenu() {
    setState(() {
      _showMenu = !_showMenu;
    });
    if (_showMenu) {
      _menuAnimationController.forward();
    } else {
      _menuAnimationController.reverse();
    }
  }

  void _reloadPage() {
    _controller?.reload();
    _toggleMenu();
  }

  void _exitPage() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_configLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          if (_isLoading)
            Container(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(
                  color: _config.accentColor,
                ),
              ),
            ),
          // Splash screen after loading
          if (_showSplash)
            Container(
              color: Colors.black,
              child: Center(
                child: FadeTransition(
                  opacity: _splashAnimationController,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _splashAnimationController,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset.zero,
                            end: const Offset(0, -0.1),
                          ).animate(
                            CurvedAnimation(
                              parent: _bounceAnimationController,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              _config.appIcon,
                              width: 100,
                              height: 100,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: _config.primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.gamepad,
                                    size: 70,
                                    color: Color.fromARGB(107, 255, 255, 255),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _config.appTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                color: _config.primaryColor.withOpacity(0.5),
                                offset: const Offset(0, 2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        Container(
                          width: 200,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.white,
                              valueColor: AlwaysStoppedAnimation<Color>(_config.accentColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Menu overlay
          if (_showMenu)
            GestureDetector(
              onTap: _toggleMenu,
              child: Container(
                color: Colors.black.withOpacity(1),
              ),
            ),
          // Menu dialog
          if (_showMenu)
            Center(
              child: FadeTransition(
                opacity: _menuAnimationController,
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _menuAnimationController,
                    curve: Curves.easeOutBack,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMenuButton(
                          imagePath: _config.gameReloadButtonImage,
                          label: _config.gameReloadButtonLabel,
                          onTap: _reloadPage,
                        ),
                        const SizedBox(width: 15),
                        _buildMenuButton(
                          imagePath: _config.gameExitButtonImage,
                          label: _config.gameExitButtonLabel,
                          onTap: _exitPage,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Ad countdown
          if (_showCountdown)
            _buildCountdownWidget(),
          // Draggable FAB
          Positioned(
            right: _fabPosition.dx,
            bottom: _fabPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _fabPosition = Offset(
                    (_fabPosition.dx - details.delta.dx)
                        .clamp(0, MediaQuery.of(context).size.width - 40),
                    (_fabPosition.dy - details.delta.dy)
                        .clamp(0, MediaQuery.of(context).size.height - 40),
                  );
                });
              },
              child: _buildFAB(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required String imagePath,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: 60,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.error, color: _config.primaryColor, size: 24);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB({bool isDragging = false}) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 0.9).animate(
        CurvedAnimation(
          parent: _fabAnimationController,
          curve: Curves.easeInOut,
        ),
      ),
      child: GestureDetector(
        onTapDown: (_) => _fabAnimationController.forward(),
        onTapUp: (_) {
          _fabAnimationController.reverse();
          if (!isDragging) _toggleMenu();
        },
        onTapCancel: () => _fabAnimationController.reverse(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Image.asset(
            _config.gameFabImage,
            width: 40,
            height: 40,
            fit: BoxFit.fill,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_config.primaryColor, _config.primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  _showMenu ? Icons.close : Icons.menu,
                  color: Colors.white,
                  size: 28,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownWidget() {
    // Determine position based on config
    Widget countdownContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _config.accentColor, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.ad_units, color: _config.accentColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Ad in $_countdown',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    // Position based on config
    switch (_config.gameInterstitialCountdownPosition.toLowerCase()) {
      case 'topleft':
        return Positioned(
          top: 50,
          left: 16,
          child: countdownContent,
        );
      case 'topright':
        return Positioned(
          top: 50,
          right: 16,
          child: countdownContent,
        );
      case 'bottomleft':
        return Positioned(
          bottom: 80,
          left: 16,
          child: countdownContent,
        );
      case 'bottomright':
        return Positioned(
          bottom: 80,
          right: 16,
          child: countdownContent,
        );
      case 'center':
      case 'middle':
      default:
        return Center(
          child: countdownContent,
        );
    }
  }
}
