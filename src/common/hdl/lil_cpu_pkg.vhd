------------------------------------------------------------------------------------------------------------------------
-- A package to carry common declarations used across all modules
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package lil_cpu_pkg is

  constant c_bus_width : natural := 8;
  subtype  t_bus_data is std_logic_vector(c_bus_width - 1 downto 0);

  --------------------------------------------------------------------------------------------------------------------
  -- Implement a bus transceiver. When not enabled, isolate the output from the input data, putting the output to
  -- high-impedance. When enabled, output the input data.
  --------------------------------------------------------------------------------------------------------------------
  function buffer_output_to_bus (
    i_en : std_logic;
    i_data : std_logic_vector
  ) return std_logic_vector;

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

end package body;
