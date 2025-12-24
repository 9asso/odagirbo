import 'dart:convert';
import 'package:flutter/services.dart';

class AppConfig {
  static AppConfig? _instance;
  late Map<String, dynamic> _config;

  AppConfig._();

  static Future<AppConfig> getInstance() async {
    if (_instance == null) {
      _instance = AppConfig._();
      await _instance!._loadConfig();
    }
    return _instance!;
  }

  Future<void> _loadConfig() async {
    final configString = await rootBundle.loadString('assets/config.json');
    _config = json.decode(configString);
  }

  // App settings
  String get appTitle => _config['app']['title'] ?? 'Subscription Game';
  String get appIcon => _config['app']['icon'] ?? 'assets/pack/loadingtxt.png';
  String get packageName => _config['app']['packageName'] ?? 'com.example.app';
  bool get enableSplashScreen => _config['app']['enableSplashScreen'] ?? true;
  int get loadingProgressSpeed => _config['app']['loadingProgressSpeed'] ?? 30;
  double get loadingProgressIncrement =>
      _config['app']['loadingProgressIncrement'] ?? 0.01;

  // AdMob settings
  bool get admobEnabled => _config['admob']?['enabled'] ?? false;
  bool get admobTestMode => _config['admob']?['testMode'] ?? true;

  String get androidAdmobAppId => _config['admob']?['android']?['appId'] ?? '';
  String get androidBannerAdUnitId =>
      _config['admob']?['android']?['bannerAdUnitId'] ?? '';
  String get androidInterstitialAdUnitId =>
      _config['admob']?['android']?['interstitialAdUnitId'] ?? '';

  String get iosAdmobAppId => _config['admob']?['ios']?['appId'] ?? '';
  String get iosBannerAdUnitId =>
      _config['admob']?['ios']?['bannerAdUnitId'] ?? '';
  String get iosInterstitialAdUnitId =>
      _config['admob']?['ios']?['interstitialAdUnitId'] ?? '';

  // Game settings
  bool get gameEnabled => _config['game']?['enabled'] ?? true;
  String get gameUrl => _config['game']?['url'] ?? 'https://example.com/game';
  
  // Game loader
  bool get gameLoaderEnabled => _config['game']?['loader']?['enabled'] ?? true;
  int get gameLoaderDuration => _config['game']?['loader']?['duration'] ?? 8;

  // Game interstitial
  bool get gameInterstitialEnabled => _config['game']?['interstitial']?['enabled'] ?? true;
  int get gameInterstitialInterval => _config['game']?['interstitial']?['interval'] ?? 60;
  String get gameInterstitialCountdownPosition => _config['game']?['interstitial']?['countdownPosition'] ?? 'topRight';

  // Game UI (GameScreen)
  String get gameFabImage =>
      _config['game']?['menu']?['fab']?['image'] ?? 'assets/pack/circle.png';
  String get gameReloadButtonImage =>
      _config['game']?['menu']?['buttons']?['reload']?['image'] ??
      'assets/pack/reload.png';
  String get gameReloadButtonLabel =>
      _config['game']?['menu']?['buttons']?['reload']?['label'] ?? 'Reload';
  String get gameExitButtonImage =>
      _config['game']?['menu']?['buttons']?['exit']?['image'] ??
      'assets/pack/exit.png';
  String get gameExitButtonLabel =>
      _config['game']?['menu']?['buttons']?['exit']?['label'] ?? 'Exit';

  // Screen enabled states
  bool isScreenEnabled(String screenName) {
    return _config['screens'][screenName]?['enabled'] ?? true;
  }

  // Home screen
  bool get homeShareButtonEnabled =>
      _config['screens']['home']['buttons']['share']['enabled'] ?? true;
  bool get homeMoreGamesButtonEnabled =>
      _config['screens']['home']['buttons']['moreGames']['enabled'] ?? true;
  bool get homeRateButtonEnabled =>
      _config['screens']['home']['buttons']['rate']['enabled'] ?? true;

  String get homeShareButtonImage =>
      _config['screens']['home']['buttons']['share']['image'] ??
      'assets/pack/share.png';
  String get homeMoreGamesButtonImage =>
      _config['screens']['home']['buttons']['moreGames']['image'] ??
      'assets/pack/more.png';
  String get homeRateButtonImage =>
      _config['screens']['home']['buttons']['rate']['image'] ??
      'assets/pack/rate.png';

  String get homeShareButtonLabel =>
      _config['screens']['home']['buttons']['share']['label'] ?? 'Share';
  String get homeMoreGamesButtonLabel =>
      _config['screens']['home']['buttons']['moreGames']['label'] ??
      'More Games';
  String get homeRateButtonLabel =>
      _config['screens']['home']['buttons']['rate']['label'] ?? 'Rate Us';

  String get homeShareMessage =>
      _config['screens']['home']['buttons']['share']['message'] ??
      'Check out this amazing game!';

  String get homeBackgroundImage =>
      _config['screens']['home']['images']['background'] ??
      'assets/pack/bg.png';
  String get homeHeaderImage =>
      _config['screens']['home']['images']['header'] ??
      'assets/pack/header.png';
  String get homePlayImage =>
      _config['screens']['home']['images']['play'] ?? 'assets/pack/play.png';

  // Gender Selection
  String get genderBackgroundImage =>
      _config['screens']['genderSelection']['images']['background'] ??
      'assets/pack/bg.png';
  String get genderTitleImage =>
      _config['screens']['genderSelection']['images']['title'] ??
      'assets/pack/boyorgirl.png';
  String get genderGirlImage =>
      _config['screens']['genderSelection']['images']['girl'] ??
      'assets/pack/girl.png';
  String get genderBoyImage =>
      _config['screens']['genderSelection']['images']['boy'] ??
      'assets/pack/boy.png';
  String get genderCloseImage =>
      _config['screens']['genderSelection']['images']['close'] ??
      'assets/pack/close.png';
  String get genderNextImage =>
      _config['screens']['genderSelection']['images']['next'] ??
      'assets/pack/next.png';
  String get genderFallbackTitle =>
      _config['screens']['genderSelection']['fallbackText']['title'] ??
      'Boy or Girl';

  // User Info
  String get userInfoBackgroundImage =>
      _config['screens']['userInfo']['images']['background'] ??
      'assets/pack/bg.png';
  String get userInfoCloseImage =>
      _config['screens']['userInfo']['images']['close'] ??
      'assets/pack/close.png';
  String get userInfoNextImage =>
      _config['screens']['userInfo']['images']['next'] ??
      'assets/pack/next.png';
  String get userInfoInputBackgroundImage =>
      _config['screens']['userInfo']['images']['inputBackground'] ??
      'assets/pack/continue.png';

  String get userInfoNameHint =>
      _config['screens']['userInfo']['fields']['name']['hint'] ?? 'Full Name';
  int get userInfoNameMaxLength =>
      _config['screens']['userInfo']['fields']['name']['maxLength'] ?? 25;
  String get userInfoEmailHint =>
      _config['screens']['userInfo']['fields']['email']['hint'] ??
      'Email Address';
  int get userInfoEmailMaxLength =>
      _config['screens']['userInfo']['fields']['email']['maxLength'] ?? 100;

  String get validationNameEmpty =>
      _config['screens']['userInfo']['validation']['messages']['nameEmpty'] ??
      'Please enter your name';
  String get validationNameTooLong =>
      _config['screens']['userInfo']['validation']['messages']['nameTooLong'] ??
      'Name is too long (max 25 characters)';
  String get validationEmailEmpty =>
      _config['screens']['userInfo']['validation']['messages']['emailEmpty'] ??
      'Please enter your email';
  String get validationEmailInvalid =>
      _config['screens']['userInfo']['validation']['messages']
          ['emailInvalid'] ??
      'Please enter a valid email address';
  String get validationEmailTooLong =>
      _config['screens']['userInfo']['validation']['messages']
          ['emailTooLong'] ??
      'Email is too long (max 100 characters)';

  // Difficulty
  String get difficultyTitleImage =>
      _config['screens']['difficulty']['titleImage'] ??
      'assets/pack/difficultytitle.png';
  String get difficultyBackgroundImage =>
      _config['screens']['difficulty']['images']['background'] ??
      'assets/pack/bg.png';
  String get difficultyCloseImage =>
      _config['screens']['difficulty']['images']['close'] ??
      'assets/pack/close.png';
  String get difficultyEasyImage =>
      _config['screens']['difficulty']['images']['easy'] ??
      'assets/pack/easy.png';
  String get difficultyNormalImage =>
      _config['screens']['difficulty']['images']['normal'] ??
      'assets/pack/normal.png';
  String get difficultyHardImage =>
      _config['screens']['difficulty']['images']['hard'] ??
      'assets/pack/hard.png';

  String get difficultyEasyLabel =>
      _config['screens']['difficulty']['buttons']['easy']['label'] ?? 'Easy';
  String get difficultyNormalLabel =>
      _config['screens']['difficulty']['buttons']['normal']['label'] ??
      'Normal';
  String get difficultyHardLabel =>
      _config['screens']['difficulty']['buttons']['hard']['label'] ?? 'Hard';

  double get difficultyUnselectedOpacity =>
      _config['screens']['difficulty']['unselectedOpacity'] ?? 0.3;

  String get difficultyContinueButtonImage =>
      _config['screens']?['difficulty']?['continueButtonImage'] ??
      _config['game']?['continueButtonImage'] ??
      'assets/pack/next.png';

  // More Games
  String get moreGamesBackgroundImage =>
      _config['screens']['moreGames']['images']['background'] ??
      'assets/pack/bg.png';
  String get moreGamesHeaderImage =>
      _config['screens']['moreGames']['images']['header'] ??
      'assets/pack/moregames.png';
  String get moreGamesCloseImage =>
      _config['screens']['moreGames']['images']['close'] ??
      'assets/pack/close.png';
  String get moreGamesFrameImage =>
      _config['screens']['moreGames']['images']['frame'] ??
      'assets/pack/frame.png';
  String get moreGamesFallbackTitle =>
      _config['screens']['moreGames']['fallbackText']['title'] ?? 'MORE GAMES';

  int get moreGamesGridColumns =>
      _config['screens']['moreGames']['grid']['columns'] ?? 3;
  double get moreGamesGridCrossSpacing =>
      (_config['screens']['moreGames']['grid']['crossSpacing'] ?? 25)
          .toDouble();
  double get moreGamesGridMainSpacing =>
      (_config['screens']['moreGames']['grid']['mainSpacing'] ?? 25).toDouble();
  double get moreGamesGridAspectRatio =>
      (_config['screens']['moreGames']['grid']['aspectRatio'] ?? 1.6)
          .toDouble();
  double get moreGamesGridBorderRadius =>
      (_config['screens']['moreGames']['grid']['borderRadius'] ?? 25)
          .toDouble();

  List<String> get moreGamesGameImages =>
      List<String>.from(_config['screens']['moreGames']['gameImages'] ?? []);

  // Splash
  String get splashBackgroundImage =>
      _config['screens']['splash']['images']['background'] ??
      'assets/pack/bg.png';
  String get splashLoadingTextImage =>
      _config['screens']['splash']['images']['loadingText'] ??
      'assets/pack/loadingtxt.png';
  String get splashLoadingEmptyImage =>
      _config['screens']['splash']['images']['loadingEmpty'] ??
      'assets/pack/loadingempty.png';

  double get splashProgressBarWidth =>
      (_config['screens']['splash']['progressBar']['width'] ?? 310).toDouble();
  double get splashProgressBarHeight =>
      (_config['screens']['splash']['progressBar']['height'] ?? 24).toDouble();
  double get splashProgressBarBorderRadius =>
      (_config['screens']['splash']['progressBar']['borderRadius'] ?? 10)
          .toDouble();

  // Subscription
  bool get subscriptionEnabled => _config['subscription']['enabled'] ?? true;
  bool get subscriptionBarrierDismissible =>
      _config['subscription']['popup']['barrierDismissible'] ?? false;
  double get subscriptionPopupWidth =>
      (_config['subscription']['popup']['width'] ?? 300).toDouble();
  double get subscriptionPopupHeight =>
      (_config['subscription']['popup']['height'] ?? 400).toDouble();

  String get subscriptionBackgroundImage =>
      _config['subscription']['popup']['images']['background'] ??
      'assets/pack/noadspopup.png';
  String get subscriptionIconImage =>
      _config['subscription']['popup']['images']['icon'] ??
      'assets/pack/noadsicon.png';
  String get subscriptionPriceTagImage =>
      _config['subscription']['popup']['images']['priceTag'] ??
      'assets/pack/pricetag.png';
  String get subscriptionCloseImage =>
      _config['subscription']['popup']['images']['close'] ??
      'assets/pack/noadsclose.png';

  double get subscriptionIconHeight =>
      (_config['subscription']['popup']['content']['iconHeight'] ?? 120)
          .toDouble();

  String get subscriptionTitleText =>
      _config['subscription']['popup']['content']['title']['text'] ?? 'NO ADS!';
  double get subscriptionTitleFontSize =>
      (_config['subscription']['popup']['content']['title']['fontSize'] ?? 45)
          .toDouble();
  Color get subscriptionTitleColor => _parseColor(_config['subscription']
          ['popup']['content']['title']['color'] ??
      '#FFC800');
  Color get subscriptionTitleShadowColor => _parseColor(_config['subscription']
          ['popup']['content']['title']['shadowColor'] ??
      '#00000073');
  double get subscriptionTitleShadowBlurRadius => (_config['subscription']
              ['popup']['content']['title']['shadowBlurRadius'] ??
          2)
      .toDouble();

  String get subscriptionSubtitleText =>
      _config['subscription']['popup']['content']['subtitle']['text'] ??
      'Enjoy an uninterrupted experience!';
  double get subscriptionSubtitleFontSize =>
      (_config['subscription']['popup']['content']['subtitle']['fontSize'] ??
              16)
          .toDouble();
  Color get subscriptionSubtitleColor => _parseColor(_config['subscription']
          ['popup']['content']['subtitle']['color'] ??
      '#5F3190');
  Color get subscriptionSubtitleShadowColor => _parseColor(
      _config['subscription']['popup']['content']['subtitle']['shadowColor'] ??
          '#00000073');
  double get subscriptionSubtitleShadowBlurRadius => (_config['subscription']
              ['popup']['content']['subtitle']['shadowBlurRadius'] ??
          1)
      .toDouble();

  String get subscriptionPriceText =>
      _config['subscription']['popup']['content']['price']['text'] ?? '\$5.99';
  double get subscriptionPriceFontSize =>
      (_config['subscription']['popup']['content']['price']['fontSize'] ?? 24)
          .toDouble();
  Color get subscriptionPriceColor => _parseColor(_config['subscription']
          ['popup']['content']['price']['color'] ??
      '#FFFFFF');
  Color get subscriptionPriceShadowColor => _parseColor(_config['subscription']
          ['popup']['content']['price']['shadowColor'] ??
      '#00000073');
  double get subscriptionPriceShadowBlurRadius => (_config['subscription']
              ['popup']['content']['price']['shadowBlurRadius'] ??
          5)
      .toDouble();

  double get subscriptionCloseButtonTop =>
      (_config['subscription']['popup']['closeButton']['top'] ?? -10)
          .toDouble();
  double get subscriptionCloseButtonRight =>
      (_config['subscription']['popup']['closeButton']['right'] ?? -10)
          .toDouble();
  double get subscriptionCloseButtonHeight =>
      (_config['subscription']['popup']['closeButton']['height'] ?? 40)
          .toDouble();

  // Subscription Popup Footer (Terms / Restore / Privacy)
  bool get subscriptionFooterEnabled =>
      _config['subscription']['popup']['footer']?['enabled'] ?? true;

  String get subscriptionTermsText =>
      _config['subscription']['popup']['footer']?['terms']?['text'] ??
      'Terms of Use';
  String get subscriptionTermsUrl =>
      _config['subscription']['popup']['footer']?['terms']?['url'] ?? '';

  String get subscriptionPrivacyText =>
      _config['subscription']['popup']['footer']?['privacy']?['text'] ??
      'Privacy Policy';
  String get subscriptionPrivacyUrl =>
      _config['subscription']['popup']['footer']?['privacy']?['url'] ?? '';

  String get subscriptionRestorePurchaseImage =>
      _config['subscription']['popup']['footer']?['restore']?['image'] ??
      'assets/pack/restore.png';
  double get subscriptionRestorePurchaseHeight =>
      (_config['subscription']['popup']['footer']?['restore']?['height'] ?? 28)
          .toDouble();

  double get subscriptionFooterTopPadding =>
      (_config['subscription']['popup']['footer']?['style']?['topPadding'] ??
              12)
          .toDouble();
  double get subscriptionFooterFontSize =>
      (_config['subscription']['popup']['footer']?['style']?['fontSize'] ?? 12)
          .toDouble();
  Color get subscriptionFooterLinkColor => _parseColor(
      _config['subscription']['popup']['footer']?['style']?['linkColor'] ??
          '#FFFFFF');
  double get subscriptionFooterItemSpacing =>
      (_config['subscription']['popup']['footer']?['style']?['itemSpacing'] ??
              12)
          .toDouble();

  // Subscription Product IDs
  List<String> get subscriptionTypes =>
      List<String>.from(_config['subscription']['types'] ?? ['monthly']);
  
  String getSubscriptionProductId(String type, String platform) {
    return _config['subscription']['productIds']?[platform]?[type] ?? '';
  }
  
  String get androidSubscriptionProductId =>
      _config['subscription']['productIds']['android'] ?? 'subscription_no_ads';
  String get iosSubscriptionProductId =>
      _config['subscription']['productIds']['ios'] ?? 'subscription_no_ads';

  // Theme
  Color get primaryColor =>
      _parseColor(_config['theme']['primaryColor'] ?? '#673AB7');
  Color get accentColor =>
      _parseColor(_config['theme']['accentColor'] ?? '#FFC107');
  Color get errorColor =>
      _parseColor(_config['theme']['errorColor'] ?? '#F44336');

  // Animation
  int get buttonPressDuration =>
      _config['animation']['buttonPressDuration'] ?? 150;
  int get pageTransitionDuration =>
      _config['animation']['pageTransitionDuration'] ?? 600;
  int get fadeTransitionDuration =>
      _config['animation']['fadeTransitionDuration'] ?? 300;
  double get scaleDownPlay =>
      (_config['animation']['scaleDownPlay'] ?? 0.9).toDouble();
  double get scaleDownButton =>
      (_config['animation']['scaleDownButton'] ?? 0.85).toDouble();

  // Helper to parse color from hex string
  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
