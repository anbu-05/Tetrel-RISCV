CC = riscv64-unknown-elf-gcc
OBJCOPY = riscv64-unknown-elf-objcopy

CFLAGS = -march=rv32imc -mabi=ilp32 -nostdlib

SRC     = src/smoke_test.c
ASM     = asm/start.S
LINKER  = linker.ld

ELF     = build/smoke_test.elf
HEX     = hex/smoke_test.hex

all: $(HEX)

$(HEX): $(ELF)
	$(OBJCOPY) -O verilog --verilog-data-width=4 $(ELF) $(HEX) && \
	awk '/^@/{print; next} {for(i=1;i<=NF;i++) print $i}' $(HEX) > $(HEX).tmp && \
	mv $(HEX).tmp $(HEX)

$(ELF): $(SRC) $(ASM) $(LINKER)
	mkdir -p build hex
	$(CC) $(CFLAGS) -T $(LINKER) -o $(ELF) $(ASM) $(SRC)

.PHONY: all