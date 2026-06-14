# Microinstructions

## Fetch Cycle
Every "macroinstruction", e.g. `LDA` is performed in steps called "microinstructions". The first two microinstructions are the same for every macroinstruction, referred to as the "Fetch Cycle", as the computer fetches the next instruction.

| Microinstruction Count | Description | Active Control Signals |
|---|---|---|
| 0 | Load the program count into the memory address | E<sub>P</sub>, L<sub>M</sub> |
| 1 | Increment the program counter and load the instruction from memory into control | C<sub>P</sub>, E<sub>M</sub>, L<sub>I</sub> |

From here, the different instructions diverge.

## LDA

| Microinstruction Count | Description | Active Control Signals |
|---|---|---|
| 2 | Load the operand into the memory address | E<sub>I</sub>, L<sub>M</sub> |
| 3 | Load the data from memory into Register A | E<sub>M</sub>, L<sub>A</sub> |
| 4 | None |  |

## ADD & SUB

| Microinstruction Count | Description | Active Control Signals |
|---|---|---|
| 2 | Load the operand into the memory address | E<sub>I</sub>, L<sub>M</sub> |
| 3 | Load the data from memory into Register B | E<sub>M</sub>, L<sub>B</sub> |
| 4 | Load the data from the ALU into Register A | E<sub>U</sub>, L<sub>A</sub>, (S<sub>U</sub> if SUB) |

## LOR

| Microinstruction Count | Description | Active Control Signals |
|---|---|---|
| 2 | Load the data from Register A into the Output Register | E<sub>A</sub>, L<sub>O</sub> |
| 3 | None |  |
| 4 | None |  |

## HLT

| Microinstruction Count | Description | Active Control Signals |
|---|---|---|
| 2 | Stop the counter |  |
| 3 | None |  |
| 4 | None |  |
