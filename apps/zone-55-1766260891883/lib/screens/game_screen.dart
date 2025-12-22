import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/app_config.dart';

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
  late AnimationController _menuAnimationController;
  late AnimationController _fabAnimationController;
  Offset _fabPosition = const Offset(20, 20); // Position from bottom-right
  final List<String> _pageHistory = []; // Track all visited pages

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
    _loadConfig();
  }

  @override
  void dispose() {
    _menuAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    _config = await AppConfig.getInstance();
    setState(() {
      _configLoaded = true;
    });
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // Log page to history
            _pageHistory.add(url);
            print('📄 Page started: $url');
            print('📚 History count: ${_pageHistory.length}');
            print('📋 Full history: $_pageHistory');
            
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            print('✅ Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
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
}
