# Sweep — AI photo cleaner (iOS) · design handoff

Source of truth for the UI: the 7 screens in `design/`. Each `.dc.html` file is one screen at 390×844 pt (Home is a 390×1560 scrolling page). Markup is plain HTML with inline styles; `{{holes}}`, `<sc-for>` and `<sc-if>` are template loops/conditionals, and the `<script data-dc-script>` block at the bottom of each file holds the sample data and interaction logic (selection state, totals). Read the files for exact spacing, sizes and copy.

All counts and sizes in the designs are sample data. "Sweep" is a placeholder app name.

## Screens and flow

| # | File | Purpose | Goes to |
|---|------|---------|---------|
| 1 | `Scanning.dc.html` | On-device AI scan progress (orbit of thumbnails, progress ring, per-category status) | Home |
| 2 | `Main.dc.html` | Home: total junk found, "Clean all suggested", AI category cards, floating tab bar + scan FAB | Review, Similar, Videos, Confirm, Scanning |
| 3 | `Review.dc.html` | Screenshots grid with bulk select: tap to toggle, Select all, "Select all 2,104 suggested", AI "keep" items unselected by default | Confirm |
| 4 | `Similar.dc.html` | Similar-photo group: AI best shot kept, others marked; tap to keep; switch to apply to all groups | Confirm |
| 5 | `Videos.dc.html` | Per-video Delete / Compress / Keep segmented choice, AI pre-selected, live "free X GB" total | Confirm |
| 6 | `Confirm.dc.html` | Bulk-clean sheet: category checkboxes, live item count and size, destructive confirm | Done |
| 7 | `Done.dc.html` | Result: space cleaned, before/after storage, "Empty Recently Deleted", weekly scan switch | Home |

## Design tokens

| Token | Value | Use |
|---|---|---|
| background | `#F2F3F5` | screen ground |
| surface | `#FFFFFF` | cards, round icon buttons, tab bar |
| ink | `#0B0B0C` | text, primary black pill buttons, FAB, selected chips |
| muted | `#5F646C` | secondary text |
| line | `#E1E4E8` | unselected chip border |
| accent | `#1A5DD8` | "Clean all suggested", selection, switches, progress |
| accent-soft | `#EAF0FC` | AI icon circles |
| destructive | `#C8261B` | final Clean confirm and Delete segment only |
| category tints | Screenshots `#C7CCF6`, Similar `#F6B3B0`, Duplicates `#BFE3D3`, Blurry `#D9DBE1`, Large videos `#F3DDA0`, Accidental `#F5C6A5`, Screen rec `#DCC8F0` | category cards and icons |

- Type: system font (SF Pro). Titles 24–32 pt semibold, tracking about −0.02em; body 15–16; captions 12–14.
- Radii: cards 22–28, photo tiles 14–18, pills fully rounded (height/2), round icon buttons 40 pt.
- Shadows: soft, e.g. `0 8px 24px rgba(16,24,40,0.12)` on floating elements.
- Frosted strip on category cards: translucent white with background blur (SwiftUI `.ultraThinMaterial` is the closest).
- Touch targets are 44 pt or more. Icons are stroke icons, so SF Symbols can replace them.

## Behavior to implement

- The AI pre-selects junk, and items it flags as important (tickets, documents, keepers) start unselected with an "AI: keep" label.
- Bulk select at three levels: single item, "Select all" on screen, and "select all suggested" across the whole category. There's also a cross-category bulk clean on the Confirm sheet.
- Totals (count and size) update live as the selection changes.
- Deleted items go to iOS Recently Deleted, and the copy tells the user they can be restored for 30 days.
