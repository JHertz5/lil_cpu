# lil_cpu
Yet another small VHDL CPU design. The goals of this project are to:
- remind myself about CPU architecture.
- experiment with open source tools.
- have a bit of fun.

The design is based on [Ben Eater's 8-bit computer](https://eater.net/8bit), which is a variant of the ["Simple-As-Possible"](https://en.wikipedia.org/wiki/Simple-As-Possible_computer) computer from the book Digital Computer Electronics by Albert Paul Malvino and Jerald A. Brown.

# Tasks
For each module, I'd like to do the following tasks.
[ ] Design - Ideally a diagram and some documentation before I start writing any code.
[ ] Implementation - The design coded up in VHDL.
[ ] Verification - A self-checking testbench to validate the operation of the module.

# Stretch Goals
- Run the CPU on real hardware (maybe [FOMU](https://www.crowdsupply.com/sutajio-kosagi/fomu) or [iCEBreaker](https://1bitsquared.com/products/icebreaker).
- Implement the [LC-3](https://en.wikipedia.org/wiki/Little_Computer_3) ISA.
- Implement a compiler from assembly to machine code.
