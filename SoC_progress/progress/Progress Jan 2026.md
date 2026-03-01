
i am making a new progress sheet for 2026, since the previous one got very cluttered
### Jan 5
we need to reimplement the AXI bus -a more honest version of AXI bus.
here's what im planning to do
currently the memory module has AXI built in
1. seperate the AXI implementation from memory module as an adapter
2. make two memory modules, one for RAM and the other for ROM
since im using a single cycle CPU, there's a lot of features that i dont need to support 

![[Pasted image 20260105120646.png]]

---
→ No two read/write FSMs. 
→ The 5 channels have their own always-ff (or comb) blocks. 
→ AR R AW W B 
→ we’ll ignore this for now, since it’s not implemented in the picoRV32. 
→ There are 4 registers: Read Address, Write Address, Write Data, Read Data 
→ The 5 blocks act independently. 
→ AR Block Does the valid-ready handshake and puts data in the read address register. 
→ R Block Does the valid-ready handshake & puts mem[read addr register] on read data register. → AW Block Does valid-ready HS & stores write address in write addr register 
→ W Block Does VP-HS & puts write data in mem[write addr register] 
→ B Block (NOT final) probably monitors W & AW blocks (probably using flags) & does its VR-HS

### Jan 6
i've made a new AXI adapter. now i just need to change back to memory simple mem and test if this works flawlessly
i have 2 hours to do the following
- implement new axi into memory, uart
- make GPIO module and implement axi in it
- write a bunch of test programs to show proof of testing.
the last part should be pretty easy using chatgpt. 

### Jan 7
the meeting got postponed to today
anyways, ive implemented the new axi intro memory but it's not working
im gonna write a bunch of test programs for the old core to show proof of testing now.

### Feb 24
im trying to fix axi4-lite reimplementation
in the process im finding out a lot of algorithmic issues
i need to get a notebook and start sketching stuff out. i need to look at my rtl circuit from a different perspective to understand what im trying to create
i need to map out this logic and look for logic loops. 

---
okay so, i dont have to reinvent the wheel. there's an axi adapter right there in picorv32. i just have to refer to it