# AdMob Integration Documentation

## Overview
This app implements Google AdMob ads with banner and interstitial ad formats across multiple screens. All AdMob settings are configured through the `config.json` file.

## Configuration

### config.json Settings
The AdMob configuration is located in `assets/config.json`:

```json
{
  "admob": {
    "enabled": true,
    "testMode": true,
    "android": {
      "appId": "ca-app-pub-3940256099942544~3347511713",
      "bannerAdUnitId": "ca-app-pub-3940256099942544/6300978111",
      "interstitialAdUnitId": "ca-app-pub-3940256099942544/1033173712"
    },
    "ios": {
      "appId": "ca-app-pub-3940256099942544~1458002511",
      "bannerAdUnitId": "ca-app-pub-3940256099942544/2934735716",
      "interstitialAdUnitId": "ca-app-pub-3940256099942544/4411468910"
    }
  }
}
```

### Configuration Parameters
- `enabled`: Set to `true` to enable ads, `false` to disable
- `testMode`: Currently set to `true` (using Google test ad IDs)
- `android.appId`: Android AdMob App ID
- `android.bannerAdUnitId`: Android banner ad unit ID
- `android.interstitialAdUnitId`: Android interstitial ad unit ID
- `ios.appId`: iOS AdMob App ID
- `ios.bannerAdUnitId`: iOS banner ad unit ID
- `ios.interstitialAdUnitId`: iOS interstitial ad unit ID

## Ad Implementation by Screen

### 1. Home Screen
- **Banner Ad**: Displayed at the bottom of the screen
- **Interstitial Ad**: None

### 2. Gender Selection Screen
- **Banner Ad**: Displayed at the bottom of the screen
- **Interstitial Ad**: Shows once when user selects boy or girl (only on first selection)

### 3. User Info Screen
- **Banner Ad**: Displayed at the bottom of the screen
- **Interstitial Ad**: Shows once when the continue button appears (when form is valid)

### 4. Difficulty Screen
- **Banner Ad**: Displayed at the bottom of the screen
- **Interstitial Ad**: Shows when user closes the subscription popup

## Using Real Ad Units

### Step 1: Create AdMob Account
1. Go to https://admob.google.com
2. Sign up or log in with your Google account
3. Create a new app for Android and iOS

### Step 2: Get Your Ad Unit IDs
1. In AdMob console, create ad units for:
   - Banner Ad (Android)
   - Banner Ad (iOS)
   - Interstitial Ad (Android)
   - Interstitial Ad (iOS)
2. Copy the Ad Unit IDs

### Step 3: Update config.json
Replace the test IDs in `assets/config.json` with your real ad unit IDs:

```json
{
  "admob": {
    "enabled": true,
    "testMode": false,
    "android": {
      "appId": "ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX",
      "bannerAdUnitId": "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX",
      "interstitialAdUnitId": "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
    },
    "ios": {
      "appId": "ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX",
      "bannerAdUnitId": "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX",
      "interstitialAdUnitId": "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
    }
  }
}
```

### Step 4: Update Platform Files

#### Android (android/app/src/main/AndroidManifest.xml)
Replace the test App ID:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

#### iOS (ios/Runner/Info.plist)
Replace the test App ID:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

## Testing Ads

### Test Mode (Current Configuration)
The app is currently configured with Google's official test ad unit IDs. These will show test ads that you can safely click without violating AdMob policies.

### Important Notes
- **Never click on real ads during testing** - This can get your AdMob account banned
- Always use test IDs during development
- Only switch to real ad IDs when publishing to production
- Test on real devices for accurate ad behavior

## AdMob Service

The `AdMobService` class (`lib/services/admob_service.dart`) handles:
- Ad initialization
- Banner ad creation
- Interstitial ad loading and showing
- Platform-specific ad unit ID selection

## Troubleshooting

### Ads Not Showing
1. Check that `admob.enabled` is `true` in config.json
2. Verify internet connection
3. Check that Ad Unit IDs are correct
4. Review console logs for error messages

### Ads Showing Blank/White
- This is normal for test ads sometimes
- Real ads may take time to fill
- Check AdMob dashboard for ad fill rate

### Build Errors
- Run `flutter pub get` to ensure google_mobile_ads package is installed
- Verify AndroidManifest.xml and Info.plist have correct App IDs
- Clean and rebuild: `flutter clean && flutter pub get`

## Revenue Optimization Tips
1. Don't show too many ads - it can hurt user experience
2. Strategic placement matters - bottom banners are less intrusive
3. Interstitial ads should appear at natural breaks (after selections, screen transitions)
4. Monitor your AdMob dashboard for performance metrics
5. A/B test different ad placements and frequencies
