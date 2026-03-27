# Lantern Brand Kit

This package consolidates Lantern's reusable brand assets around the shipped app palette and icon language already present in the repository.

## Included

- Primary wordmark in SVG and PNG
- Forest, gold, white, and slate wordmark variants
- Auxiliary lantern monogram for compact UI, favicon, and documentation use
- App-icon exports from 1024 px down to 16 px
- Web favicon package (`favicon.ico`, PNG sizes, manifest, Safari pinned tab, browser config)
- Social cards and header images
- Brand tokens in JSON and CSS
- Source SVG masters for the monogram, wordmark, and app icon

## Primary Recommendation

Use `logos/lantern-wordmark-primary.svg` as the default brand mark for docs, repository banners, and product-adjacent UI.

## Reversed Usage

Use `logos/lantern-wordmark-white.svg` on dark forest or charcoal backgrounds.

## Favicon / App Icon

Use the square icon exports in `icons/` and `favicon/` for launcher, browser, and manifest use. Use the monogram files when you need a transparent compact mark.

## Color System

- Lantern Gold: `#C49020`
- Lantern Gold Bright: `#E0B038`
- Lantern Ember: `#C2581A`
- Lantern Ember Bright: `#E07633`
- Canopy Green: `#214C40`
- Pine Green: `#173329`
- Forest Night: `#0E221C`
- Lantern Slate: `#343038`
- Warm Surface: `#FDF4E8`
- Paper Glow: `#FFF9E8`

## Typography

- Display / wordmark stack: `Avenir Next`, `Avenir`, `Helvetica Neue`, `Helvetica`, `sans-serif`
- UI/system stack: `SF Pro Display`, `Avenir Next`, `system-ui`, `sans-serif`

The SVG wordmark masters use the local macOS font stack above. The PNG exports are the safest handoff assets when appearance must stay exact across environments.

## Standard File Map

### `logos/`

- `lantern-wordmark-primary.svg/png`
- `lantern-wordmark-forest.svg/png`
- `lantern-wordmark-gold.svg/png`
- `lantern-wordmark-white.svg/png`
- `lantern-wordmark-slate.svg/png`

### `previews/`

- `lantern-wordmark-on-forest-night.png`
- `lantern-wordmark-on-warm-surface.png`
- `lantern-wordmark-gold-on-night.png`
- `lantern-wordmark-white-on-forest.png`

### `icons/`

- `lantern-monogram-gold.svg/png`
- `lantern-monogram-white.svg/png`
- `lantern-monogram-forest.svg/png`
- `lantern-monogram-slate.svg/png`
- `lantern-monogram-gold-transparent.png`
- `lantern-app-icon-1024.png`
- `lantern-icon-{16,32,48,64,128,152,167,180,192,256,512,1024}.png`

### `favicon/`

- `favicon.ico`
- `favicon-16x16.png`
- `favicon-32x32.png`
- `apple-touch-icon.png`
- `android-chrome-192x192.png`
- `android-chrome-512x512.png`
- `icon-{16,32,48,64,180,192,256,512,1024}.png`
- `safari-pinned-tab.svg`
- `site.webmanifest`
- `browserconfig.xml`

### `social/`

- `lantern-social-card-dark.png`
- `lantern-social-card-light.png`
- `lantern-header-dark.png`
- `lantern-header-light.png`

### `tokens/`

- `lantern-brand-tokens.json`
- `lantern-brand-tokens.css`

### `source/`

- `lantern-monogram-master.svg`
- `lantern-wordmark-master.svg`
- `lantern-app-icon-master.svg`
- `original-notes.md`

