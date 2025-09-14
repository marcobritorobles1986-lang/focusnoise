FocusNoise – Pack de iconos
===========================
Archivos incluidos:
- app-icon-foreground-1024.png  (PNG, fondo transparente)  -> usar como adaptive_icon_foreground
- app-icon-foreground-512.png   (PNG, fondo transparente)
- app-icon-foreground-432.png   (PNG, fondo transparente)
- app-icon-1024-white.png       (PNG, fondo blanco)        -> usar como image_path (iOS/fallback)
- play-store-icon-512.png       (PNG, fondo blanco)        -> Play Store asset
- app-icon-monochrome-432.png   (PNG, negro sobre transparente) -> adaptive_icon_monochrome (Android 13)
- focusnoise-mark-1024.png      (PNG, transparente)        -> marca/foreground
- ic_notification_white_96.png  (PNG, blanco sobre transparente) -> ícono notificación

Sugerencias de pubspec.yaml:
----------------------------
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/brand/app-icon-1024-white.png"
  adaptive_icon_foreground: "assets/brand/focusnoise-mark-1024.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_monochrome: "assets/brand/app-icon-monochrome-432.png"
  remove_alpha_ios: true
  min_sdk_android: 21

flutter:
  assets:
    - assets/brand/app-icon-1024-white.png
    - assets/brand/focusnoise-mark-1024.png
    - assets/brand/app-icon-monochrome-432.png
    - assets/brand/play-store-icon-512.png
    - assets/brand/app-icon-foreground-1024.png
    - assets/brand/app-icon-foreground-512.png
    - assets/brand/app-icon-foreground-432.png
    - assets/brand/ic_notification_white_96.png