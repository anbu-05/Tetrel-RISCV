CC      = riscv64-unknown-elf-gcc
OBJCOPY = riscv64-unknown-elf-objcopy

CFLAGS = -march=rv32im -mabi=ilp32 -nostdlib -I src

FILE   ?= smoke_test

SRC    = src/$(FILE).c
ASM    = asm/start.s
LINKER = linker.ld

ELF    = build/$(FILE).elf
HEX    = hex/$(FILE).hex

all: $(HEX)

$(HEX): $(ELF)
	mkdir -p hex
	$(OBJCOPY) -O verilog --verilog-data-width=4 $(ELF) $(HEX)
	awk '/^@/{print; next} {for(i=1;i<=NF;i++) print $$i}' $(HEX) > $(HEX).tmp
	mv $(HEX).tmp $(HEX)

$(ELF): $(SRC) $(ASM) $(LINKER)
	mkdir -p build
	$(CC) $(CFLAGS) -T $(LINKER) -o $(ELF) $(ASM) $(SRC)

clean:
	rm -f $(ELF) $(HEX)

.PHONY: all clean