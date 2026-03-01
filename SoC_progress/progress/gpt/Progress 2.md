
i am making a new progress sheet because the old one got too long. i think ill make a new progress sheet every month.
### Jan 5 (2026)
i need to reimplement axi on all the modules with a more honest and efficient implementation
here's the plan.
1. ill change simplemem to use picorv32's default memory signal wires.
2. ill make an honest axi adapter (with mux included), and add that adapter to simplemem.
this way we dont have only simplemem being a default AXI module.

the axi implementation ill have to do will be a lot less robust than an actual axi lite (ironic considering axi lite itself is only a less robust version of axi)
since picorv32 is a single cycle CPU, i dont need to support a lot of things with my bus

![[Pasted image 20260105113841.png]]