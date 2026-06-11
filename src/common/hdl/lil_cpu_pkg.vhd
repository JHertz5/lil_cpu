------------------------------------------------------------------------------------------------------------------------
-- A package to carry common declarations used across all modules
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

package lil_cpu_pkg is

  -- Declarations for common signal types.
  constant c_bus_width  : natural := 8;
  constant c_addr_width : natural := 4;
  subtype  t_bus_data  is std_logic_vector(c_bus_width - 1 downto 0);
  subtype  t_addr is unsigned(c_addr_width - 1 downto 0);

  constant c_ram_depth : natural := c_addr_width ** 2;
  type     t_ram is array(c_ram_depth - 1 downto 0) of t_bus_data;

  -- Implement a bus transceiver. When not enabled, isolate the output from the input data, putting the output to
  -- high-impedance. When enabled, output the input data.
  function buffer_output_to_bus (
    i_en : std_logic;
    i_data : std_logic_vector
  ) return std_logic_vector;

  -- Calculate ceiling(log2(x)). Useful for bit widths.
  function clog2 (
    i_arg : positive
  ) return natural;

end package;

package body lil_cpu_pkg is

  function buffer_output_to_bus (
    i_en : std_logic;
    i_data : std_logic_vector
  ) return std_logic_vector is

    variable v_result : i_data'subtype;

  begin

    v_result := i_data when i_en else (others => 'Z');
    return v_result;

  end function;

  function clog2 (
    i_arg : positive
  ) return natural is
  begin

    return integer(ceil(log2(real(i_arg))));

  end function;

end package body;
