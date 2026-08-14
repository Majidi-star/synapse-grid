---
name: Ethereal Study
colors:
  surface: '#15130f'
  surface-dim: '#15130f'
  surface-bright: '#3b3934'
  surface-container-lowest: '#0f0e0a'
  surface-container-low: '#1d1c17'
  surface-container: '#21201b'
  surface-container-high: '#2c2a25'
  surface-container-highest: '#36352f'
  on-surface: '#e7e2da'
  on-surface-variant: '#cfc5b3'
  inverse-surface: '#e7e2da'
  inverse-on-surface: '#32302b'
  outline: '#98907f'
  outline-variant: '#4c4638'
  surface-tint: '#e3c36c'
  primary: '#ffdf8c'
  on-primary: '#3d2f00'
  primary-container: '#e3c36c'
  on-primary-container: '#664f00'
  inverse-primary: '#735b0c'
  secondary: '#cac6bd'
  on-secondary: '#32302a'
  secondary-container: '#484740'
  on-secondary-container: '#b8b5ac'
  tertiary: '#dde0ff'
  on-tertiary: '#222c5f'
  tertiary-container: '#b9c3ff'
  on-tertiary-container: '#454f83'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffe08d'
  primary-fixed-dim: '#e3c36c'
  on-primary-fixed: '#241a00'
  on-primary-fixed-variant: '#584400'
  secondary-fixed: '#e6e2d9'
  secondary-fixed-dim: '#cac6bd'
  on-secondary-fixed: '#1c1c16'
  on-secondary-fixed-variant: '#484740'
  tertiary-fixed: '#dee1ff'
  tertiary-fixed-dim: '#b9c3ff'
  on-tertiary-fixed: '#0a1649'
  on-tertiary-fixed-variant: '#394377'
  background: '#15130f'
  on-background: '#e7e2da'
  surface-variant: '#36352f'
typography:
  display-lg:
    fontFamily: Manrope
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Manrope
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Manrope
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  margin-page: 24px
  gutter-inline: 16px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
  card-padding: 40px
---

## Brand & Style

This design system is built on a philosophy of **Focus-Oriented Minimalism**. Designed for a mobile-first flashcard experience, it prioritizes cognitive ease by stripping away traditional UI chrome and focusing entirely on the relationship between the learner and the content. 

The aesthetic blends **Modern Minimalism** with a **Tactile** warmth. By utilizing a deep, earthy dark mode palette, the system reduces eye strain during long study sessions. The visual narrative is one of quiet sophistication, evoking the feeling of premium stationery or a private library. High-quality whitespace is used not just as a separator, but as a functional tool to frame information and prevent mental fatigue.

## Colors

The palette is anchored by a sophisticated contrast between deep obsidian tones and a warm, metallic gold.

*   **Primary (#e3c36c):** Used for the active flashcard surface and high-priority actions. It acts as the "illuminated" element in the dark environment.
*   **On-Surface (#e6e1d9):** An off-white, low-glare tint used for all primary text to ensure high legibility without the harshness of pure white.
*   **Surface-Container (#2a2923):** A subtle elevation color used for secondary inputs, list items, or navigation bars to distinguish them from the deep background.
*   **Background (#1c1b16):** The base canvas, providing a rich, immersive environment that makes the primary gold elements pop.

## Typography

The typography system utilizes **Manrope** for its modern, balanced proportions that maintain high legibility at both large display sizes and small body scales. For technical or meta-information, **Geist** provides a clean, monospaced-adjacent aesthetic that adds a layer of precision to labels and progress indicators.

*   **Flashcard Content:** Use `headline-md` for the primary word or question on the card face.
*   **Information Hierarchy:** `label-md` is reserved for category headers or status tags (e.g., "LEARNING", "MASTERED") to create a distinct visual texture compared to body text.
*   **Scaling:** On smaller mobile devices, `display-lg` should scale down to 36px to ensure long words do not break awkwardly.

## Layout & Spacing

This design system uses a **Fluid Mobile Grid** with generous safe areas. 

*   **Margins:** A fixed 24px horizontal margin ensures content feels centered and "held" by the screen.
*   **Card Layout:** The central flashcard should utilize a vertical stack with `card-padding` to ensure text never crowds the edges.
*   **Rhythm:** Vertical spacing follows an 8px base unit. Use `stack-lg` to separate distinct functional groups (e.g., the flashcard from the control buttons) and `stack-sm` for related text elements.
*   **Touch Targets:** All interactive elements maintain a minimum 48x48px hit area, even if the visual representation is smaller.

## Elevation & Depth

In this system, depth is communicated through **Tonal Layering** and **Soft Ambient Shadows** rather than aggressive highlights.

*   **The Flashcard:** As the focal point, the flashcard uses the Primary color (#e3c36c) and sits on the highest elevation. It features a soft, diffused shadow with a 15% opacity of the background color to create a slight lift.
*   **Surface Tiers:** Secondary elements like menu drawers or "Add Card" sheets use the `#2a2923` surface color. 
*   **Interaction:** When a button is pressed, it should "depress" visually by removing its shadow and slightly reducing its scale (98%), creating a tactile, physical response.

## Shapes

The shape language is consistently **Rounded**. This softens the high-contrast color palette and makes the app feel more approachable and modern.

*   **Flashcards:** Use `rounded-xl` (1.5rem / 24px) to emphasize the card as a distinct, physical-like object.
*   **Buttons & Inputs:** Use standard `rounded` (0.5rem / 8px) for a crisp but friendly appearance.
*   **Progress Bars:** Should be fully pill-shaped (rounded-full) to represent the fluid nature of learning progress.

## Components

### Flashcards
The centerpiece of the UI. The "Front" should be Primary (#e3c36c) with Dark Text (#1c1b16). The "Back" can invert this (Dark Surface with Primary Text) to provide a clear visual state change when flipped.

### Buttons
*   **Primary Button:** Solid Primary (#e3c36c) with Dark Text. Heavy 24px vertical padding for a "squishy" tactile feel.
*   **Ghost Button:** Transparent background with an On-Surface (#e6e1d9) border. Used for "Skip" or "Edit" actions.

### Chips / Status Tags
Small, pill-shaped elements using the `Surface-Container` color. Use `label-sm` for the text to provide metadata like "Deck: Anatomy" or "Interval: 4 Days."

### Inputs
Text fields should be minimal: a simple bottom border or a subtle `Surface-Container` fill with no stroke. Focus states are indicated by the border changing to the Primary (#e3c36c) color.

### Progress Indicators
A horizontal bar at the top of the study session. The track should be `#2a2923` and the progress fill should be the Primary (#e3c36c) color, using a smooth spring animation during transitions.