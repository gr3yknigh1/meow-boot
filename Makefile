.PHONY: default all dirs clean run

RM  := rm -rf
ASM := nasm
QEMU := qemu-system-x86_64

SRC_DIR   := source
BUILD_DIR := build

BOOT_FLOPPY_IMAGE := $(BUILD_DIR)/boot_floppy.img

default: all

all: dirs $(BOOT_FLOPPY_IMAGE)

dirs:
	[ -d $(BUILD_DIR) ] || mkdir -p $(BUILD_DIR) || true

$(BOOT_FLOPPY_IMAGE): $(BUILD_DIR)/boot.o
	cp $(BUILD_DIR)/boot.o $(BOOT_FLOPPY_IMAGE)
	truncate -s 1440k $(BOOT_FLOPPY_IMAGE)

$(BUILD_DIR)/boot.o: $(SRC_DIR)/boot.asm
	$(ASM) $^ -f bin -o $@

clean:
	$(RM) $(BUILD_DIR)

run: $(BOOT_FLOPPY_IMAGE)
	$(QEMU) $(BOOT_FLOPPY_IMAGE)
