import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import 'gender_selection_screen.dart';
import 'user_info_screen.dart';
import 'difficulty_screen.dart';
import 'game_screen.dart';
import 'more_games_screen.dart';
import '../utils/page_transition.dart';
import '../services/app_config.dart';
import '../services/admob_service.dart';
import '../widgets/banner_ad_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _playButtonController;
  late AnimationController _shareButtonController;
  late AnimationController _moreButtonController;
  late AnimationController _rateButtonController;
  late AppConfig _config;
  bool _configLoaded = false;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _playButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _shareButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _moreButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _rateButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  Future<void> _loadConfig() async {
    _config = await AppConfig.getInstance();
    setState(() {
      _configLoaded = true;
    });

    // Load banner ad
    if (_config.admobEnabled && AdMobService.isSupported) {
      final adMobService = await AdMobService.getInstance();
      _bannerAd = adMobService.createBannerAd();
      _bannerAd!.load().then((_) {
        setState(() {
          _isBannerAdLoaded = true;
        });
      });
    }
  }

  void _navigateToNextScreen() {
    // Flow: genderSelection -> userInfo -> difficulty
    if (_config.isScreenEnabled('genderSelection')) {
      Navigator.push(
        context,
        FadePageRoute(
          page: const GenderSelectionScreen(),
        ),
      );
    } else if (_config.isScreenEnabled('userInfo')) {
      // Skip gender selection, go to user info with default gender
      Navigator.push(
        context,
        FadePageRoute(
          page: const UserInfoScreen(gender: 'default'),
        ),
      );
    } else if (_config.isScreenEnabled('difficulty')) {
      // Skip both gender and user info, go directly to difficulty
      Navigator.push(
        context,
        FadePageRoute(
          page: const DifficultyScreen(
            gender: 'default',
            name: 'Player',
            email: 'player@game.com',
          ),
        ),
      );
    } else {
      // All screens are disabled, go directly to game
      Navigator.push(
        context,
        FadePageRoute(
          page: const GameScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _playButtonController.dispose();
    _shareButtonController.dispose();
    _moreButtonController.dispose();
    _rateButtonController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _handleShare() {
    final box = context.findRenderObject() as RenderBox?;
    Share.share(
      _config.homeShareMessage,
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  Future<void> _showRatingDialog() async {
    final InAppReview inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    }
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
              _config.homeBackgroundImage,
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Game Name/Logo at top
                  Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: SizedBox(
                      // width: double.infinity,
                      height: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          _config.homeHeaderImage,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text(
                                'GAME NAME',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Play Button in the middle
                  GestureDetector(
                    onTapDown: (_) => _playButtonController.forward(),
                    onTapUp: (_) {
                      _playButtonController.reverse();
                      _navigateToNextScreen();
                    },
                    onTapCancel: () => _playButtonController.reverse(),
                    child: ScaleTransition(
                      scale:
                          Tween<double>(begin: 1.0, end: _config.scaleDownPlay)
                              .animate(
                        CurvedAnimation(
                          parent: _playButtonController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: SizedBox(
                        height: 100,
                        child: Center(
                          child: Image.asset(
                            _config.homePlayImage,
                            height: 100,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.play_arrow,
                                size: 100,
                                color: Colors.white,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Bottom buttons
                  Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_config.homeShareButtonEnabled)
                          _buildBottomButton(
                            _config.homeShareButtonImage,
                            _config.homeShareButtonLabel,
                            _handleShare,
                            _shareButtonController,
                          ),
                        if (_config.homeMoreGamesButtonEnabled)
                          _buildBottomButton(
                            _config.homeMoreGamesButtonImage,
                            _config.homeMoreGamesButtonLabel,
                            () {
                              if (_config.isScreenEnabled('moreGames')) {
                                Navigator.push(
                                  context,
                                  FadePageRoute(
                                    page: const MoreGamesScreen(),
                                  ),
                                );
                              }
                            },
                            _moreButtonController,
                          ),
                        if (_config.homeRateButtonEnabled)
                          _buildBottomButton(
                            _config.homeRateButtonImage,
                            _config.homeRateButtonLabel,
                            _showRatingDialog,
                            _rateButtonController,
                          ),
                      ],
                    ),
                  ),
                ],
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
          ], // Stack children
        ), // Stack
      ), // Container
    ); // Scaffold body
  }

  Widget _buildBottomButton(String iconUrl, String label, VoidCallback onTap,
      AnimationController controller) {
    return GestureDetector(
      onTapDown: (_) => controller.forward(),
      onTapUp: (_) {
        controller.reverse();
        onTap();
      },
      onTapCancel: () => controller.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: _config.scaleDownButton).animate(
          CurvedAnimation(
            parent: controller,
            curve: Curves.easeInOut,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12.5),
          height: 50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                iconUrl,
                height: 50,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image, size: 40);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
