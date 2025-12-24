- difference between packed array and unpacked array:
packed array:
- `bit [3:0] data` makes one 4 bit wide vector register:

|3|2|1|0|
|---|---|---|---|

- `bit [1:0][3:0] data` creates two 4 bit vector registers packed together as an 8 bit vector register:

| 1,3 | 1,2 | 1,1 | 1,0 | 0,3 | 0,2 | 0,1 | 0,0 |
| --- | --- | --- | --- | --- | --- | --- | --- |

unpacked array:
- `bit data [3:0]` creates four 1 bit wide vector registers

| 3   |
| --- |

| 2   |
| --- |

| 1   |
| --- |

| 0   |
| --- |
- `bit [3:0] data [1:0]` creates two 4 bit wide vector registers

| 1,3 | 1,2 | 1,1 | 1,0 |
| --- | --- | --- | --- |

| 0,3 | 0,2 | 0,1 | 0,0 |
| --- | --- | --- | --- |

### 29 april
- implemented load and store instructions
	- they need testing
- tried to use signal tap analyser
- inverted reset signal
- need to try bruteforce debug
### 30 april
- Imem was using an initial block and initial blocks are not syntesizable
- switched out tasks for define statements
---
- define statements are not synthesizable either
- trying to use readmemh and hex files
	- need to study about memory blocks in FPGAs
	- need to learn about MIF files
- need to test lw and sw functions


