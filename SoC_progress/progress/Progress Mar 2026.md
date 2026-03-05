### Mar 1
i successfully moved to linux, got it set up and running

moreover i went and spoke to Dr. Sivasankaran. he told me how the AXI "bus" isnt just wires, but could be more than just wires. he told something about an interconnect of sorts. this probably explains my mux dilemma. i always wondered why the axi protocol never spoke about the mux for taking input from multiple slaves. when i looked into it, it seemed like there shouldve been a block called the axi interconnect or something

this explained a lot of things. i dont just connect it as wires in the top block.

that aside. i also started using cadence xcelium. but there was an issue where i didnt have the license locally, because the server doesn't have git, and I have to copy paste the code to my laptop to upload on git

plus i also like my vscode niceties. but then i figured out how to fix this issue. there's this thing called sshfs. my laptop's ssh key is stored in vit server now, i dont have to type password to login to vit servers anymore, and the the server's folders appear as regular folders in my laptop

i did it using claude here: https://claude.ai/share/48383d32-bc21-4b00-90ea-e5984c463da3

i also briefly looked into verilator, about which i spoke on the claude chat, but with xcelium working flawlessly now, i can use that only