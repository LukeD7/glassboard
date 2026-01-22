# Installation Guide

This guide provides detailed instructions for installing Glassboard on macOS.

---

## System Requirements

- **Operating System:** macOS 13.0 (Ventura) or later
- **Architecture:** Apple Silicon (M1/M2/M3) or Intel-based Macs
- **Permissions:** You'll need to grant Glassboard the following permissions on first run:
  - Screen Recording (for screenshot capture)
  - Accessibility (for keyboard shortcuts)
  - Apple Events (for pasting content)

---

## Installation Methods

### Option 1: Homebrew (Recommended)

The easiest way to install and keep Glassboard updated.

1. Add the Glassboard tap:
   ```bash
   brew tap luked7/glassboard https://github.com/luked7/glassboard
   ```

2. Install Glassboard:
   ```bash
   brew install --cask glassboard
   ```

3. Launch Glassboard from your Applications folder or Spotlight.

**To update Glassboard later:**
```bash
brew upgrade --cask glassboard
```

**To uninstall:**
```bash
brew uninstall --cask glassboard
```

---

### Option 2: Manual Download

If you prefer not to use Homebrew:

1. Visit the [Releases page](https://github.com/luked7/glassboard/releases)
2. Download the latest `Glassboard.zip` file
3. Unzip the downloaded file
4. Drag `Glassboard.app` to your **Applications** folder
5. Launch Glassboard from Applications

**First-time launch on macOS:**
Because this is an open-source app distributed outside the Mac App Store, macOS may prevent it from opening. To fix this:
1. Right-click (or Control-click) on `Glassboard.app`
2. Select **Open** from the context menu
3. Click **Open** in the dialog that appears

This only needs to be done once.

---

### Option 3: Build from Source

For developers who want to compile Glassboard themselves:

#### Prerequisites

- macOS 13.0+
- Xcode Command Line Tools (includes Swift 5.9+)
- Git

**Install Xcode Command Line Tools (if not already installed):**
```bash
xcode-select --install
```

#### Build Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/luked7/glassboard.git
   cd glassboard
   ```

2. Build and install:
   ```bash
   make install
   ```

This will:
- Build the app in release mode
- Create the `.app` bundle with proper icons and Info.plist
- Copy it to your `/Applications` folder
- Terminate any running instance of Glassboard

3. Launch Glassboard from your Applications folder.

**For development:**
If you want to run Glassboard in debug mode without building the full app bundle:
```bash
swift run
```

To build the app bundle without installing:
```bash
make app
open Glassboard.app
```

---

## Post-Installation Setup

### Granting Permissions

When you first launch Glassboard, macOS will ask for several permissions:

1. **Accessibility Access**
   - Required for keyboard shortcuts to work
   - Go to: System Settings → Privacy & Security → Accessibility
   - Enable Glassboard

2. **Screen Recording**
   - Required for screenshot capture (`⌘⇧C`)
   - Go to: System Settings → Privacy & Security → Screen Recording
   - Enable Glassboard

3. **Apple Events** (if prompted)
   - Required to paste content into other apps
   - Will be requested automatically when needed

**Note:** You may need to restart Glassboard after granting these permissions.

### Using Glassboard

Once installed and running, Glassboard lives in your menu bar. Use these shortcuts:

- **⌘⇧V** - Open clipboard history (search by typing, press Enter to paste)
- **⌘⇧C** - Capture a screenshot to clipboard

Glassboard automatically tracks your last 50 copied items.

---

## Troubleshooting

### "Glassboard.app cannot be opened"

If you see this message, follow the steps under [Manual Download](#option-2-manual-download) to approve the app.

### Keyboard Shortcuts Not Working

1. Make sure Glassboard is running (check menu bar)
2. Verify Accessibility permissions are granted
3. Try quitting and relaunching Glassboard

### Screenshots Not Working

1. Verify Screen Recording permission is granted
2. Go to System Settings → Privacy & Security → Screen Recording
3. Make sure Glassboard is checked
4. Restart Glassboard

### Build Errors (Source Installation)

If you encounter build errors:

1. Verify Xcode Command Line Tools are installed:
   ```bash
   xcode-select -p
   ```

2. If not installed or outdated:
   ```bash
   xcode-select --install
   ```

3. Make sure you're on macOS 13.0 or later:
   ```bash
   sw_vers
   ```

### Glassboard Doesn't Start After Installation

1. Check Console.app for error messages (search for "Glassboard")
2. Try launching from Terminal to see error output:
   ```bash
   /Applications/Glassboard.app/Contents/MacOS/Glassboard
   ```

---

## Updating Glassboard

### Homebrew Installation
```bash
brew upgrade --cask glassboard
```

### Manual Installation
Download the latest release and replace the old app in your Applications folder.

### Source Installation
```bash
cd glassboard
git pull
make install
```

---

## Uninstalling Glassboard

### Homebrew
```bash
brew uninstall --cask glassboard
```

### Manual Installation
1. Quit Glassboard
2. Drag `Glassboard.app` from Applications to Trash
3. (Optional) Remove clipboard history data:
   ```bash
   rm -rf ~/Library/Application\ Support/Glassboard
   ```

---

## Getting Help

- **Issues:** [GitHub Issues](https://github.com/luked7/glassboard/issues)
- **Discussions:** [GitHub Discussions](https://github.com/luked7/glassboard/discussions)
- **Documentation:** [README](README.md)

---

## License

Glassboard is MIT licensed and free forever.
