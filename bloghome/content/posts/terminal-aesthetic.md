---
title: "Designing a calmer terminal-native Hugo theme"
date: 2024-08-23
lastmod: 2026-07-29
description: "Keeping the character of a terminal without sacrificing hierarchy, readability, or accessibility."
tags: ["design", "hugo", "accessibility"]
---

Terminal-inspired sites have a recognizable vocabulary: monospace labels, dark surfaces, bright status colors, and command-line prompts. The hard part is keeping that character without turning every line into neon.

## Keep the terminal as an accent

The refreshed Candace theme uses terminal language for navigation, labels, and small bits of interface chrome. Long-form text uses a system sans-serif stack with a comfortable line length. Code remains monospace.

The palette has three jobs:

- green marks positive status and primary actions;
- cyan identifies links and secondary information;
- warm off-white carries the reading experience.

Muted text and quiet borders do most of the remaining work.

## One visual system

The old theme switched from a raw terminal homepage to a bright article card. The new layout keeps the same dark surfaces, spacing scale, navigation, and typography across the home page, lists, and individual notes.

That consistency also reduces CSS complexity: the design is a small set of reusable panels, cards, metadata rows, and prose rules.

## Accessibility is part of the aesthetic

The theme includes a skip link, visible keyboard focus, semantic navigation, responsive layouts, reduced-motion support, and high-contrast text. The result still feels like a terminal, but it behaves like a modern reading interface.
