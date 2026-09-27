APP_NAME := AutoTranslator
CONFIG := release
BUILD_DIR := .build/$(CONFIG)
APP_BUNDLE := $(APP_NAME).app
SIGN_IDENTITY ?= $(shell security find-identity -v -p codesigning 2>/dev/null | sed -n 's/.*"\(.*\)"/\1/p' | head -1)

.PHONY: build app run clean install

build:
	swift build -c $(CONFIG)

app: build
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	cp Resources/Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@if [ -n "$(SIGN_IDENTITY)" ]; then \
		echo "Signing with: $(SIGN_IDENTITY)"; \
		codesign --force --deep --sign "$(SIGN_IDENTITY)" $(APP_BUNDLE); \
	else \
		echo "No signing identity found; using ad-hoc signature"; \
		codesign --force --deep --sign - $(APP_BUNDLE); \
	fi
	@echo "Built $(APP_BUNDLE)"

run: app
	open $(APP_BUNDLE)

install: app
	rm -rf /Applications/$(APP_BUNDLE)
	cp -R $(APP_BUNDLE) /Applications/
	@echo "Installed to /Applications/$(APP_BUNDLE)"

clean:
	rm -rf .build $(APP_BUNDLE)
