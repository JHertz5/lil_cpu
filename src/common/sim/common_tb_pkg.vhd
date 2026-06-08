------------------------------------------------------------------------------------------------------------------------
-- A package to hold definitions common across testbenches.
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.math_real.all;

library vunit_lib;
  context vunit_lib.vunit_context;

package common_tb_pkg is

  constant c_clk_period : time := 1 ns;

  ----------------------------------------------------------------------------------------------------------------------
  -- Generate a random std_logic_vector.
  ----------------------------------------------------------------------------------------------------------------------
  procedure generate_random_slv (
    variable o_result : out std_logic_vector
  );

  ----------------------------------------------------------------------------------------------------------------------
  -- Check the expected result against the actual.
  ----------------------------------------------------------------------------------------------------------------------
  procedure verify_output (
    i_actual   : in  std_logic_vector;
    i_expected : in  std_logic_vector
  );

end package;

package body common_tb_pkg is

  shared variable v_seed1 : integer := 1;
  shared variable v_seed2 : integer := 1;

  procedure generate_random_slv (
    variable o_result : out std_logic_vector
  ) is

    variable v_random_real : real;

  begin

    for lv_bit in o_result'range loop
      uniform(v_seed1, v_seed2, v_random_real);
      o_result(lv_bit) := '1' when v_random_real >= 0.5 else '0';
    end loop;

  end procedure;

  procedure verify_output (
    i_actual   : in  std_logic_vector;
    i_expected : in  std_logic_vector
  ) is

    constant c_msg : string := "o_data mismatch: got " & to_string(i_actual) & ", expected " & to_string(i_expected);

  begin

    check((i_actual = i_expected), c_msg);

  end procedure;

end package body;
