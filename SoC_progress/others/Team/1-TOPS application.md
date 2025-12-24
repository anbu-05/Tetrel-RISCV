# first page
### team name: 
Tetrels
### SOP:
Our team is applying to the 1-TOPS program because the computing landscape is undergoing a clear architectural transition. Modern x86 processors, despite being based on a CISC ISA, already translate each instruction into simpler RISC-like micro-operations internally. ARM, the dominant commercial RISC architecture, remains proprietary and accessible only under strict licensing. This leaves a significant gap for an open, extensible, and community-driven ISA—precisely the space RISC-V now occupies.

The situation is similar to the transition from Unix to Linux. Unix systems were powerful but closed and fragmented. Linux emerged as an open alternative that allowed anyone to study, modify, and build on it. Over time, Linux became the foundation of modern computing. RISC-V represents that same opportunity for hardware: a path toward transparent, modifiable, and fully open processor design.

Our ongoing work involves developing a compact RV32IMC SoC, and participation in 1-TOPS would allow us to refine this effort within a structured environment. The motivation is not abstract; it is to position our work in alignment with the broader industry shift toward open hardware, rather than legacy architectures.

We aim to develop a functional and efficient SoC that can evolve into a platform for future academic use, experimentation, and eventual ASIC exploration. The 1-TOPS program provides the right technical direction to accelerate this transition and to ensure that our work aligns with modern architectural trends.

### Project Synopsis:
Our project focuses on building a compact and efficient RV32IMC System-on-Chip based on the PicoRV32 core. The ISA and core choice were inherited from the existing PicoRV32 implementation, which already provides a stable RV32IMC baseline and simplifies early-stage bring-up. The current SoC integrates on-chip SRAM and a UART module through an AXI4-Lite bus, and it is already capable of running programs.

The next steps include adding an AXI4-Lite crossbar and implementing a GPIO module to expand peripheral functionality. These components were also part of the original architecture of the PicoRV32 ecosystem, and incorporating them maintains consistency while enabling modular growth. Once the SoC is feature-complete, the team will proceed toward optimization—improving area, timing, memory efficiency, and evaluating ISA extensions.

A key advantage of establishing an early working prototype is parallelization. With a functional baseline in place, different members can focus on subsystems independently, such as interconnects, peripherals, verification, or firmware. This accelerates development while maintaining clarity in responsibilities.

Although the final application is still open, the current direction aligns with microcontroller-class SoCs. Depending on future extensions such as DSP units, potential applications include robotics control, sensor fusion, or embedded signal processing tasks.

# riscv team members

#1
- Anbu, anbuazhagudurai1@gmail.com, 6381348414
- B.Tech Electronics Engineering (VLSI Design and Technology), 5th semester, 7.52, 93.8% in 12th
- Physics of semiconductor devices, ElectroMagnetic field theory, Signal Processing, Digital Signal Design, Electronic Materials, Computer Architecture, vlsi System Design, Semiconductor Device Modeling, Design, CAD for IC Design, Testing Of vLsi circuits, Scripting Languages and verification

#2
- Gayam Lehana Reddy, lehana4984@gmail.com, 8688301094
- B.Tech Electronics Engineering (VLSI Design and Technology), 5th semester, 9.03, 98.2% in 12th
- Physics of semiconductor devices, ElectroMagnetic field theory, Signal Processing, Digital Signal Design, Electronic Materials, Computer Architecture, vlsi System Design, Semiconductor Device Modeling, ASIC Design, CAD for IC Design, Testing Of vLsi circuits

#3
- Rakshith Raj S, rakshithrajr@gmail.com, 9066528417
- Integrated MTech Software Engineering, 7th Semester, 8.7, 93% in 12th
- Foundations in electronics and electrical engineering, Digital logic microprocessors, System programming

#4
- Tanmay Karandikar , tankar2508@gmail.com, 9769584676
- B.Tech Electronics and Communication Engineering, 3rd semester, 9.01, 85.83% in 12th
- Digital System Design, Electronic Materials and Devices

#5
- Santosh Bala N , santoshAbala.n2024@vitstudent.ac.in , 9884515122
- B.Tech Computer Science Engineering Core , 3rd semester, 8.97 , 93% in 12th
- Digital System Design

#6
- Ruthvik Patro, ruthvik.patro2024@vitstudent.ac.in, 8897401503
- B.Tech Electronics and Communication Engineering, 3rd semester, 9.31, 94% in 12th
- Digital System Design, Electronic Materials and Devices

#7
- Abhrodwip Saha, abhrodwip.saha2024@vitstudent.ac.in, 9769861218
- B.Tech Electronics and Communication Engineering, 3rd semester, 9.78, 95.5% in 12th
- Digital System Design, Electronic Materials and Devices