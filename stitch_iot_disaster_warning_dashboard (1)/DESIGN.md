---
name: Firmus Tactical Light
colors:
  surface: '#FFFFFF'
  surface-dim: '#d8dadc'
  surface-bright: '#f7f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f6'
  surface-container: '#eceef0'
  surface-container-high: '#e6e8ea'
  surface-container-highest: '#e0e3e5'
  on-surface: '#191c1e'
  on-surface-variant: '#3e484f'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f3'
  outline: '#6e7980'
  outline-variant: '#bdc8d1'
  surface-tint: '#00668a'
  primary: '#00668a'
  on-primary: '#ffffff'
  primary-container: '#38bdf8'
  on-primary-container: '#004965'
  inverse-primary: '#7bd0ff'
  secondary: '#505f76'
  on-secondary: '#ffffff'
  secondary-container: '#d0e1fb'
  on-secondary-container: '#54647a'
  tertiary: '#855300'
  on-tertiary: '#ffffff'
  tertiary-container: '#f1a02b'
  on-tertiary-container: '#613b00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#c4e7ff'
  primary-fixed-dim: '#7bd0ff'
  on-primary-fixed: '#001e2c'
  on-primary-fixed-variant: '#004c69'
  secondary-fixed: '#d3e4fe'
  secondary-fixed-dim: '#b7c8e1'
  on-secondary-fixed: '#0b1c30'
  on-secondary-fixed-variant: '#38485d'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb960'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#f7f9fb'
  on-background: '#191c1e'
  surface-variant: '#e0e3e5'
  border: '#E2E8F0'
  text-main: '#0F172A'
  status-aman: '#10B981'
  status-waspada: '#F59E0B'
  status-siaga: '#F97316'
  status-awas: '#EF4444'
typography:
  headline-lg:
    fontFamily: manrope
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: manrope
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: manrope
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: manrope
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  data-display:
    fontFamily: jetbrainsMono
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 24px
    letterSpacing: 0.02em
  data-label:
    fontFamily: jetbrainsMono
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.05em
  headline-lg-mobile:
    fontFamily: manrope
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 30px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 32px
  card-padding: 16px
  component-gap: 8px
---

## Brand & Style

This design system is a high-performance adaptation of a tactical monitoring interface, reimagined for high-visibility environments and daylight operations. It maintains its "Mission Control" DNA—precision, urgency, and technical rigor—but shifts from a cinematic dark aesthetic to a clean, clinical, and professional **Tactical Modernism** in light mode.

The visual narrative focuses on **Information Clarity** and **Instrumental Precision**. By utilizing a bright, neutral foundation, the UI reduces visual fatigue in well-lit environments while ensuring that critical status indicators remain the most vibrant elements on the screen. 

Key visual pillars include:
- **Clinical Utility:** A "Slate" and "White" palette that feels like high-end laboratory or aerospace equipment.
- **Structured Density:** Heavy reliance on 1px borders and monospaced accents to organize complex telemetry without visual clutter.
- **Vibrant Criticality:** Status colors are high-chroma to ensure that alerts "pop" against the sterile background, maintaining the system's reactive nature.

## Colors

The color strategy transitions from "Deep Command Navy" to "Alpine Slate," prioritizing legibility and structural separation.

- **Foundational Layers:** The base background uses `#F8FAFC` (Slate 50) to provide a soft, non-reflective canvas. Surface elements and cards use pure `#FFFFFF` to create distinct elevation through value rather than shadow.
- **Typography & Borders:** Primary text is set in `#0F172A` (Slate 900) for maximum contrast. Secondary metadata uses `#64748B` (Slate 500). Borders are strictly `#E2E8F0` (Slate 200), acting as the primary method of structural containment.
- **Tactical Accents:** `#38BDF8` remains the interactive anchor. 
- **Preserved Statuses:** The four-tier alert system (Aman, Waspada, Siaga, Awas) retains its original high-saturation values. In this light environment, these colors are used in chips, icon fills, and "active-state" borders to signal environmental health.

## Typography

The typographic system relies on a dual-personality approach to separate interface narrative from raw telemetry.

- **Structural UI (Manrope):** All headings, navigation elements, and body descriptions use Manrope. It provides a contemporary, geometric feel that remains readable at high densities.
- **Telemetry & Data (JetBrains Mono):** This monospaced face is mandatory for all numerical sensor outputs, coordinates, timestamps, and data labels. It ensures tabular alignment in dashboard views and reinforces the tactical, technical nature of the software.
- **Hierarchy:** Use `data-label` in all-caps with the specified letter spacing for metadata headers to maximize the "instrumentation" aesthetic.

## Layout & Spacing

This design system employs a **12-column fluid grid** for desktop and a **4-column grid** for mobile. 

- **The 4px Baseline:** All spacing, margins, and component heights must be multiples of 4px. Standard internal card padding is 16px (4 units).
- **Tactical Grid Overlay:** For map-heavy views, a subtle 1px grid or dot-matrix pattern can be applied to the background at 3% opacity to assist with spatial orientation.
- **Reflow Rules:** On mobile, complex data tables should collapse into "Telemetry Cards," where JetBrains Mono labels are stacked vertically to maintain legibility.

## Elevation & Depth

Unlike consumer light-mode designs, this system avoids soft, large-radius shadows. Depth is communicated through **Low-Contrast Outlines** and **Surface Tiering**.

- **Level 0 (Base):** Slate 50 (`#F8FAFC`). Used for the main application background.
- **Level 1 (Surface):** White (`#FFFFFF`). Used for cards, sidebars, and panels. These must have a 1px solid border (`#E2E8F0`).
- **Level 2 (Overlay):** White (`#FFFFFF`) with a very tight, low-opacity shadow (`0px 2px 4px rgba(15, 23, 42, 0.05)`) and a 1px border. Used for dropdowns and popovers.
- **Tactical Indicator:** Instead of elevation shadows, "Active" or "Critical" states are indicated by changing the 1px border color to the Primary or Status color (e.g., a 1px "Awas" red border for a failing sensor).

## Shapes

The shape language reflects an "Industrial Hardware" feel—rugged yet refined.

- **Containers:** Large panels and telemetry cards use `rounded-xl` (1.5rem) to soften the high-density layout.
- **Interactive Elements:** Buttons, inputs, and chips use `rounded-lg` (1.0rem) to provide a clear, touch-friendly target.
- **Precision Components:** Checkboxes and small utility icons use a sharper `rounded-sm` (0.25rem) to maintain a technical edge.

## Components

- **Buttons:** 
    - **Primary:** Solid `#38BDF8` with white text. 
    - **Secondary:** White background with `#E2E8F0` border and `#0F172A` text.
- **Telemetry Cards:** Must use `#FFFFFF` background and `#E2E8F0` border. The top section should house the `data-label` (Mono) and the main body should feature the `data-display` (Mono) for the primary metric.
- **Status Chips:** Small pills using a light tinted background of the status color (e.g., 10% opacity) with a solid 1px border and text in the full-saturation status color.
- **Input Fields:** `#FFFFFF` background with a 1px `#E2E8F0` border. On focus, the border shifts to Primary `#38BDF8` with no glow, maintaining a crisp, flat aesthetic.
- **Data Tables:** Use alternating row stripes (Slate 50) and a header row with a 2px bottom border in Slate 200. All numerical data must be right-aligned in JetBrains Mono.
- **Map Overlays:** White panels with 90% opacity and a 16px backdrop blur to maintain the visual link to the underlying data.