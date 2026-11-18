## 2026-06-09 - Focus Visibility & Reduced Motion in Custom UT Overrides
**Learning:** Custom UI components extending APEX Universal Theme need explicit `:focus-visible` styles using theme CSS variables (`var(--ut-palette-primary)`) and `prefers-reduced-motion` fallbacks to ensure keyboard accessibility and comfort for users sensitive to motion effects.
**Action:** Always include `:focus-visible` outline rings with theme variable fallbacks and `@media (prefers-reduced-motion: reduce)` rules when creating or extending Universal Theme CSS overrides.
