# Copyright (c) 2024 Neil Davis (https://github.com/neildavis)

# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the
# Software without restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so, subject to the
# following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Ganeral flags
DEBUG := 0

# Tools
TOOLS_DIR := ./tools
VASM_DIR := $(TOOLS_DIR)/vasm
VLINK_DIR := $(TOOLS_DIR)/vlink

# The assembler
ASM := $(VASM_DIR)/vasmm68k_mot
ASM_ARGS := -quiet -m68000 -Fhunk -I./include

ifeq ($(DEBUG),1)
# Debug vasm args..
ASM_ARGS += -linedebug 
endif

# The linker
LD := $(VLINK_DIR)/vlink
LINK_ARGS := -mrel -bamigahunk -Bstatic

ifneq ($(DEBUG),1)
# Release vlink args..
LINK_ARGS += -s 
endif

# Source files
SRC_DIR := ./src
MAIN_SRC := $(SRC_DIR)/main.s
ASM_SRCS=$(filter-out $(MAIN_SRC),$(wildcard $(SRC_DIR)/*.s))

# Object files
BUILD_DIR := ./build
MAIN_OBJ=$(patsubst $(SRC_DIR)/%,$(BUILD_DIR)/%,$(MAIN_SRC:.s=.o))
OBJS := $(patsubst $(SRC_DIR)/%,$(BUILD_DIR)/%,$(ASM_SRCS:.s=.o))

# Assets
ASSETS_DIR := ./assets
GIMP_ASSETS := $(wildcard $(ASSETS_DIR)/*.xcf)
RAW_ASSETS := $(GIMP_ASSETS:.xcf=.raw)
PALETTE_DIR := ./include

# The target ADF dir
ADF_DIR := ./uae/dh0
# The Target Binary Program
TARGET := $(ADF_DIR)/main

# Generic rule to assemble a 68k asm source file (../src/*.cpp) into an object file (*.o)
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s $(ASM)
#	@echo '(${ASM}) Assembling source file: $<'
	$(ASM) $(ASM_ARGS) -o "$@" "$<"

# Link executable
$(TARGET): $(LD) $(RAW_ASSETS) $(BUILD_DIR) $(MAIN_OBJ) $(OBJS)
#	@echo '(${LD}) Linking target: $@'
	$(LD) $(LINK_ARGS) -o "$@" $(MAIN_OBJ) $(OBJS)
	@echo 'Finished linking target: $@'

# Directories
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# RAW assets
$(RAW_ASSETS):
	@./scripts/convert_assets_to_raw.sh -x -p -r -s -i $(PALETTE_DIR)

# TOOLS - vasm
$(ASM): $(VASM_DIR)
	@echo 'Building vasmm68k_mot in $(VASM_DIR)...'
	$(MAKE) -C $(VASM_DIR) CPU=m68k SYNTAX=mot

$(VASM_DIR):
	@echo 'Extracting vasm source into $(VASM_DIR)...'
	@tar xf $(TOOLS_DIR)/vasm.tar.gz -C $(TOOLS_DIR)

# TOOLS - vlink
$(LD): $(VLINK_DIR)
	@echo 'Building vlink in $(VLINK_DIR)...'
	$(MAKE) -C $(VLINK_DIR)

$(VLINK_DIR):
	@echo 'Extracting vlink source into $(VLINK_DIR)...'
	@tar xf $(TOOLS_DIR)/vlink.tar.gz -C $(TOOLS_DIR)

all: $(TARGET)

tools: $(ASM) $(LD)

assets: $(RAW_ASSETS)

ADF_FILE := amiga_demo.adf
ADF_VOLUME_NAME := 'Amiga Demo'
XDF_TOOL := xdftool

adf: clean_adf $(TARGET)
	$(XDF_TOOL) $(ADF_FILE) create
	$(XDF_TOOL) $(ADF_FILE) format $(ADF_VOLUME_NAME)
	$(XDF_TOOL) $(ADF_FILE) boot install boot1x
	$(XDF_TOOL) $(ADF_FILE) write $(ADF_DIR)/main
	$(XDF_TOOL) $(ADF_FILE) write $(ADF_DIR)/s
	$(XDF_TOOL) $(ADF_FILE) list

clean_adf:
	@rm -f $(ADF_FILE)

# clean CODE and ADF only
clean: clean_adf
	@rm -rf $(BUILD_DIR)
	@rm -f $(TARGET)

# clean TOOLS only
clean_tools:
	@rm -rf $(VASM_DIR)
	@rm -rf $(VLINK_DIR)

# clean converted ASSETS only
clean_assets:
	@rm -f $(PALETTE_DIR)/*_palette.i
	@rm -f $(ASSETS_DIR)/*.png
	@rm -f $(ASSETS_DIR)/*.iff
	@rm -f $(ASSETS_DIR)/*.raw

# clean EVERYTHING
clean_all: clean clean_tools clean_assets clean_adf

#Non-File Targets
.PHONY: adf all assets clean clean_tools clean_assets clean_all
