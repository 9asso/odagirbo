import 'package:flutter/material.dart';
import '../services/app_config.dart';

class MoreGamesScreen extends StatefulWidget {
  const MoreGamesScreen({super.key});

  @override
  State<MoreGamesScreen> createState() => _MoreGamesScreenState();
}

class _MoreGamesScreenState extends State<MoreGamesScreen>
    with TickerProviderStateMixin {
  late AnimationController _backButtonController;
  late AppConfig _config;
  bool _configLoaded = false;
  List<String> gameImages = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _backButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  Future<void> _loadConfig() async {
    _config = await AppConfig.getInstance();
    setState(() {
      _configLoaded = true;
      gameImages = _config.moreGamesGameImages;
    });
  }

  @override
  void dispose() {
    _backButtonController.dispose();
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
              _config.moreGamesBackgroundImage,
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Header Image at top
                  Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: SizedBox(
                      height: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          _config.moreGamesHeaderImage,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                _config.moreGamesFallbackTitle,
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

                  // const SizedBox(height: 20),

                  // Scrollable Grid View
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20, left: 0, right: 0, bottom: 0),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _config.moreGamesGridColumns,
                          crossAxisSpacing: _config.moreGamesGridCrossSpacing,
                          mainAxisSpacing: _config.moreGamesGridMainSpacing,
                          childAspectRatio: _config.moreGamesGridAspectRatio,
                        ),
                        itemCount: gameImages.length,
                        itemBuilder: (context, index) {
                          return _buildGameCard(gameImages[index], index);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Back button at top left
            Positioned(
              top: 20,
              left: 20,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: _config.scaleDownPlay).animate(
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
                        _config.moreGamesCloseImage,
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
            ],
          ),
        ),
      );
  }

  Widget _buildGameCard(String imageUrl, int index) {
    return GestureDetector(
      onTap: () {
        // Handle game card tap - can open game or show details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Game ${index + 1} clicked'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_config.moreGamesGridBorderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              
              // Frame overlay
              Image.asset(
                _config.moreGamesFrameImage,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
              
              
              // Game Image
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 10, top: 9, bottom: 18),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(33),
                    topRight: Radius.circular(32),
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                ' ${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
