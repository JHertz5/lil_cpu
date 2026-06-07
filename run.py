#!/usr/bin/env python3.
"""
VUnit test runner for lil_cpu project.
"""

from pathlib import Path
from vunit import VUnit

# Get the directory where this script is located (project root).
ROOT_DIR = Path(__file__).parent

# Create VUnit instance with VHDL-2008 standard.
vu = VUnit.from_argv(
    vhdl_standard="2008"
)
vu.add_vhdl_builtins()

# Create the lil_cpu library.
lib = vu.add_library("lil_cpu")

# Add HDL files.
lib.add_source_files(ROOT_DIR / "src" / "*" / "hdl" / "*.vhd")
# Add testbench files.
lib.add_source_files(ROOT_DIR / "src" / "*" / "sim" / "*.vhd")

# Add test configurations (optional: test with different generic values).
# By default, g_is_instruction_reg is false. Uncomment below to add a configuration with it set to true.
# tb_file.add_vhdl_compile_option("--generic g_is_instruction_reg=true")

# Run the test suite.
vu.main()
