# Product Specification — All-in-One Calculator v1

## Product goal
Create a fast, clean, trustworthy utility app that handles common calculations without forcing sign-in or collecting personal data.

## Navigation
1. Calculator
2. Finance
3. Convert
4. Tools

## Monetization-ready architecture
The v1 build is intentionally free of ad/analytics dependencies. A later monetization release can add:
- unobtrusive banner/interstitial placements only where they do not interrupt core calculation;
- optional one-time Pro unlock for an ad-free experience and advanced tools;
- platform-compliant purchase handling.

No purchase UI is shipped until real product IDs and store configuration exist.

## Privacy principles
- Process calculations locally.
- Avoid account creation.
- Avoid network access unless a future feature truly needs it.
- Request no sensitive permissions in v1.
- Explain any future third-party SDK data collection before release.

## QA checklist
- Basic arithmetic and divide-by-zero
- Decimal input and negative values
- Finance formula edge cases
- Date picker boundaries
- Converter category switching
- Light/dark/system theme
- Rotation and large-screen layout
- Accessibility text scaling
- Android back navigation
- iOS navigation and safe areas
