import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/app_config.dart';
import '../services/admob_service.dart';
import '../services/iap_service.dart';
import '../widgets/banner_ad_widget.dart';
import 'game_screen.dart';
import '../utils/page_transition.dart';

class DifficultyScreen extends StatefulWidget {
  final String gender;
  final String name;
  final String email;

  const DifficultyScreen({
    super.key,
    required this.gender,
    required this.name,
    required this.email,
  });

  @override
  State<DifficultyScreen> createState() => _DifficultyScreenState();
}

class _DifficultyScreenState extends State<DifficultyScreen>
    with TickerProviderStateMixin {
  String? _selectedDifficulty;
  bool _showContinueButton = false;
  bool _showSubscriptionPopup = false;
  late AnimationController _backButtonController;
  late AnimationController _easyButtonController;
  late AnimationController _normalButtonController;
  late AnimationController _hardButtonController;
  late AnimationController _continueButtonController;
  late AppConfig _config;
  bool _configLoaded = false;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _backButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _easyButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _normalButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _hardButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _continueButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  Future<void> _loadConfig() async {
    _config = await AppConfig.getInstance();
    setState(() {
      _configLoaded = true;
    });

    // Load banner ad only if user doesn't have active subscription
    if (_config.admobEnabled && AdMobService.isSupported) {
      final adMobService = await AdMobService.getInstance();
      final shouldShowAds = await adMobService.shouldShowAds();
      
      if (shouldShowAds) {
        _bannerAd = adMobService.createBannerAd();
        _bannerAd!.load().then((_) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _backButtonController.dispose();
    _easyButtonController.dispose();
    _normalButtonController.dispose();
    _hardButtonController.dispose();
    _continueButtonController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _showSubscriptionPopupDialog() {
    if (!_config.subscriptionEnabled) {
      // If subscription is disabled, show continue button immediately
      setState(() {
        _showContinueButton = true;
      });
      return;
    }

    setState(() {
      _showSubscriptionPopup = true;
    });
  }

  void _closeSubscriptionPopup() {
    setState(() {
      _showSubscriptionPopup = false;
      _showContinueButton = true;
    });
  }

  Future<void> _handlePurchase() async {
    try {
      final iapService = await IAPService.getInstance();

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text(
                    'Processing purchase...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Use 'monthly' as default subscription type
      // You can show a selection dialog here if you want to offer multiple types
      await iapService.purchaseSubscription(
        type: 'monthly', // Change to show selection: 'weekly', 'monthly', or 'lifetime'
        onSuccess: () {
          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            _closeSubscriptionPopup();
            _showSuccessMessage(
                'Subscription activated! Enjoy ad-free experience.');
            // Reload the screen to hide ads
            setState(() {
              _isBannerAdLoaded = false;
            });
            _bannerAd?.dispose();
            _bannerAd = null;
          }
        },
        onError: (error) {
          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            _showErrorMessage(error);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorMessage('Failed to process purchase: $e');
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
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
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              _config.difficultyBackgroundImage,
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDifficultyButton(
                      _config.difficultyHardLabel,
                      Colors.red,
                      _config.difficultyHardImage,
                      _hardButtonController,
                    ),
                    const SizedBox(width: 25),
                    _buildDifficultyButton(
                      _config.difficultyNormalLabel,
                      Colors.orange,
                      _config.difficultyNormalImage,
                      _normalButtonController,
                    ),
                    const SizedBox(width: 25),
                    _buildDifficultyButton(
                      _config.difficultyEasyLabel,
                      Colors.green,
                      _config.difficultyEasyImage,
                      _easyButtonController,
                    ),
                  ],
                ),
              ),
            ),

            // Back button at top left
            Positioned(
              top: 20,
              left: 20,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: _config.scaleDownPlay)
                    .animate(
                  CurvedAnimation(
                    parent: _backButtonController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: GestureDetector(
                  onTapDown: (_) => _backButtonController.forward(),
                  onTapUp: (_) {
                    _backButtonController.reverse();
                    Navigator.pop(context);
                  },
                  onTapCancel: () => _backButtonController.reverse(),
                  child: SizedBox(
                    height: 45,
                    child: Image.asset(
                      _config.difficultyCloseImage,
                      height: 45,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 30,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Continue button at bottom right
            if (_showContinueButton)
              Positioned(
                bottom: 20,
                right: 20,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: _config.scaleDownPlay)
                      .animate(
                    CurvedAnimation(
                      parent: _continueButtonController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: GestureDetector(
                    onTapDown: (_) => _continueButtonController.forward(),
                    onTapUp: (_) {
                      _continueButtonController.reverse();
                      if (_config.gameEnabled) {
                        Navigator.push(
                          context,
                          FadePageRoute(
                            page: const GameScreen(),
                          ),
                        );
                      }
                    },
                    onTapCancel: () => _continueButtonController.reverse(),
                    child: SizedBox(
                      height: 50,
                      child: Image.asset(
                        _config.difficultyContinueButtonImage,
                        height: 50,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            decoration: BoxDecoration(
                              color: _config.accentColor,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              'CONTINUE',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

            // Banner Ad positioned at bottom
            if (_isBannerAdLoaded && _bannerAd != null)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: BannerAdWidget(
                      key: ValueKey(_bannerAd), bannerAd: _bannerAd!),
                ),
              ),

            // Subscription Popup Overlay
            if (_showSubscriptionPopup)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _config.subscriptionBarrierDismissible
                      ? _closeSubscriptionPopup
                      : null,
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {}, // Prevent tap from propagating to barrier
                        child: ClipRect(
                          clipBehavior: Clip.none,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: _config.subscriptionPopupWidth,
                                height:
                                    MediaQuery.of(context).size.height * 0.9,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(
                                        _config.subscriptionBackgroundImage),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // No Ads Icon
                                      Image.asset(
                                        _config.subscriptionIconImage,
                                        height: _config.subscriptionIconHeight,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.block,
                                            size: 120,
                                            color: Colors.white,
                                          );
                                        },
                                      ),

                                      const SizedBox(height: 0),

                                      // NO ADS! Text
                                      Text(
                                        _config.subscriptionTitleText,
                                        style: TextStyle(
                                          fontSize:
                                              _config.subscriptionTitleFontSize,
                                          fontWeight: FontWeight.bold,
                                          color: _config.subscriptionTitleColor,
                                          shadows: [
                                            Shadow(
                                              color: _config
                                                  .subscriptionTitleShadowColor,
                                              blurRadius: _config
                                                  .subscriptionTitleShadowBlurRadius,
                                              offset: const Offset(0, 0),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 0),

                                      // Subtitle Text
                                      Text(
                                        _config.subscriptionSubtitleText,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: _config
                                              .subscriptionSubtitleFontSize,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              _config.subscriptionSubtitleColor,
                                          shadows: [
                                            Shadow(
                                              color: _config
                                                  .subscriptionSubtitleShadowColor,
                                              blurRadius: _config
                                                  .subscriptionSubtitleShadowBlurRadius,
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 15),

                                      // Price Tag with Text - Tappable
                                      GestureDetector(
                                        onTap: _handlePurchase,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Image.asset(
                                              _config.subscriptionPriceTagImage,
                                              height: 60,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  child: Text(
                                                    _config
                                                        .subscriptionPriceText,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            Positioned(
                                              child: Text(
                                                _config.subscriptionPriceText,
                                                style: TextStyle(
                                                  fontSize: _config
                                                      .subscriptionPriceFontSize,
                                                  fontWeight: FontWeight.bold,
                                                  color: _config
                                                      .subscriptionPriceColor,
                                                  shadows: [
                                                    Shadow(
                                                      color: _config
                                                          .subscriptionPriceShadowColor,
                                                      blurRadius: _config
                                                          .subscriptionPriceShadowBlurRadius,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Close button at top right
                              Positioned(
                                top: _config.subscriptionCloseButtonTop,
                                right: _config.subscriptionCloseButtonRight,
                                child: GestureDetector(
                                  onTap: _closeSubscriptionPopup,
                                  child: Image.asset(
                                    _config.subscriptionCloseImage,
                                    height:
                                        _config.subscriptionCloseButtonHeight,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.black87,
                                          size: 24,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ], // Stack children
        ), // Stack
      ), // Container
    ); // Scaffold body
  }

  Widget _buildDifficultyButton(String difficulty, Color color, String iconUrl,
      AnimationController controller) {
    final isSelected = _selectedDifficulty == difficulty;
    final hasSelection = _selectedDifficulty != null;
    final shouldReduceOpacity = hasSelection && !isSelected;

    return AnimatedOpacity(
      opacity: shouldReduceOpacity ? _config.difficultyUnselectedOpacity : 1.0,
      duration: const Duration(milliseconds: 300),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: _config.scaleDownPlay).animate(
          CurvedAnimation(
            parent: controller,
            curve: Curves.easeInOut,
          ),
        ),
        child: GestureDetector(
          onTapDown: (_) => controller.forward(),
          onTapUp: (_) {
            controller.reverse();
            setState(() {
              _selectedDifficulty = difficulty;
            });
            // Show popup after selection
            Future.delayed(const Duration(milliseconds: 300), () {
              _showSubscriptionPopupDialog();
            });
          },
          onTapCancel: () => controller.reverse(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  iconUrl,
                  width: 180,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      difficulty == 'Easy'
                          ? Icons.sentiment_satisfied
                          : difficulty == 'Normal'
                              ? Icons.sentiment_neutral
                              : Icons.sentiment_very_dissatisfied,
                      size: 50,
                      color: Colors.white,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
