SYSROOT = $(THEOS)/sdks/iPhoneOS13.3.sdk
ARCHS = arm64
BUNDLE_NAME = ReverieCC
$(BUNDLE_NAME)_BUNDLE_EXTENSION = bundle
$(BUNDLE_NAME)_FILES = ReverieCC.m
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(BUNDLE_NAME)_PRIVATE_FRAMEWORKS = ControlCenterUIKit
$(TWEAK_NAME)_EXTRA_FRAMEWORKS = UIKit
$(BUNDLE_NAME)_INSTALL_PATH = /Library/ControlCenter/Bundles/
ADDITIONAL_CFLAGS += -DTHEOS_LEAN_AND_MEAN

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/bundle.mk

