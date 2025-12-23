# Configuration System Documentation

## Overview
The template now uses a centralized configuration system that allows you to control all static values, images, colors, screen visibility, and game URL from a single `config.json` file located in `assets/config.json`.

## Configuration File Location
```
/assets/config.json
```

## Key Features

### 1. **Game Configuration**
Control the game webview screen:
```json
"game": {
  "enabled": true,
  "url": "https://example.com/game",
  "continueButtonImage": "assets/pack/continue.png"
}
```

### 2. **Screen Visibility Control**
You can enable/disable entire screens:
```json
"screens": {
  "home": { "enabled": true },
  "genderSelection": { "enabled": true },
  "userInfo": { "enabled": true },
  "difficulty": { "enabled": true },
  "moreGames": { "enabled": true },
  "splash": { "enabled": true }
}
```

### 2. **Home Screen Button Control**
Control visibility of share, more games, and rate buttons:
```json
"home": {
  "buttons": {
    "share": { "enabled": true },
    "moreGames": { "enabled": true },
    "rate": { "enabled": true }
  }
}
```

### 3. **Image Assets**
All image paths are configurable:
```json
"images": {
  "background": "assets/pack/bg.png",
  "header": "assets/pack/header.png",
  "play": "assets/pack/play.png"
}
```

### 4. **Text Content**
All display text is configurable:
```json
"content": {
  "title": {
    "text": "NO ADS!",
    "fontSize": 45,
    "fontWeight": "bold",
    "color": "#FFC800"
  }
}
```

### 5. **Colors**
Colors use hex format with alpha channel support:
```json
"color": "#FFC800",           // RGB
"shadowColor": "#00000073"    // RGBA (with transparency)
```

### 6. **Validation Messages**
All form validation messages:
```json
"validation": {
  "messages": {
    "nameEmpty": "Please enter your name",
    "emailInvalid": "Please enter a valid email address"
  }
}
```

### 7. **More Games Grid**
Configure game images and grid layout:
```json
"moreGames": {
  "grid": {
    "columns": 3,
    "crossSpacing": 25,
    "mainSpacing": 25,
    "aspectRatio": 1.6
  },
  "gameImages": [
    "https://url1.com/game1.jpg",
    "https://url2.com/game2.jpg"
  ]
}
```

### 8. **Subscription Popup**
Full control over subscription popup:
```json
"subscription": {
  "enabled": true,
  "popup": {
    "barrierDismissible": false,
    "width": 300,
    "height": 400,
    "content": {
      "title": {
        "text": "NO ADS!",
        "fontSize": 45,
        "color": "#FFC800"
      },
      "price": {
        "text": "$5.99"
      }
    }
  }
}
```

### 9. **Animation Settings**
Configure animation timings:
```json
"animation": {
  "buttonPressDuration": 150,
  "pageTransitionDuration": 600,
  "scaleDownPlay": 0.9,
  "scaleDownButton": 0.85
}
```

## Usage in Code

### Accessing Configuration
```dart
import '../services/app_config.dart';

// Get config instance
final config = await AppConfig.getInstance();

// Use config values
Image.asset(config.homeBackgroundImage);
Text(config.subscriptionTitleText);
Color color = config.primaryColor;
```

### Example: Conditional Button Display
```dart
if (config.homeShareButtonEnabled) {
  _buildBottomButton(
    config.homeShareButtonImage,
    config.homeShareButtonLabel,
    () {},
    _shareButtonController,
  ),
}
```

## Dashboard Integration

Your dashboard can:
1. Read the current `config.json`
2. Modify any values
3. Save the updated `config.json`
4. The app will use new values on next launch

### Example Dashboard Update Flow:
```javascript
// Dashboard code example
const config = await fetch('config.json').then(r => r.json());

// Update values
config.subscription.popup.content.price.text = "$9.99";
config.screens.home.buttons.share.enabled = false;

// Save back to file
await saveConfig(config);
```

## Available Config Properties

### App Settings
- `enableSplashScreen` - Show/hide splash screen
- `loadingProgressSpeed` - Loading animation speed
- `loadingProgressIncrement` - Progress bar increment

### Screen Controls
- `isScreenEnabled(screenName)` - Check if screen is enabled
- Home buttons: `homeShareButtonEnabled`, `homeMoreGamesButtonEnabled`, `homeRateButtonEnabled`

### Images (all screens)
- Background images
- Button images
- Icon images
- Header images

### Text & Styling
- Font sizes
- Font weights
- Colors (hex format)
- Shadow properties

### Layout
- Spacing values
- Grid configurations
- Border radius
- Opacity values

### Validation
- Field max lengths
- Error messages
- Validation rules

## Complete Configuration Structure

See `assets/config.json` for the complete structure with all available options.

## Notes

- All changes require app restart to take effect
- Colors support hex format (#RGB, #RRGGBB, #AARRGGBB)
- Image paths must point to valid assets
- Boolean values control feature visibility
- Numeric values control sizing and timing
- String values control display text

## Future Enhancements

The config system can be extended to include:
- Remote config fetching
- A/B testing parameters
- Localization strings
- Analytics settings
- Ad placement configurations
