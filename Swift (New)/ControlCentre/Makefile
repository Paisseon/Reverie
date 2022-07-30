SYSROOT = $(THEOS)/sdks/iPhoneOS14.4.sdk/
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:13.0

FINALPACKAGE = 1
DEBUG = 0
THEOS_LEAN_AND_MEAN = 1

BUNDLE_NAME = ReverieCC
$(BUNDLE_NAME)_BUNDLE_EXTENSION = bundle
$(BUNDLE_NAME)_FILES = $(BUNDLE_NAME).m
$(BUNDLE_NAME)_CFLAGS = -fobjc-arc
$(BUNDLE_NAME)_PRIVATE_FRAMEWORKS = ControlCenterUIKit
$(BUNDLE_NAME)_INSTALL_PATH = /Library/ControlCenter/Bundles/

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/bundle.mk

