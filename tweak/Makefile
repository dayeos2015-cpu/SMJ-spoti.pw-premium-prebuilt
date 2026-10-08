TARGET := iphone:clang:latest:16.0
ARCHS := arm64
FINALPACKAGE := 1

SG_VERSION := $(or $(shell cat ../version.txt 2>/dev/null),0.0.0)
PACKAGE_VERSION := $(SG_VERSION)

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := spotifyglass

# Incluye todas las fuentes del proyecto
spotifyglass_FILES := $(shell find Sources -type f \( -name '*.m' -o -name '*.x' -o -name '*.swift' \))
spotifyglass_CFLAGS := -fobjc-arc -ISources -DSG_VERSION=\"$(SG_VERSION)\"
spotifyglass_FRAMEWORKS := UIKit QuartzCore UniformTypeIdentifiers MediaPlayer CoreImage AudioToolbox AVFoundation CoreHaptics Accelerate Network CoreML

spotifyglass_LOGOS_DEFAULT_GENERATOR := internal

SG_AUDIO := ../vendor/audio
spotifyglass_OBJ_FILES := $(SG_AUDIO)/build/ios/libsgaudio.a
Sources/Shared/AudioEffects/SGDSPCrossfeed.m_CFLAGS := -isystem $(SG_AUDIO)/libbs2b
Sources/Shared/AudioEffects/SGDSPLiveprog.m_CFLAGS := -isystem $(SG_AUDIO)/wdl/eel2

include $(THEOS_MAKE_PATH)/tweak.mk

# Generación automática de la tabla de flags requerida por FlagsPage.m
before-all::
	@if [ -x ../scripts/extract-flags.sh ]; then ../scripts/extract-flags.sh; fi
	@if [ -x ../scripts/check-layers.sh ]; then ../scripts/check-layers.sh Sources; fi

spotifyglass.all.tweak.variables: sg-audio
.PHONY: sg-audio
sg-audio:
	@$(MAKE) --no-print-directory -C $(SG_AUDIO) PLATFORM=ios
