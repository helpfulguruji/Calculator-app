# Branding & Store Assets — v1.5.2

The project includes the generated visual brand board and separated starter assets under `assets/brand_assets/`.

## Brand direction
- Distinct calculator mark: four colorful operation tiles inside a rounded-square frame.
- Primary visual language: deep navy/blue foundation with cyan/green/purple/orange accents.
- Tagline: **Smart • Fast • Complete**.
- Light and dark splash concepts are included in the visual board.

## Included assets
- `app_icon_1024.png` — master icon artwork.
- `adaptive_icon_1024.png` — Android adaptive-icon source artwork.
- `splash_dark_1290x2796.png` — dark splash concept/source.
- `hero_store_graphic.png` — promotional hero artwork.
- `feature_graphic.png` — feature graphic concept.
- `store_asset_board.png` — complete visual reference board.

## Store screenshot set
The visual board contains the following designed screen concepts:
1. Home / dashboard
2. Basic calculator
3. Scientific calculator
4. EMI calculator
5. Unit converter
6. History
7. Favorites
8. Settings & theme
9. Share result

Before submission, export each final screenshot at the exact store-required dimensions from the real app running on target devices. Do not use the concept board as a substitute for real-app screenshots.

## Icon implementation
After running `flutter create .`, wire the master/adaptive artwork into Android launcher resources and the iOS AppIcon asset catalog. Keep safe margins around the mark and verify masking on multiple Android icon shapes.

## Splash implementation
Use the supplied artwork as the visual source, but implement the actual splash using the platform-native launch/splash mechanism. Verify cold start, warm start, dark mode, and accessibility/reduced-motion behavior.
