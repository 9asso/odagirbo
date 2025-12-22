import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'difficulty_screen.dart';
import '../utils/page_transition.dart';
import '../services/app_config.dart';
import '../services/admob_service.dart';
import '../widgets/banner_ad_widget.dart';

class UserInfoScreen extends StatefulWidget {
  final String gender;

  const UserInfoScreen({super.key, required this.gender});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  late AnimationController _backButtonController;
  late AnimationController _nextButtonController;
  late AppConfig _config;
  bool _configLoaded = false;
  bool _canProceed = false;
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
    _nextButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Listen to text field changes
    _nameController.addListener(_updateCanProceed);
    _emailController.addListener(_updateCanProceed);
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

  void _navigateToNextScreen(String name, String email) {
    // Flow: difficulty (final screen)
    if (_config.isScreenEnabled('difficulty')) {
      Navigator.push(
        context,
        FadePageRoute(
          page: DifficultyScreen(
            gender: widget.gender,
            name: name,
            email: email,
          ),
        ),
      );
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  void _updateCanProceed() {
    final newCanProceed = _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _isValidEmail(_emailController.text.trim());
    
    setState(() {
      _canProceed = newCanProceed;
    });
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateCanProceed);
    _emailController.removeListener(_updateCanProceed);
    _nameController.dispose();
    _emailController.dispose();
    _backButtonController.dispose();
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
              _config.userInfoBackgroundImage,
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                          // Full Name Input
                          _buildInputField(
                            controller: _nameController,
                            hint: _config.userInfoNameHint,
                            icon: Icons.person,
                          ),

                          const SizedBox(height: 25),

                          // Email Input
                          _buildInputField(
                            controller: _emailController,
                            hint: _config.userInfoEmailHint,
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ),

                    const SizedBox(height: 25),
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
                        _config.userInfoCloseImage,
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

              // Next button at bottom right
              Positioned(
                bottom: 20,
                right: 20,
                child: AnimatedOpacity(
                  opacity: _canProceed ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: _config.scaleDownPlay)
                        .animate(
                      CurvedAnimation(
                        parent: _nextButtonController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: GestureDetector(
                      onTapDown: _canProceed
                          ? (_) => _nextButtonController.forward()
                          : null,
                      onTapUp: _canProceed
                          ? (_) {
                              _nextButtonController.reverse();
                              final name = _nameController.text.trim();
                              final email = _emailController.text.trim();

                              if (name.isEmpty) {
                                _showToast(_config.validationNameEmpty);
                                return;
                              }

                              if (name.length > _config.userInfoNameMaxLength) {
                                _showToast(_config.validationNameTooLong);
                                return;
                              }

                              if (email.isEmpty) {
                                _showToast(_config.validationEmailEmpty);
                                return;
                              }

                              if (!_isValidEmail(email)) {
                                _showToast(_config.validationEmailInvalid);
                                return;
                              }

                              _navigateToNextScreen(name, email);
                            }
                          : null,
                      onTapCancel: () => _nextButtonController.reverse(),
                      child: SizedBox(
                        height: 50,
                        child: Image.asset(
                          _config.userInfoNextImage,
                          height: 50,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 30,
                            );
                          },
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

    Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Center(
      child: Container(
        width: 350,
        height: 60,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              _config.userInfoInputBackgroundImage,
            ),
            fit: BoxFit.fill,
            onError: (exception, stackTrace) {},
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLength: hint == _config.userInfoNameHint
                      ? _config.userInfoNameMaxLength
                      : _config.userInfoEmailMaxLength,
                  textCapitalization: hint == _config.userInfoNameHint
                      ? TextCapitalization.words
                      : TextCapitalization.none,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jua(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(255, 87, 39, 111),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.jua(
                      color: const Color.fromARGB(37, 87, 39, 111),
                      fontSize: 21,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }}