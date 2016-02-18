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
# SOURCEFILE the Smalltalk source file to link into this directory. Optional.
#
# APPSOURCE the Smalltalk source file to link into the app Resource. Optional.
#
# PLUGINSRCDIR defines the locaton of the plugin source, the subsets of which
# selected by plugins.int and plugins.ext will be built. Optional. Defaults to
# ../../src
# 
# CONFIGURATION defines what version of the VM to build, product, assert or
# debug. Optional. Defaults to product. The default is overridden in mvm script


ifeq ($(CONFIGURATION),debug)
	APP:=CocoaDebug.app
else ifeq ($(CONFIGURATION),assert)
	APP:=CocoaAssert.app
else # default CONFIGURATION=product => CocoaFast.app
	APP:=CocoaFast.app
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
SOURCES:=
ifneq ($(SOURCEFILE),)
SOURCES:=./$(SOURCEFILE)
endif
ifneq ($(APPSOURCE),)
SOURCES:=$(SOURCES) $(APP)/Contents/Resources/$(APPSOURCE)
endif


$(APP):	cleanbundles $(VMEXE) $(VMBUNDLES) $(VMPLIST) $(VMMENUNIB) $(VMICONS) \
 		$(SOURCES) $(APPPOST) signapp touchapp

# Bundles with missing prerequisites won't be built. But we need to force the
# attempt to make them every time in case the prerequisites /have/ been built.
# to do this we must both delete the bundles and touch any ignore files, upon
# which the bundle build depends.
cleanbundles:
	-rm -rf $(APP)/Contents/Resources/*.bundle
	-touch $(OBJDIR)/*.ignore

$(VMEXE): $(OBJDIR)/$(VM)
	mkdir -p $(APP)/Contents/MacOS
	cp -p $(OBJDIR)/$(VM) $(APP)/Contents/MacOS

$(APP)/Contents/Resources/%.bundle: $(BLDDIR)/vm/%.bundle
	@mkdir -p $(APP)/Contents/Resources
	@if [ -f $(basename $<).ignore ]; then \
		echo $(notdir $<) is being ignored; \
		rm -rf $^; \
	else \
		echo cp -pR $< $(APP)/Contents/Resources; \
		cp -pR $< $(APP)/Contents/Resources; \
	fi

$(VMPLIST): $(OSXDIR)/$(SYSTEM)-Info.plist getversion
	mkdir -p $(APP)/Contents
	sed "s/\$$(VERSION)/`getversion VERSION_TAG`/" $< | \
	sed "s/\$$(VERSION_NUMBER)/`getversion VERSION_NUMBER`/" | \
	sed "s/\$$(VERSION_TAG)/`getversion VERSION_TAG`/" | \
	sed "s/\$$(VIRTUAL_MACHINE_NICKNAME)/`getversion VIRTUAL_MACHINE_NICKNAME`/" | \
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

# To sign the app, set SIGNING_IDENTITY in the environment, e.g.
# export SIGNING_IDENTITY="Developer ID Application: Eliot Miranda"
#
ifeq ($(SIGNING_IDENTITY),)
signapp:
	echo "No signing identity found (SIGNING_IDENTITY unset). Not signing app."
else
signapp:
	codesign -f --deep -s "$(SIGNING_IDENTITY)" $(APP)
endif

touchapp:
	touch $(APP)

# source installation
%.sources: ../../sources/%.sources
	ln $< $@

$(APP)/Contents/Resources/%.sources: ../../sources/%.sources
	ln $< $@

print-app-settings:
	@echo ---------------- Makefile.app settings ------------------
	@echo APP=$(APP)
	@echo VMEXE=$(VMEXE)
	@echo VMBUNDLES=$(VMBUNDLES)
	@echo VMPLIST=$(VMPLIST)
	@echo VMICONS=$(VMICONS)
	@echo SIGNING_IDENTITY=$(SIGNING_IDENTITY)
	@echo SOURCEFILE=$(SOURCEFILE)
	@echo APPSOURCE=$(APPSOURCE)
	@echo -----------------------------------------------------
