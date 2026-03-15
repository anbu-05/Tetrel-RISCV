CC      = riscv64-unknown-elf-gcc
OBJCOPY = riscv64-unknown-elf-objcopy

CFLAGS = -march=rv32imc_zicsr -mabi=ilp32 -nostdlib -I src

ASM    = bootloader/start.s
LINKER = linker.ld

ELF    = build/program.elf
HEX    = hex/program.hex

# Assembly test files for instr_test
INSTR_TEST_ASM = src/asm/test_alu_reg.S    \
                 src/asm/test_alu_imm.S    \
                 src/asm/test_load.S       \
                 src/asm/test_store.S      \
                 src/asm/test_branch.S     \
                 src/asm/test_jump.S       \
                 src/asm/test_upper.S      \
                 src/asm/test_m.S          \
                 src/asm/test_c_alu.S      \
                 src/asm/test_c_loadstore.S \
                 src/asm/test_c_branch.S   \
                 src/asm/test_c_jump.S     \
                 src/asm/test_trap.S

# If no target given, show a usage message
default:
	@echo "Usage: make <filename_without_extension>"
	@echo "       make instr_test"

# Instruction unit test — links C file with all assembly test files
instr_test:
	@if [ -f .last_build ] && [ "$$(cat .last_build)" != "instr_test" ]; then \
		echo "Switching from $$(cat .last_build) to instr_test, cleaning..."; \
		rm -f $(ELF) $(HEX); \
	fi
	mkdir -p build hex
	$(CC) $(CFLAGS) -T $(LINKER) -o $(ELF) $(ASM) src/unit_test_instr.c $(INSTR_TEST_ASM)
	$(OBJCOPY) -O verilog --verilog-data-width=4 $(ELF) $(HEX)
	awk '/^@/{print; next} {for(i=1;i<=NF;i++) print $$i}' $(HEX) > $(HEX).tmp
	mv $(HEX).tmp $(HEX)
	@echo "instr_test" > .last_build

# Match any target that doesn't have a dot in it (e.g. make smoke_test)
%:
	@# Check if a different file was built last time
	@if [ -f .last_build ] && [ "$$(cat .last_build)" != "$@" ]; then \
		echo "Switching from $$(cat .last_build) to $@, cleaning..."; \
		rm -f $(ELF) $(HEX); \
	fi
	@# Build
	mkdir -p build hex
	$(CC) $(CFLAGS) -T $(LINKER) -o $(ELF) $(ASM) src/$@.c
	$(OBJCOPY) -O verilog --verilog-data-width=4 $(ELF) $(HEX)
	awk '/^@/{print; next} {for(i=1;i<=NF;i++) print $$i}' $(HEX) > $(HEX).tmp
	mv $(HEX).tmp $(HEX)
	@# Save what we just built
	@echo "$@" > .last_build

clean:
	rm -f $(ELF) $(HEX) .last_build

.PHONY: default clean instr_test