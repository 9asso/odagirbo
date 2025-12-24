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
      ..setOnConsoleMessage((JavaScriptConsoleMessage message) {
        print('🌐 WebView Console: ${message.message}');
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Block about:blank (popups)
            if (request.url == 'about:blank' || request.url.startsWith('about:blank')) {
              print('🚫 Blocked popup: ${request.url}');
              return NavigationDecision.prevent;
            }
            // Block requests containing 'games-sdk.playhop.com'
            if (request.url.contains('games-sdk.playhop.com')) {
              print('🚫 Blocked request: ${request.url}');
              return NavigationDecision.prevent;
            }
            // Allow all other navigation requests (including redirects)
            print('🔗 Navigation requested: ${request.url}');
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
            print('✅ Page finished loading: $url');
            
            // Inject JavaScript to remove unwanted modals
            _injectModalBlocker();
            
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

  void _injectModalBlocker() {
    // Inject JavaScript to automatically dismiss the modal (mobile version)
    final script = '''
      (function() {
        const processedModals = new Set();
        
        function closeModal() {
          let foundNewModal = false;
          
          // Method 1: Click on backdrop/overlay (only if visible and not GDPR)
          const overlays = document.querySelectorAll('.modal-wrapper, [class*="overlay"], [class*="backdrop"]');
          overlays.forEach(overlay => {
            // Skip GDPR overlay and already processed ones
            if (overlay.classList.contains('gdpr-overlay')) return;
            
            // Only process if visible
            const isVisible = overlay.offsetParent !== null && 
                            window.getComputedStyle(overlay).display !== 'none' &&
                            window.getComputedStyle(overlay).visibility !== 'hidden';
            
            if (isVisible && !processedModals.has(overlay)) {
              console.log('🖱️ Clicking overlay:', overlay.className);
              overlay.click();
              processedModals.add(overlay);
              foundNewModal = true;
            }
          });
          
          // Method 2: Find and click close button
          const closeButtons = document.querySelectorAll('.close-button, .close-button_type_popup, [aria-label*="close" i], [aria-label*="закрыть" i]');
          closeButtons.forEach(button => {
            const isVisible = button.offsetParent !== null;
            if (isVisible && !processedModals.has(button)) {
              console.log('🖱️ Clicking close button:', button.className);
              button.click();
              processedModals.add(button);
              foundNewModal = true;
            }
          });
          
          // Method 3: Simulate swipe down on payment modals
          const modals = document.querySelectorAll('[data-testid="in-app-form"], .inAppForm, [class*="PaymentsModal"]');
          modals.forEach(modal => {
            const isVisible = modal.offsetParent !== null;
            if (isVisible && !processedModals.has(modal)) {
              const modalContent = modal.querySelector('[class*="modal"]') || modal;
              
              const touchStart = new TouchEvent('touchstart', {
                touches: [new Touch({
                  identifier: Date.now(),
                  target: modalContent,
                  clientX: 100,
                  clientY: 50,
                  pageX: 100,
                  pageY: 50
                })]
              });
              
              const touchEnd = new TouchEvent('touchend', {
                changedTouches: [new Touch({
                  identifier: Date.now(),
                  target: modalContent,
                  clientX: 100,
                  clientY: 300,
                  pageX: 100,
                  pageY: 300
                })]
              });
              
              console.log('👆 Simulating swipe down on payment modal');
              modalContent.dispatchEvent(touchStart);
              setTimeout(() => modalContent.dispatchEvent(touchEnd), 50);
              processedModals.add(modal);
              foundNewModal = true;
            }
          });
          
          if (foundNewModal) {
            console.log('✅ Modal dismissed');
          }
        }
        
        // Run immediately
        console.log('🚀 Modal blocker initialized');
        closeModal();
        
        // Run every 1 second to catch modals quickly
        setInterval(closeModal, 1000);
        
        // Watch for DOM changes (only for new modal additions)
        const observer = new MutationObserver((mutations) => {
          const hasNewModal = mutations.some(m => 
            Array.from(m.addedNodes).some(node => 
              node.nodeType === 1 && 
              (node.classList?.contains('modal-wrapper') || 
               node.classList?.contains('inAppForm') ||
               node.dataset?.testid === 'in-app-form')
            )
          );
          if (hasNewModal) {
            console.log('🔄 New modal detected');
            closeModal();
          }
        });
        observer.observe(document.body, { childList: true, subtree: true });
      })();
    ''';
    
    _controller?.runJavaScript(script);
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
              height: 100,
              fit: BoxFit.fill,
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
