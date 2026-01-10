# Glassboard

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/luked7)

**A fast, private visual clipboard history for macOS.**

Glassboard brings the simplicity of Windows **Win + V** to your Mac. It gives you a clear visual history of everything you've copied—text, images, and screenshots—without the bloat.

No accounts. No cloud syncing. No complex configuration. Just a clipboard that remembers.

---

## What does it do?

- **⌘⇧V** opens your history. Type to search, Enter to paste.
- **⌘⇧C** grabs a screenshot immediately to your clipboard.
- It remembers the last 50 things you copied.
- Everything stays on your computer.

That's mostly it. Glassboard is designed to be invisible until you need it, then instant when you do.

## Why Glassboard?

I built this because I moved from Windows to macOS and hit a productivity wall.

On Windows, clipboard history is standard. On macOS, the native clipboard tools are hidden behind multiple keybinds and unclear features, adding friction where there should be none.

**Screenshots are the bigger problem.**
On Windows, one key (Print Screen) gives you a UI to choose your mode, and the result is saved *and* copied.
On macOS, you are expected to memorize multiple complex shortcuts (`⌘⇧3`, `⌘⇧4`, `⌘⇧5`...) just to decide whether you want a file on your desktop or an image in your clipboard.

**Productivity is about flow.**
As a developer, I am constantly copying code snippets, prompting AI, and sharing screenshots in team chats. I shouldn't have to pause to remember if I held `Control` or not to get an image into Slack.

Glassboard is the answer:
1.  **Unified History:** `⌘⇧V` shows everything you copied. Searchable. Visual.
2.  **Unified Capture:** `⌘⇧C` opens a tool. Select your mode (Region, Window, Full). It goes straight to the clipboard.

It is not trying to reinvent the wheel. It is just a better, lower-friction way to use native tools, wrapped in a UI that looks like it belongs on macOS.

## Installation

### Requirements
- macOS 13.0 (Ventura) or later.
- Support for both Apple Silicon and Intel Macs.

### How to Install

**Option 1: Homebrew (Recommended)**
The easiest way to install and keep Glassboard updated.

```bash
brew tap luked7/tap
brew install --cask glassboard
```

**Option 2: Manual Download**
1. Download the latest version from the [Releases page](https://github.com/luked7/glassboard/releases).
2. Unzip the file.
3. Drag `Glassboard.app` to your **Applications** folder.

*Note: Because this is an open-source app not on the App Store, you may need to Right-Click the app and choose "Open" the first time you run it.*

**Option 3: Build from Source**
If you prefer to compile it yourself:

```bash
git clone https://github.com/luked7/glassboard.git
cd glassboard
make install
```

---

## For Developers

We built this to be easy to hack on. You don't need the full Xcode IDE; you can use VS Code or just a terminal.

**Prerequisites:**
- macOS 13+
- Swift 5.9+ (included with Xcode Command Line Tools)

**Workflow:**
1. **Clone & Setup:**
   ```bash
   git clone https://github.com/luked7/glassboard.git
   cd glassboard
   ```

2. **Run in Debug Mode:**
   Tests your changes immediately without building the full app bundle.
   ```bash
   swift run
   ```

3. **Build the App:**
   When you're ready to test the actual `.app` bundle (e.g., for menu bar behavior or permissions):
   ```bash
   make app
   open Glassboard.app
   ```

**Tip:** If you are using VS Code, install the [Swift extension](https://marketplace.visualstudio.com/items?itemName=sswg.swift-lang) for full IntelliSense and debugging support.

## License

MIT. Free forever.
