import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  final BannerAd bannerAd;

  const BannerAdWidget({super.key, required this.bannerAd});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> with AutomaticKeepAliveClientMixin {
  Widget? _adWidget;
  BannerAd? _currentBannerAd;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _createAdWidget();
  }

  void _createAdWidget() {
    if (_currentBannerAd != widget.bannerAd) {
      _currentBannerAd = widget.bannerAd;
      _adWidget = null;
      // Use post frame callback to create widget in next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _adWidget = AdWidget(ad: widget.bannerAd);
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(BannerAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bannerAd != widget.bannerAd) {
      _createAdWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    if (_adWidget == null) {
      return Container(
        width: widget.bannerAd.size.width.toDouble(),
        height: widget.bannerAd.size.height.toDouble(),
        color: Colors.transparent,
      );
    }
    
    return SizedBox(
      width: widget.bannerAd.size.width.toDouble(),
      height: widget.bannerAd.size.height.toDouble(),
      child: _adWidget,
    );
  }
}
