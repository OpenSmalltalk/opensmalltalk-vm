#############################################################################
# Generic Makefile for VM app bundle
# Do make getversion to get makwe -n to work
#
# This is designed to be invoked by Makefile in a specific build directory via
# include ../common/Makefile.app
#
# Parameters:
# VMSRCDIR defines the locaton of the VM source to build.  Required.
#
# COGDEFS supply any command-line defines to use, and may be null.
#
# The name of the VM to build.  Optional.  Defaults to Squeak
#
# PLUGINSRCDIR defines the locaton of the plugin source, the subsets of which
# selected by plugins.int and plugins.ext will be built. Optional. Defaults to
# ../../src
# 
# CONFIGURATION defines what version of the VM to build, product, assert or
# debug. Optional. Defaults to product. The default is overridden in mvm script


ifeq ("$(CONFIGURATION)","product")
	APP:=CocoaFast.app
else ifeq ("$(CONFIGURATION)","assert")
	APP:=CocoaAssert.app
else
	APP:=CocoaDebug.app
endif

default:	$(APP)

include ../common/Makefile.vm

cleanall: cleanapp cleanastapp cleandbgapp cleanallvm

cleanapp:
	rm -rf CocoaFast.app

cleanastapp:
	rm -rf CocoaAssert.app

cleandbgapp:
	rm -rf CocoaDebug.app

VMEXE:=$(APP)/Contents/MacOS/$(VM)
VMPLIST:=$(APP)/Contents/Info.plist
VMBUNDLES:=$(addprefix $(APP)/Contents/Resources/, $(addsuffix .bundle, $(EXTERNAL_PLUGINS)))
OSXICONS:=$(OSXDIR)/$(VM).icns $(wildcard $(OSXDIR)/$(SYSTEM)*.icns)
VMICONS:=$(addprefix $(APP)/Contents/Resources/,$(notdir $(OSXICONS)))
VMMENUNIB:=$(APP)/Contents/Resources/English.lproj/MainMenu.nib

$(APP):	$(VMEXE) $(VMBUNDLES) $(VMPLIST) $(VMMENUNIB) $(VMICONS) $(APPPOST)

$(VMEXE): vm $(OBJDIR)/$(VM)
	mkdir -p $(APP)/Contents/MacOS
	cp $(OBJDIR)/$(VM) $(APP)/Contents/MacOS

$(APP)/Contents/Resources/%.bundle: $(BLDDIR)/vm/%.bundle
	mkdir -p $(APP)/Contents/Resources
	cp -pR $< $(APP)/Contents/Resources

$(VMPLIST): $(OSXDIR)/$(SYSTEM)-Info.plist getversion
	mkdir -p $(APP)/Contents
	sed "s/\$$(VERSION)/`getversion VERSION_TAG`/" $< | \
	sed "s/\$$(VERSION_NUMBER)/`getversion VERSION_NUMBER`/" | \
	sed "s/\$$(VERSION_TAG)/`getversion VERSION_TAG`/" | \
	sed "s/\$$(VM_NICKNAME)/`getversion VM_NICKNAME`/" > $@

$(VMMENUNIB): $(PLATDIR)/iOS/vm/English.lproj/MainMenu.xib
	mkdir -p $(dir $@)
	$(XCUB)/ibtool --errors --warnings --notices --module $(VM) \
	--minimum-deployment-target $(TARGET_VERSION_MIN) \
	--auto-activate-custom-fonts --output-format human-readable-text \
	--compile $(VMMENUNIB) \
	$(PLATDIR)/iOS/vm/English.lproj/MainMenu.xib

$(APP)/Contents/Resources/%.icns: $(OSXDIR)/%.icns
	mkdir -p $(APP)/Contents/Resources
	cp -p $< $(APP)/Contents/Resources

print-app-settings:
	@echo ---------------- Makefile.app settings ------------------
	@echo APP=$(APP)
	@echo VMEXE=$(VMEXE)
	@echo VMBUNDLES=$(VMBUNDLES)
	@echo VMPLIST=$(VMPLIST)
	@echo VMICONS=$(VMICONS)
	@echo -----------------------------------------------------
