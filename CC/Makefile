# Theos optimisations

ARCHS = arm64 arm64e

ifeq ($(ROOTLESS),1)
	TARGET = iphone:clang:latest:15.0
endif


# Define included files, imported frameworks, etc.

BUNDLE_NAME = ReverieCC
$(BUNDLE_NAME)_FILES = $(shell find Sources/$(BUNDLE_NAME) -name '*.swift')
$(BUNDLE_NAME)_INSTALL_PATH = /Library/ControlCenter/Bundles
$(BUNDLE_NAME)_PRIVATE_FRAMEWORKS = ControlCenterUIKit

# Theos makefiles to include

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
include $(THEOS_MAKE_PATH)/bundle.mk

# Rootless support? with a question mark

ifeq ($(ROOTLESS),1)
internal-stage::
	@$(PRINT_FORMAT_MAKING) "Patching load commands for $(BUNDLE_NAME)"
	
	$(ECHO_NOTHING)for fw in $($(BUNDLE_NAME)_EXTRA_FRAMEWORKS); do \
		install_name_tool -change /Library/Frameworks/$$fw.framework/$$fw \
		/var/jb/Library/Frameworks/$$fw.framework/$$fw \
		"$(THEOS_STAGING_DIR)/Library/ControlCenter/Bundles/$(BUNDLE_NAME).bundle/$(BUNDLE_NAME)" > /dev/null 2>&1 ; \
	done$(ECHO_END)
	
	$(ECHO_NOTHING)for lib in $($(BUNDLE_NAME)_LIBRARIES); do \
		install_name_tool -change /usr/lib/lib$$lib.dylib \
		/var/jb/usr/lib/lib$$lib.dylib \
		"$(THEOS_STAGING_DIR)/Library/ControlCenter/Bundles/$(BUNDLE_NAME).bundle/$(BUNDLE_NAME)" > /dev/null 2>&1 ; \
	done$(ECHO_END)
	
	@$(PRINT_FORMAT_MAKING) "Re-signing $(BUNDLE_NAME)"
	
	$(ECHO_NOTHING)ldid -S "$(THEOS_STAGING_DIR)/Library/ControlCenter/Bundles/$(BUNDLE_NAME).bundle/$(BUNDLE_NAME)"$(ECHO_END)
endif
