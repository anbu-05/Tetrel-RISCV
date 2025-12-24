- what the bootloader does:
	- it tells the CPU where the main program is
		- if it's a copy-to-SRAM, it copies the data from the SPI flash and puts it on the sram for the CPU to execute. we are probably not doing that since we are making a small uc. if it's this case, the external flash will need an address mapping 
		- we'll make an XIP, where the bootloader just tells where in the SPI flash the program is located. if it's this case, the SPI flash contains many things -bootloader, program code, data, the CPU needs, again, an address mapping to know where to find each part.
	- It gets the CPU ready to think straight.
		- At reset, every flip-flop, register, and flag in the CPU might be in a junk state (except those tied to reset)
		- it clears the status flags, disables interrupts, sets the stack pointer, sets up the interrupt vectors
	- It sets up the environment the program expects
		- The main firmware assumes a few things _just work_, like UART, timers, or even a console output.
		- The bootloader might:
			- Initialize the clock system (refer to the huge clock system in STM32s)
			- Set up memory mapping — telling the CPU which address range is SRAM, flash, MMIO, etc.
	- It decides _where_ to boot from
		- Some systems can boot from multiple places — UART, SD card, SPI flash, etc.  
		- The bootloader can: Detect what’s connected, Pick the right boot source, Fall back to another if one fails (like “if no flash, enter UART update mode”).
	- (only in very large SoCs) It can update or verify firmware

| Boot Method                                              | Implementation                                            | Example SoC |
| -------------------------------------------------------- | --------------------------------------------------------- | ----------- |
| Copy-to-SRAM + Hardware FSM                              | Simple FPGA softcores (e.g., some RISC-V FPGA demos)      |             |
| Copy-to-SRAM + Software BootROM                          | STM32, NXP i.MX (internal ROM routines)                   |             |
| XIP + Hardware FSM (SPI mapped as instruction memory)    | PicoSoC / PicoRV32                                        |             |
| XIP + Software BootROM (init controller, then map flash) | ESP32 (second-stage bootloader configures QSPI and cache) |             |