# Glassboard

A fast, visual clipboard history for macOS.

Glassboard brings the immediacy of Windows **Win + V** to macOS, with first-class
support for screenshots, instant search, and keyboard-driven use.

No accounts. No cloud. No configuration.

---

## Why

macOS has a powerful clipboard system but no usable history UI.

Glassboard exists because:
- Clipboard history should be **visible**
- Screenshots should be **first-class**
- Pasting should require **zero thought**

This is not a power tool.
It is a simple, opinionated replacement for invisible clipboard behavior.

---

## Features (v1)

- Global clipboard history (text and images)
- Screenshot-first visual list
- Instant search by typing
- Minimal pinning (small, capped)
- Global hotkey: **⌘⇧V** for clipboard history
- **Screen Grab Tool**: **⌘⇧C** for quick screenshots
  - Selection (draw area), Window, or Full Screen modes
  - Remembers your last used capture mode
  - Always copies directly to clipboard
  - Right-click menu bar icon for manual mode selection
- Menu bar access
- Fully local storage

---

## Non-Goals

Glassboard deliberately does **not** include:

- Cloud or iCloud sync
- Accounts or analytics
- Snippets or templates
- Clipboard editing
- Tags, folders, or collections
- Preferences UI
- Raycast or Alfred integrations

If a feature needs explanation, it probably doesn’t belong here.

---

## Philosophy

1. Recognition beats recall  
2. Visual beats textual  
3. Speed beats flexibility  

Opinionated design is intentional.

---

## Status

Early development.  
Built primarily for personal use and shared as open source.

Breaking changes may occur before v1.0.

---

## Requirements

- macOS 13+
- Apple Silicon or Intel

---

## Installation

### For End Users (Production)

To install Glassboard as a standalone application:

1. **Clone the repository**
   ```bash
   git clone https://github.com/lukedust/glassboard.git
   cd glassboard
   ```

2. **Build & Install**
   ```bash
   make install
   ```
   This will compile the optimized release version and copy `Glassboard.app` to your `/Applications` folder.
   
   Once finished, you can launch **Glassboard** from Spotlight or your Applications folder. No terminal required.

### For Developers

**Prerequisites**
- macOS 13.0+
- Xcode 15.0+ (or Swift 5.9+ CLI)

**Development Workflow**

1. **Run from Terminal** (Quick iteration)
   ```bash
   swift run
   ```

2. **Open in Xcode** (Recommended for editing)
   Double-click `Package.swift` to open the project.

3. **Build .app Bundle**
   ```bash
   make app
   ```
   Creates `Glassboard.app` in the current directory for testing the release build behavior.

---

## License

MIT
