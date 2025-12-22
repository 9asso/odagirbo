import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'user_info_screen.dart';
import 'difficulty_screen.dart';
import '../utils/page_transition.dart';
import '../services/app_config.dart';
import '../services/admob_service.dart';
import '../widgets/banner_ad_widget.dart';

class GenderSelectionScreen extends StatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  State<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen>
    with TickerProviderStateMixin {
  String? _selectedGender;
  late AnimationController _girlButtonController;
  late AnimationController _boyButtonController;
  late AnimationController _closeButtonController;
  late AnimationController _nextButtonController;
  late AppConfig _config;
  bool _configLoaded = false;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  // bool _hasShownInterstitial = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _girlButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _boyButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _closeButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _nextButtonController = AnimationController(
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

  void _navigateToNextScreen() async {
    // Show loading dialog
    if (_config.admobEnabled) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
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
                    'Loading Ad...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Show interstitial ad
        if (AdMobService.isSupported) {
          final adMobService = await AdMobService.getInstance();
          await adMobService.showInterstitialAd(
        onAdDismissed: () {
          // Close loading dialog
          if (mounted) Navigator.of(context).pop();
          // Navigate to next screen
          _proceedToNextScreen();
        },
        onAdFailedToShow: () {
          // Close loading dialog
          if (mounted) Navigator.of(context).pop();
          // Navigate to next screen anyway
          _proceedToNextScreen();
        },
          );
        } else {
          _proceedToNextScreen();
        }
    } else {
      _proceedToNextScreen();
    }
  }

  void _proceedToNextScreen() {
    // Flow: userInfo -> difficulty
    if (_config.isScreenEnabled('userInfo')) {
      Navigator.push(
        context,
        FadePageRoute(
          page: UserInfoScreen(
            gender: _selectedGender!,
          ),
        ),
      );
    } else if (_config.isScreenEnabled('difficulty')) {
      // Skip user info, go directly to difficulty
      Navigator.push(
        context,
        FadePageRoute(
          page: DifficultyScreen(
            gender: _selectedGender!,
            name: 'Player',
            email: 'player@game.com',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _girlButtonController.dispose();
    _boyButtonController.dispose();
    _closeButtonController.dispose();
    _nextButtonController.dispose();
    _bannerAd?.dispose();
    super.dispose();
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
              _config.genderBackgroundImage,
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
                  // Title at top
                  Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: SizedBox(
                      // width: double.infinity,
                      height: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          _config.genderTitleImage,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                _config.genderFallbackTitle,
                                style: const TextStyle(
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

                  // Gender selection buttons in the middle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildGenderButton(
                        'girl',
                        _config.genderGirlImage,
                        'Girl',
                        Colors.pink,
                        _girlButtonController,
                      ),
                      const SizedBox(width: 25),
                      _buildGenderButton(
                        'boy',
                        _config.genderBoyImage,
                        'Boy',
                        Colors.blue,
                        _boyButtonController,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Close button at top left
            Positioned(
                top: 20,
                left: 20,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: _config.scaleDownPlay).animate(
                    CurvedAnimation(
                      parent: _closeButtonController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: GestureDetector(
                    onTapDown: (_) => _closeButtonController.forward(),
                    onTapUp: (_) {
                      _closeButtonController.reverse();
                      Navigator.pop(context);
                    },
                    onTapCancel: () => _closeButtonController.reverse(),
                    child: SizedBox(
                      height: 45,
                      child: Image.asset(
                        _config.genderCloseImage,
                        height: 45,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.arrow_forward,
                            color: Colors.black,
                            size: 30,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Next button at bottom right
              Positioned(
                bottom: 20,
                right: 20,
                child: AnimatedOpacity(
                  opacity: _selectedGender != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: _config.scaleDownPlay).animate(
                      CurvedAnimation(
                        parent: _nextButtonController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: GestureDetector(
                      onTapDown: _selectedGender != null
                          ? (_) => _nextButtonController.forward()
                          : null,
                      onTapUp: _selectedGender != null
                            ? (_) {
                              _nextButtonController.reverse();
                              _navigateToNextScreen();
                            }
                          : null,
                      onTapCancel: () => _nextButtonController.reverse(),
                      child: SizedBox(
                        height: 50,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                _config.genderNextImage,
                                height: 50,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.black,
                                    size: 30,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
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
              child: BannerAdWidget(key: ValueKey(_bannerAd), bannerAd: _bannerAd!),
            ),
          ),
      ], // Stack children
    ), // Stack
  ), // Container
); // Scaffold body
  }

  Widget _buildGenderButton(String gender, String iconUrl, String label,
      Color color, AnimationController controller) {
    final isSelected = _selectedGender == gender;

    return GestureDetector(
      onTapDown: (_) => controller.forward(),
      onTapUp: (_) async {
        controller.reverse();
        setState(() {
          _selectedGender = gender;
        });
        
        // Show interstitial ad only once
        // if (_config.admobEnabled && !_hasShownInterstitial) {
        //   _hasShownInterstitial = true;
        //   final adMobService = await AdMobService.getInstance();
        //   adMobService.showInterstitialAd();
        // }
      },
      onTapCancel: () => controller.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: _config.scaleDownPlay).animate(
          CurvedAnimation(
            parent: controller,
            curve: Curves.easeInOut,
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                iconUrl,
                height: 140,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    gender == 'girl' ? Icons.girl : Icons.boy,
                    size: 80,
                    color: color,
                  );
                },
              ),
              const SizedBox(height: 0),
              if (isSelected)
                const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(
                      Icons.check_circle,
                      color: Color(0xFF63397e),
                      size: 30,
                    ))
              else
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(
                    Icons.circle_sharp,
                    color: Color.fromRGBO(100, 57, 126, 0.1),
                    size: 30,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
