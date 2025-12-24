[Paper summary RISC-V IoT](https://chatgpt.com/share/68be8587-12c0-8007-8855-b6c6606bafea)

---
- RavenSoC is a fabrication ready (ASIC) implementation of picoRV32
- the ravenSoC has poor documentation; and we're not able to find any videos/articles of it's implementation
- also, the RavenSoC is a full blown processor implementation; not a minimal microcontroller implementation like we want. trying to strip that down to a minimal microcontroller would be like trying to reduce a tree trunk into a single toothpick.


- there's this guy (grug huhler) on youtube who implemented a basic picoRV32 core on an FPGA: [Tang Nano 9K Simple PicoRV32-based SoC on FPGA](https://www.youtube.com/watch?v=cq7ETOCPIBM), playlist: [PicoRV32 Mini SoC - YouTube](https://www.youtube.com/playlist?list=PL7bIsDBNgNWsOMSPGQcaWWmu-4CNgrxn_)
- grug huhler's implementation has a video explanation, and even a playlist of doing different things using the fpga picoRV32 implementation
- he basically has implemented the picoRV32 core on an FPGA (tang nano 9k) -it is so basic it doesnt even have barrel shifters or hardware mul/div to keep the core as small and simple as possible.


- we could divide our work into parts
	- we first implement grug huhler's picoRV32 on DE2-115; as it is, without any changes
	- after implementation, we will work on example use cases to familiarize ourselves with the picoRV32 toolchain
	- after that we can split into two teams 
		- **backend** team that works on converting grug's FPGA design into an ASIC implementation
		- **frontend** team working on on modifying grug's design to be more simplified and focused towards our goal (ex: adding interrupt/UART/SPI etc.)
	- once both teams have achieved significant progress, we can combine the two works -by modifying the ASIC design 
- **PS:** 
	- we could get the tang nano 9k itself -it's only 4k https://amzn.in/d/f4M4bLN. we wont have to spend time making the transfer to DE2
	- we could even email him to get personal help
- future scope:
	- if we are following the paper and making the core IoT focused, we will need to look into making the core more than just minimal. we'll need to work on low power modes, security