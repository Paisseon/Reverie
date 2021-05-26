SYSROOT = $(THEOS)/sdks/iPhoneOS13.3.sdk
ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:13.0
INSTALL_TARGET_PROCESSES = SpringBoard

TWEAK_NAME = Reverie

$(TWEAK_NAME)_FILES = Reverie.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_EXTRA_FRAMEWORKS = UIKit Cephei
GO_EASY_ON_ME = 1
ADDITIONAL_CFLAGS += -DTHEOS_LEAN_AND_MEAN

SUBPROJECTS += Prefs ControlCentre

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
include $(THEOS_MAKE_PATH)/tweak.mk