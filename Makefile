.PHONY: default all dirs

ASM := nasm

SRC_DIR   := src
BUILD_DIR := build

default: all

all: dirs $(BUILD_DIR)/main_floppy.img

dirs:
	[ -d $(BUILD_DIR) ] || mkdir -p $(BUILD_DIR) || true

$(BUILD_DIR)/main_floppy.img: $(BUILD_DIR)/main.o
	cp $(BUILD_DIR)/main.o $(BUILD_DIR)/main_floppy.img
	truncate -s 1440k $(BUILD_DIR)/main_floppy.img


$(BUILD_DIR)/main.o: $(SRC_DIR)/main.asm
	$(ASM) $(SRC_DIR)/main.asm -f bin -o $(BUILD_DIR)/main.o

