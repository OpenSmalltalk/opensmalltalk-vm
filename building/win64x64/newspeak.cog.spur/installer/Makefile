# Makefile for the Windows installer on cygwin.  Produces a Microsoft .MSI file
# given an executable, and possibly an image file.
#
# How to build:
# On unix edit and run ./links to get .exe, .map and sources, then on cygwin
# run make

SOURCES := yes
DOCUMENTATION_DIR := doc
GUID_UPGRADE_CODE := FB4E770A-413B-4745-913B-D7EE7041AA48

include branding.gmk

# Cab contents:
VM_EXECUTABLE := $(VM_BASE_NAME).exe
VM_EXECUTABLE_MAP := $(VM_BASE_NAME).map
VM_EXECUTABLE_MANIFEST := $(VM_EXECUTABLE).manifest
VM_MANIFEST_8DOT3 := $(VM_BASE_NAME).man
VM_ICON := $(VM_BASE_NAME).ico
SOURCEFILENAME1 := SqueakV50.sources

CAB_FILES := $(VM_EXECUTABLE) $(VM_EXECUTABLE_MAP) $(VM_EXECUTABLE_MANIFEST)
ifeq ($(strip $(SOURCES)),yes)
CAB_FILES := $(CAB_FILES) $(SOURCEFILENAME1)
endif

CC := /usr/bin/gcc
CP := /usr/bin/cp
SED := /usr/bin/sed
WINDRES := /usr/bin/windres

icon.o:	$(VM_BASE_NAME).rc
	$(WINDRES) --include-dir=.. --define _WIN32 -l 0 -i $< -o $@

$(VM_EXECUTABLE): ../build/vm/$(VM_EXECUTABLE)
	rm -f $@
	cp $< $@

$(VM_EXECUTABLE_MAP):	../build/vm/$(VM_EXECUTABLE_MAP)
	rm -f $@
	grep " [tT] " $< | grep -v ' t \.text' >$@

$(VM_EXECUTABLE_MANIFEST):	../build/vm/$(VM_EXECUTABLE_MANIFEST)
	rm -f $@
	cp $< $@

echovars:
	@echo '$$(VERSION)='$(VERSION)
	@echo '$$(VM_ICON)='$(VM_ICON)
	@echo '$$(DOCUMENTATION_DIR)='$(DOCUMENTATION_DIR)
	@echo 'cygpath $$(DOCUMENTATION_DIR)='"$(shell cygpath -wa $(DOCUMENTATION_DIR))\\"

include installer-Windows.gmk
