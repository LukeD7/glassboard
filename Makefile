APP_NAME = Glassboard
BUILD_DIR = .build/release
EXECUTABLE = $(BUILD_DIR)/$(APP_NAME)
APP_BUNDLE = $(APP_NAME).app
CONTENTS_DIR = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources
INFO_PLIST = $(CONTENTS_DIR)/Info.plist
ENTITLEMENTS = Sources/Glassboard/Glassboard.entitlements
ICON_SOURCE = Assets/logo.png
ICON_SET = Glassboard.iconset
ICON_FILE = AppIcon.icns
ZIP_NAME = Glassboard.zip

# Code Signing & Notarization (Override these with environment variables)
# Example: make release SIGNING_ID="Developer ID Application: Luke Dust (XXXX)" NOTARY_PROFILE="glassboard-notary"
SIGNING_ID ?= -
NOTARY_PROFILE ?= glassboard-notary

.PHONY: all build app install clean release package sign notarize

all: app

build:
	swift build -c release

app: build
	@echo "Creating $(APP_BUNDLE)..."
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)
	@cp $(EXECUTABLE) $(MACOS_DIR)/
	@if [ -f "$(ICON_SOURCE)" ]; then \
		echo "Generating application icon from $(ICON_SOURCE)..."; \
		mkdir -p $(ICON_SET); \
		swift Scripts/GenerateAppIcon.swift "$(ICON_SOURCE)" "$(ICON_SET)"; \
		iconutil -c icns $(ICON_SET) -o $(ICON_FILE); \
		cp $(ICON_FILE) $(RESOURCES_DIR)/; \
		rm -rf $(ICON_SET); \
		rm $(ICON_FILE); \
	else \
		echo "Warning: $(ICON_SOURCE) not found. App will have default icon."; \
	fi
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > $(INFO_PLIST)
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $(INFO_PLIST)
	@echo '<plist version="1.0">' >> $(INFO_PLIST)
	@echo '<dict>' >> $(INFO_PLIST)
	@echo '    <key>CFBundleExecutable</key>' >> $(INFO_PLIST)
	@echo '    <string>$(APP_NAME)</string>' >> $(INFO_PLIST)
	@echo '    <key>CFBundleIconFile</key>' >> $(INFO_PLIST)
	@echo '    <string>AppIcon</string>' >> $(INFO_PLIST)
	@echo '    <key>CFBundleIdentifier</key>' >> $(INFO_PLIST)
	@echo '    <string>com.glassboard.app</string>' >> $(INFO_PLIST)
	@echo '    <key>CFBundleName</key>' >> $(INFO_PLIST)
	@echo '    <string>$(APP_NAME)</string>' >> $(INFO_PLIST)
	@echo '    <key>CFBundleShortVersionString</key>' >> $(INFO_PLIST)
	@echo '    <string>1.0</string>' >> $(INFO_PLIST)
	@echo '    <key>CFBundleVersion</key>' >> $(INFO_PLIST)
	@echo '    <string>1</string>' >> $(INFO_PLIST)
	@echo '    <key>LSUIElement</key>' >> $(INFO_PLIST)
	@echo '    <true/>' >> $(INFO_PLIST)
	@echo '    <key>NSPrincipalClass</key>' >> $(INFO_PLIST)
	@echo '    <string>NSApplication</string>' >> $(INFO_PLIST)
	@echo '    <key>NSHighResolutionCapable</key>' >> $(INFO_PLIST)
	@echo '    <true/>' >> $(INFO_PLIST)
	@echo '    <key>NSAppleEventsUsageDescription</key>' >> $(INFO_PLIST)
	@echo '    <string>Glassboard needs to control other applications to paste content directly for you.</string>' >> $(INFO_PLIST)
	@echo '    <key>NSScreenCaptureUsageDescription</key>' >> $(INFO_PLIST)
	@echo '    <string>Glassboard needs access to screen recording to capture screenshots.</string>' >> $(INFO_PLIST)
	@echo '    <key>NSAccessibilityUsageDescription</key>' >> $(INFO_PLIST)
	@echo '    <string>Glassboard uses accessibility features to detect shortcuts and window focus.</string>' >> $(INFO_PLIST)
	@echo '</dict>' >> $(INFO_PLIST)
	@echo '</plist>' >> $(INFO_PLIST)
	@echo "Ad-hoc signing with entitlements..."
	codesign --force --deep --sign - --entitlements $(ENTITLEMENTS) $(APP_BUNDLE)
	@echo "Glassboard.app is ready."

sign: app
	@echo "Signing $(APP_BUNDLE) with identity: $(SIGNING_ID)..."
	codesign --force --options runtime --deep --sign "$(SIGNING_ID)" --entitlements $(ENTITLEMENTS) $(APP_BUNDLE)
	@echo "Signing complete."

# Create a zip of the APP for distribution/notarization
package: sign
	@echo "Packaging $(APP_BUNDLE) into $(ZIP_NAME)..."
	/usr/bin/ditto -c -k --keepParent $(APP_BUNDLE) $(ZIP_NAME)
	@echo "Package ready: $(ZIP_NAME)"

# Create a zip without signing (for quick sharing/testing)
dist: app
	@echo "Packaging (Ad-hoc) $(APP_BUNDLE) into $(ZIP_NAME)..."
	/usr/bin/ditto -c -k --keepParent $(APP_BUNDLE) $(ZIP_NAME)
	@echo "Distribution package ready: $(ZIP_NAME)"

# Notarize the package (Requires apple ID and dev program)
# Usage: make notarize SIGNING_ID="Dev ID"
notarize: package
	@echo "Submitting $(ZIP_NAME) for notarization..."
	xcrun notarytool submit $(ZIP_NAME) --keychain-profile "$(NOTARY_PROFILE)" --wait
	@echo "Stapling ticket to app..."
	xcrun stapler staple $(APP_BUNDLE)
	@echo "Stapling complete. Re-packaging stapled app..."
	/usr/bin/ditto -c -k --keepParent $(APP_BUNDLE) $(ZIP_NAME)
	@echo "Distribution-ready file: $(ZIP_NAME)"

release: notarize

install: app
	@echo "Installing to /Applications..."
	@pkill -f Glassboard || true
	@mkdir -p /Applications/$(APP_BUNDLE)
	@rsync -a --delete $(APP_BUNDLE)/ /Applications/$(APP_BUNDLE)/
	@echo "Installation complete."

clean:
	rm -rf .build
	rm -rf $(APP_BUNDLE)
	rm -rf $(ZIP_NAME)
