#!/usr/bin/env python3
"""
VUnit test runner for lil_cpu project.
"""

from pathlib import Path
from vunit import VUnit

# Get the directory where this script is located (project root).
SRC_DIR = Path(__file__).parent.parent / "src"

# Create VUnit instance with VHDL-2008 standard.
vu = VUnit.from_argv(vhdl_standard="2008")
vu.add_vhdl_builtins()

# Create the lil_cpu library.
lib = vu.add_library("lil_cpu_lib")

# Add HDL files.
lib.add_source_files(SRC_DIR / "*" / "hdl" / "*.vhd")
# Add testbench files.
lib.add_source_files(SRC_DIR / "*" / "sim" / "*.vhd")

# Add compile options for nvc.
lib.set_compile_option("nvc.a_flags", ["--relaxed"])
lib.set_sim_option("nvc.elab_flags", ["--no-collapse"])

cpu_tb = lib.test_bench("cpu_tb")
cpu_tb.set_generic("g_program_filename_base", str(SRC_DIR / "cpu" / "sim" / "test"))

# Run the test suite.
vu.main()
