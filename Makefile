# Linux Makefile for Gemini Watermark Tool
#
# This Makefile is intended for Linux users who wish to build the project
# using system-installed libraries (pkg-config) instead of CMake/vcpkg.
#
# Prerequisites:
#   sudo apt install g++ pkg-config libopencv-dev libfmt-dev libspdlog-dev libcli11-dev
#

CXX      ?= g++
CXXFLAGS := -std=c++20 -O3 -Wall -Wextra -pthread
LDFLAGS  := 

# Application metadata
APP_NAME    := GeminiWatermarkTool
APP_VERSION := 0.1.2

# Define macros
CXXFLAGS += -DAPP_VERSION=\"$(APP_VERSION)\" -DAPP_NAME=\"$(APP_NAME)\"

# Find dependencies using pkg-config
# Note: CLI11 is header-only and usually found in /usr/include, so no pkg-config needed usually.
# If CLI11 requires a flag, add it here.
PKGS := opencv4 fmt spdlog

CXXFLAGS += $(shell pkg-config --cflags $(PKGS))
LDFLAGS  += $(shell pkg-config --libs $(PKGS))

# Source files
SRCS := src/main.cpp \
        src/watermark_engine.cpp \
        src/blend_modes.cpp

# Object files (placed in build/ directory to keep source clean)
OBJDIR := build
OBJS := $(SRCS:%.cpp=$(OBJDIR)/%.o)

# Include directories
INCLUDES := -Isrc -Iassets

# Targets
.PHONY: all clean install uninstall test

all: $(APP_NAME)

$(APP_NAME): $(OBJS)
	@echo "Linking $@"
	$(CXX) $(OBJS) -o $@ $(LDFLAGS)
	@echo "Build complete: ./$(APP_NAME)"

$(OBJDIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	@echo "Compiling $<"
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

# Test Target
TEST_NAME := test_regression
TEST_SRCS := tests/test_regression.cpp src/watermark_engine.cpp src/blend_modes.cpp
TEST_OBJS := $(TEST_SRCS:%.cpp=$(OBJDIR)/%.o)

$(TEST_NAME): $(TEST_OBJS)
	@echo "Linking Test $@"
	$(CXX) $(TEST_OBJS) -o $@ $(LDFLAGS)

test: $(TEST_NAME)
	@echo "Running Tests..."
	./$(TEST_NAME)

clean:
	@echo "Cleaning up..."
	rm -rf $(OBJDIR) $(APP_NAME) $(TEST_NAME)

install: $(APP_NAME)
	@echo "Installing to /usr/local/bin/$(APP_NAME)"
	@install -m 755 $(APP_NAME) /usr/local/bin/$(APP_NAME)

uninstall:
	@echo "Removing /usr/local/bin/$(APP_NAME)"
	@rm -f /usr/local/bin/$(APP_NAME)
