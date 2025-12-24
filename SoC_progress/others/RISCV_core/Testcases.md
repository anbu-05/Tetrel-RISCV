#### ProgramCounter
1. Reset behavior
    - Assert `reset = 1` → PC should go to `0`.
    - Deassert reset → PC should resume operation.
2. Normal increment
    - With `enable = 1` and `jump = 0`, no jumps → PC increments by 4 each cycle.
3. Enable = 0 (stall)
    - PC should hold its value when `enable = 0`.
4. Jump
    - When `jump = 1`, PC should update as `pc_reg + (imm << 1)`.

advanced:
1. Negative `imm`
    - Since `imm` is signed, check that left shift works properly when `imm` is negative.
    - Example: if `imm = -2`, `(imm << 1) = -4`, so PC should subtract.
2. Jump + Stall interaction
    - Assert `jump = 1` but keep `enable = 0`.
    - Expected: PC should not move, even though a jump condition exists.
3. Multiple consecutive jumps
    - Set `jump = 1` for several cycles.
    - Verify it keeps accumulating `(imm << 1)` each cycle.
4. Reset during operation
    - While PC is mid-count (e.g., at `24`), assert reset.
    - Check PC snaps back to `0` immediately.
5. Boundary / wraparound
    - Drive PC near the 32-bit max (like `32'hFFFFFFFC`) and see what happens when incrementing.
    - Expected: it wraps around (overflow).
    - Even if you don’t need wraparound behavior, it’s good to know exactly what it does in simulation.
