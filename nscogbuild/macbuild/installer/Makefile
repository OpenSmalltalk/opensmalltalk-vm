# Makefile for the Mac OS installer.
# Produces a .dmg given an executable, and possibly an image file.
#
# How to build:
# edit and run ./links to get .app and sources, then run make

SOURCES := yes
DOCUMENTATION_DIR := doc

include branding.gmk
include branding-sed-rules.gmk

space:= $(empty) $(empty)
define ESCAPE_VAR
$(1)_ESC := $(subst $(space),\$(space),$($(1)))
endef
BRANDING := VM_BASE_NAME PRODUCT_NAME VM_LOCALIZED_NAME MANUFACTURER IMAGE
$(foreach var,$(BRANDING),$(eval $(call ESCAPE_VAR,$(var))))

$(VM_LOCALIZED_NAME_ESC).app:
	rm -rf $(VM_LOCALIZED_NAME_ESC).app
	cp -R ../Fast.app $(VM_LOCALIZED_NAME_ESC).app

# Cab contents:
VM_BUNDLE := $(VM_LOCALIZED_NAME_ESC).app
SOURCEFILENAME1 := SqueakV41.sources

include installer-Darwin.gmk
