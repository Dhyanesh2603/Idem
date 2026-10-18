# Design System & Theme: Obsidian Slate

The design philosophy behind Obsidian Slate is rooted in calm, focused, intentional computing. Modern productivity software often bombards users with high-saturation accent cards, neon progress gradients, and overwhelming visual dashboards. Obsidian Slate strips away the artificial noise so that the user's actual tasks and thoughts emerge front and center.

---

## 1. Core Principles

- **Reduced Cognitive Load**: No neon gradients, no glassmorphism, no neumorphism, and no gratuitous drop shadows.
- **Hierarchy Through Typography & Whitespace**: Instead of using high-contrast colored cards to differentiate content, Obsidian Slate uses subtle variations in font weight, size, letter spacing, and intentional whitespace.
- **Monochrome Foundation**: The application layout, surfaces, typography, and borders remain strictly neutral. Accent colors are reserved strictly for interactive state feedback.
- **Subtle, Purposeful Motion**: Animations are bounded strictly between 150ms and 250ms with standard cubic easing. Motion is used solely to communicate state transitions (e.g., checking off a task, modal entry), never for visual flair.

---

## 2. Color Palettes

### Dark Theme (Default)
Tuned specifically for prolonged focus sessions without eye fatigue.

| Token | Hex | Role |
| :--- | :--- | :--- |
| `darkBackground` | `#0F1115` | App scaffold and base canvas |
| `darkSurface` | `#171A21` | Panels, task containers, modal surfaces |
| `darkSecondarySurface`| `#20242C` | Subtle row hovers, tooltips, nested containers |
| `darkBorder` | `#2B313C` | Clean structural boundary lines |
| `darkPrimaryText` | `#F5F5F5` | High-readability content headers and task titles |
| `darkSecondaryText` | `#A1A8B3` | Metadata, task descriptions, subtext |
| `darkMutedText` | `#6B7280` | Timestamps, microcopy, placeholder text |
| `darkDivider` | `#323845` | Structural dividers and separators |

### Light Theme (Warm Paper)
Instead of harsh clinical `#FFFFFF` backgrounds that cause glare, Light Theme uses organic warm paper tones.

| Token | Hex | Role |
| :--- | :--- | :--- |
| `lightBackground` | `#F7F5F0` | Warm paper base canvas |
| `lightSurface` | `#EEEAE1` | Elevated surfaces and lists |
| `lightSecondarySurface`| `#E2DDD2` | Card hovers and nested structures |
| `lightBorder` | `#D1CBBD` | Soft borders |
| `lightPrimaryText` | `#15181E` | Deep charcoal primary typography |
| `lightSecondaryText` | `#525866` | Mid-gray descriptive copy |
| `lightMutedText` | `#7D8491` | Low-emphasis metadata |
| `lightDivider` | `#DDD8CB` | Subtle hairline dividers |

---

## 3. Accent Packs

Users can select their personal accent personality. Crucially, the accent pack **only** touches interactive and active state elements:
- Checkbox fills
- Radio selections
- Active navigation rail / bar indicators
- Action buttons
- Active input focus rings
- Progress indicators and inline text links

All background surfaces, text, cards, and borders remain strictly neutral monochrome.

| Accent Pack | Dark Hex | Light Hex | Personality |
| :--- | :--- | :--- | :--- |
| **Forest** | `#34D399` | `#059669` | Calm pine and eucalyptus green |
| **Ocean** | `#60A5FA` | `#2563EB` | Deep nautical azure |
| **Amber** | `#FBBF24` | `#D97706` | Warm roasted honey |
| **Burgundy** | `#FB7185` | `#BE123C` | Refined ruby and wine |
| **Lavender** | `#A78BFA` | `#7C3AED` | Twilight lilac |
| **Slate** | `#94A3B8` | `#475569` | Understated mineral zinc |
| **Monochrome** | `#F5F5F5` | `#18181B` | High contrast minimalist |

---

## 4. Typography Hierarchy

- **Primary Font**: Geist (with Inter fallback)
- **Code/Mono**: JetBrains Mono

| Level | Size | Weight | Line Height | Letter Spacing |
| :--- | :--- | :--- | :--- | :--- |
| `displayLarge` | 32sp | 600 (SemiBold) | 1.25 | -0.8 |
| `displayMedium` | 26sp | 600 (SemiBold) | 1.30 | -0.6 |
| `titleLarge` | 20sp | 600 (SemiBold) | 1.35 | -0.4 |
| `titleMedium` | 16sp | 500 (Medium) | 1.40 | -0.2 |
| `titleSmall` | 14sp | 500 (Medium) | 1.40 | -0.1 |
| `bodyLarge` | 15sp | 400 (Regular) | 1.50 | -0.1 |
| `bodyMedium` | 14sp | 400 (Regular) | 1.50 | 0.0 |
| `bodySmall` | 12sp | 400 (Regular) | 1.45 | 0.0 |
| `labelLarge` | 13sp | 500 (Medium) | 1.30 | 0.1 |
| `labelMedium` | 11sp | 500 (Medium) | 1.30 | 0.2 |
| `labelSmall` | 10sp | 500 (Medium) | 1.25 | 0.3 |

---

## 5. Motion Guidelines

- **Duration**: 150ms to 250ms
- **Curves**: `Curves.easeOutCubic` for entering elements, `Curves.easeInOutCubic` for transitions.
- **Rules**: Zero bounce, zero spring oscillations, zero indefinite spinning widgets. State changes are crisp and imperceptible as animations, felt only as responsive continuity.
