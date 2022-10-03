#############################################################################
# Generic Makefile for VM app bundle
# Do make getversion to get make -n to work
#
# This is designed to be invoked by Makefile in a specific build directory via
# include ../common/Makefile.app
#
# Parameters:
# VMSRCDIR defines the location of the VM source to build.  Required.
#
# COGDEFS supply any command-line defines to use, and may be null.
#
# The name of the VM to build.  Optional.  Defaults to Squeak
#
# SOURCEFILE the Smalltalk source file to link into this directory. Optional.
#
# APPSOURCE the Smalltalk source file to link into the app Resource. Optional.
#
# PLUGINSRCDIR defines the location of the plugin source, the subsets of which
# selected by plugins.int and plugins.ext will be built. Optional. Defaults to
# ../../src
# 
# CONFIGURATION defines what version of the VM to build, product, assert or
# debug. Optional. Defaults to product. The default is overridden in mvm script

ifeq ($(APPNAME),)
APPNAME:=Cocoa
endif
ifeq ($(APPNAMEDEF),)
APPNAMEDEF:=$(APPNAME)Fast
endif
ifeq ($(APPIDENTIFIER),)
APPIDENTIFIER:=org.opensmalltalk.$(APPNAME)
endif
ifeq ($(USEPLUGINASDYLIB),)
USEPLUGINASDYLIB:=FALSE
endif

ifeq ($(CONFIGURATION),debug)
	APP:=$(APPNAME)Debug.app
	VM_IDENTIFIER:=$(APPIDENTIFIER)Debug
else ifeq ($(CONFIGURATION),assert)
	APP:=$(APPNAME)Assert.app
	VM_IDENTIFIER:=$(APPIDENTIFIER)Assert
else # default CONFIGURATION=product => $(APPNAMEDEF).app
	APP:=$(APPNAMEDEF).app
	VM_IDENTIFIER:=$(APPIDENTIFIER)
endif
export APP

default:	$(APP)

include ../common/Makefile.vm
include ../common/Makefile.lib.extra
include ../common/Makefile.sources

cleanall: cleanapp cleanastapp cleandbgapp cleanallvm

cleanapp:
	rm -rf $(APPNAMEDEF).app

cleanastapp:
	rm -rf $(APPNAME)Assert.app

cleandbgapp:
	rm -rf $(APPNAME)Debug.app

VMEXE:=$(APP)/Contents/MacOS/$(VM)
VMPLIST:=$(APP)/Contents/Info.plist

ifeq ($(USEPLUGINASDYLIB),FALSE)
VMBUNDLES:=$(addprefix $(APP)/Contents/$(APPPLUGINDIR)/, $(addsuffix .bundle, $(EXTERNAL_PLUGINS)))
else ifeq ($(USEPLUGINASDYLIB),TRUE)
VMPLUGINDYLIBS:=$(addprefix $(APP)/Contents/MacOS/Plugins/lib, $(addsuffix .dylib, $(EXTERNAL_PLUGINS)))
else 
$(error USEPLUGINASDYLIB has to be TRUE or FALSE)
endif 

ifneq ($(THIRDPARTYLIBS),) 
THIRDPARTYPREREQS:=$(THIRDPARTYINSTALLDIR) $(THIRDPARTYOUTDIR) $(THIRDPARTYCACHEDIR)
endif

OSXICONS:=$(OSXDIR)/$(VM).icns $(wildcard $(OSXDIR)/$(SYSTEM)*.icns)
VMICONS:=$(addprefix $(APP)/Contents/Resources/,$(notdir $(OSXICONS)))
VMMENUNIB:=$(APP)/Contents/Resources/English.lproj/MainMenu.nib
VMLOCALIZATION:=$(APP)/Contents/Resources/English.lproj/Localizable.strings
SOURCES:=
ifneq ($(SOURCEFILE),)
SOURCES:=./$(SOURCEFILE)
endif
ifneq ($(APPSOURCE),)
SOURCES:=$(SOURCES) $(APP)/Contents/Resources/$(APPSOURCE)
$(APP)/Contents/Resources/$(APPSOURCE): $(SOURCESDIR)/$(APPSOURCE)
	test -f $@ || ln $(SOURCESDIR)/$(notdir $@) $@
endif

$(APP):	cleanbundles $(THIRDPARTYPREREQS) $(VMEXE) $(VMBUNDLES) $(VMPLUGINDYLIBS) \
		$(VMPLIST) $(VMLOCALIZATION) $(VMMENUNIB) $(VMICONS) \
 		$(SOURCES) $(THIRDPARTYLIBS) pathapp $(APPPOST) signapp touchapp

# Bundles with missing prerequisites won't be built. But we need to force the
# attempt to make them every time in case the prerequisites /have/ been built.
# to do this we must both delete the bundles and touch any ignore files, upon
# which the bundle build depends.
cleanbundles:
	-rm -rf $(wildcard $(APP)/Contents/$(APPPLUGINDIR)/*.bundle)
ifneq ($(wildcard $(OBJDIR)/*.ignore),)
	-touch $(wildcard $(OBJDIR)/*.ignore)
endif

$(VMEXE): $(OBJDIR)/$(VM)
	@mkdir -p $(APP)/Contents/MacOS
	cp -p $(OBJDIR)/$(VM) $(APP)/Contents/MacOS

$(APP)/Contents/$(APPPLUGINDIR)/%.bundle: $(BLDDIR)/vm/%.bundle
	@mkdir -p $(APP)/Contents/$(APPPLUGINDIR)
	@if [ -f $(basename $<).ignore ]; then \
		echo $(notdir $<) is being ignored; \
		rm -rf $^; \
	else \
		echo cp -pR $< $(APP)/Contents/$(APPPLUGINDIR); \
		cp -pR $< $(APP)/Contents/$(APPPLUGINDIR); \
		if [ -d $(BLDDIR)/`basename $< .bundle`/Frameworks ]; then \
			echo copying frameworks for `basename $< .bundle` from $(BLDDIR)/`basename $< .bundle`/Frameworks; \
			mkdir -p $(APP)/Contents/Frameworks; \
			(cd $(BLDDIR)/`basename $< .bundle`/Frameworks >/dev/null; COPYFILE_DISABLE=1 tar cf - *) \
			| (cd $(APP)/Contents/Frameworks >/dev/null; tar xf -); \
		fi; \
	fi

$(APP)/Contents/MacOS/Plugins/%.dylib: $(BLDDIR)/vm/%.dylib
	@mkdir -p $(APP)/Contents/MacOS/Plugins
	@if [ -f $(basename $<).ignore ]; then \
		echo $(notdir $<) is being ignored; \
		rm -rf $^; \
	else \
		echo cp -p $< $(APP)/Contents/MacOS/Plugins; \
		cp -p $< $(APP)/Contents/MacOS/Plugins; \
	fi

$(VMPLIST): $(OSXDIR)/$(SYSTEM)-Info.plist getversion
	-mkdir -p $(APP)/Contents
	cp -p $< $@
	sed -i '' '\
		s!$$(VERSION)!$(shell ./getversion VERSION_TAG)!g;\
		s!$$(VERSION_NUMBER)!$(shell ./getversion VERSION_REVISION_DATE_TIME)!g;\
		s!$$(VERSION_TAG)!$(shell ./getversion VERSION_TAG)!g;\
		s!$$(VERSION_TAG_NO_BITS)!$(shell ./getversion VERSION_TAG_NO_BITS)!g;\
		s!$$(VIRTUAL_MACHINE_NICKNAME)!$(shell ./getversion VIRTUAL_MACHINE_NICKNAME)!g;\
		s!$$(VM_NICKNAME)!$(shell ./getversion VM_NICKNAME)!g;\
		s!$$(VM_MAJOR)!$(shell ./getversion VM_MAJOR)!g;\
		s!$$(VM_MINOR)!$(shell ./getversion VM_MINOR)!g;\
		s!$$(VM_IDENTIFIER)!$(VM_IDENTIFIER)!g;\
		s!$$(APP_IDENTIFIER)!$(APP_IDENTIFIER)!g;\
	' $@

$(VMLOCALIZATION): $(OSXCOMMONDIR)/English.lproj/$(SYSTEM)-Localizable.strings
	@mkdir -p $(dir $@)
	cp -p $< $@

$(VMMENUNIB): $(PLATDIR)/iOS/vm/English.lproj/$(SYSTEM)-MainMenu.xib
	@mkdir -p $(dir $@)
	$(XCUB)/ibtool --errors --warnings --notices --module $(VM) \
	--minimum-deployment-target $(TARGET_VERSION_MIN) \
	--auto-activate-custom-fonts --output-format human-readable-text \
	--compile $(VMMENUNIB) $<

$(APP)/Contents/Resources/%.icns: $(OSXDIR)/%.icns
	@mkdir -p $(APP)/Contents/Resources
	cp -p $< $(APP)/Contents/Resources

# Make sure that the executable has an executable_path for any subdirectories
# of Frameworks, and an executable_path for $(APPPLUGINDIR).
# If Frameworks does not exist still add an rpath for it, allowing someone to
# repackage the VM at a later date.
pathapp:
	-install_name_tool -add_rpath @executable_path/../$(APPPLUGINDIR) $(VMEXE)
	-install_name_tool -add_rpath @executable_path/Contents/$(APPPLUGINDIR) $(VMEXE)
	-install_name_tool -add_rpath @executable_path/Contents/Frameworks $(VMEXE)
	if [ -d "$(APP)/Contents/Frameworks" ]; then \
		for d in `cd "$(APP)/Contents" >/dev/null; find Frameworks -type d | fgrep -v .dSYM`; do \
			echo install_name_tool -add_rpath @executable_path/../$$d $(VMEXE); \
			install_name_tool -add_rpath @executable_path/../$$d $(VMEXE); \
		done \
	else \
		echo install_name_tool -add_rpath @executable_path/../Frameworks $(VMEXE); \
		install_name_tool -add_rpath @executable_path/../Frameworks $(VMEXE); \
	fi

# To sign the app, set SIGNING_IDENTITY in the environment, e.g.
# export SIGNING_IDENTITY="Developer ID Application: Eliot Miranda"
# If you're using ssh and codesign fails you probably need to unlock your
# keychain.  List the keychain using
#	$ security list-keychains -d user
# Unlock using e.g.
#	$ security unlock-keychain -p "<password>" "~/Library/Keychains/login.keychain-db"
# codesign can also crash (Killed: 9) if rebuilding an app that has been run.
# The only work-around found so far is to delete the executable ($(VMEXE) or
# app bundle and make.  Unsatisfactory...
# N.B. plugin bundles are signed in Makefile.plugin
ifeq ($(SIGNING_IDENTITY),)
signapp:
	echo "No signing identity found (SIGNING_IDENTITY unset). Not signing app."
else
signapp:
	rm -rf $(APP)/Contents/MacOS/*.cstemp
	xattr -cr $(APP)
	codesign --force --deep -s "$(SIGNING_IDENTITY)" \
			--timestamp --options=runtime \
			--entitlements ../common/entitlements.plist \
			$(APP)
endif

touchapp:
	touch $(APP)

# source installation
%.sources: ../../../sources/%.sources
	ln $< $@

$(APP)/Contents/Resources/%.sources: ../../../sources/%.sources
	ln $< $@

print-app-settings:
	$(info ---------------- Makefile.app settings ------------------)
	$(info APP=$(APP))
	$(info VMEXE=$(VMEXE))
	$(info VMBUNDLES=$(VMBUNDLES))
	$(info VMPLUGINDYLIBS=$(VMPLUGINDYLIBS))
	$(info VMPLIST=$(VMPLIST))
	$(info VMICONS=$(VMICONS))
	$(info SIGNING_IDENTITY=$(SIGNING_IDENTITY))
	$(info SOURCEFILE=$(SOURCEFILE))
	$(info APPSOURCE=$(APPSOURCE))
	$(info SOURCES=$(SOURCES))
	$(info -----------------------------------------------------)
