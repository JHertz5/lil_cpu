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

  -- Calculate ceiling(log2(x)). Useful for bit widths.
  function clog2 (
    i_arg : positive
  ) return natural;

end package;

package body lil_cpu_pkg is

  function clog2 (
    i_arg : positive
  ) return natural is
  begin

    return integer(ceil(log2(real(i_arg))));

  end function;

end package body;
