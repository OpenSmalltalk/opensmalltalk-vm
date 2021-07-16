# Makefile for the Mac OS installer.
# Produces a .dmg given an executable, and possibly an image file.
#
# How to build:
# edit and run ./links to get .app and sources, then run make

SOURCES := yes
SOURCEFILENAME1 := ../../../sources/SqueakV50.sources
DOCUMENTATION_DIR := doc

include branding.gmk
include branding-sed-rules.gmk

space:= $(empty) $(empty)
define ESCAPE_VAR
$(1)_ESC := $(subst $(space),\$(space),$($(1)))
endef
BRANDING := VM_BASE_NAME PRODUCT_NAME VM_LOCALIZED_NAME MANUFACTURER IMAGE
$(foreach var,$(BRANDING),$(eval $(call ESCAPE_VAR,$(var))))

$(VM_LOCALIZED_NAME_ESC).app: ../CocoaFast.app
	rm -rf $(VM_LOCALIZED_NAME_ESC).app
	cp -R ../CocoaFast.app $(VM_LOCALIZED_NAME_ESC).app
	test -f $(VM_LOCALIZED_NAME_ESC).app/Contents/Resources/$(notdir $(SOURCEFILENAME1)) || ln $(SOURCEFILENAME1) $(VM_LOCALIZED_NAME_ESC).app/Contents/Resources

# Cab contents:
VM_BUNDLE := $(VM_LOCALIZED_NAME_ESC).app

include installer-Darwin.gmk
