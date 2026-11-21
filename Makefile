APP_NAME  := Muse
BUNDLE_ID := io.github.singhchinmayy.Muse
BUILD     := build
APP       := $(BUILD)/$(APP_NAME).app
INSTALL_DIR ?= $(HOME)/Applications
AGENT     := $(HOME)/Library/LaunchAgents/$(BUNDLE_ID).plist
LOG       := $(HOME)/Library/Logs/$(APP_NAME).log
USER_ID   := $(shell id -u)

.PHONY: all app test install uninstall restart logs probe clean

all: app

SOURCES   := Package.swift $(shell find Sources -name '*.swift')

$(BUILD)/$(APP_NAME): $(SOURCES)
	@mkdir -p $(BUILD)
	swift build -c release --product $(APP_NAME)
	cp "$$(swift build -c release --show-bin-path)/$(APP_NAME)" $@

test:
	swift test

$(BUILD)/AppIcon.icns: assets/logo.png
	@rm -rf $(BUILD)/AppIcon.iconset && mkdir -p $(BUILD)/AppIcon.iconset
	@for s in 16 32 128 256 512; do \
		sips -z $$s $$s assets/logo.png --out $(BUILD)/AppIcon.iconset/icon_$${s}x$${s}.png >/dev/null; \
		d=$$((s*2)); sips -z $$d $$d assets/logo.png --out $(BUILD)/AppIcon.iconset/icon_$${s}x$${s}@2x.png >/dev/null; \
	done
	iconutil -c icns $(BUILD)/AppIcon.iconset -o $@

app: $(BUILD)/$(APP_NAME) $(BUILD)/AppIcon.icns Resources/Info.plist
	@rm -rf $(APP) && mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp $(BUILD)/$(APP_NAME) $(APP)/Contents/MacOS/
	cp Resources/Info.plist $(APP)/Contents/
	cp $(BUILD)/AppIcon.icns $(APP)/Contents/Resources/
	codesign --force --sign - --identifier $(BUNDLE_ID) $(APP)

install: app
	-launchctl bootout gui/$(USER_ID)/$(BUNDLE_ID) 2>/dev/null
	@mkdir -p $(INSTALL_DIR) && rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	cp -R $(APP) $(INSTALL_DIR)/
	sed -e 's|__APP__|$(INSTALL_DIR)/$(APP_NAME).app|' -e 's|__LOG__|$(LOG)|' Resources/launchagent.plist > $(AGENT)
	launchctl bootstrap gui/$(USER_ID) $(AGENT)
	@echo "Installed. Turn on Muse in System Settings > Privacy & Security > Accessibility."
	@open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

uninstall:
	-launchctl bootout gui/$(USER_ID)/$(BUNDLE_ID) 2>/dev/null
	rm -f $(AGENT)
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	-tccutil reset Accessibility $(BUNDLE_ID)

restart:
	launchctl kickstart -k gui/$(USER_ID)/$(BUNDLE_ID)

logs:
	tail -f $(LOG)

probe: $(BUILD)/$(APP_NAME)
	$(BUILD)/$(APP_NAME) --probe

clean:
	rm -rf $(BUILD) .build
