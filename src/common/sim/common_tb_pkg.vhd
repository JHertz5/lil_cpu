------------------------------------------------------------------------------------------------------------------------
-- A package to hold definitions common across testbenches.
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

library vunit_lib;
  context vunit_lib.vunit_context;

package common_tb_pkg is

  constant c_clk_period : time := 1 ns;

  -- Generate a random std_logic_vector.
  procedure generate_random_slv (
    variable o_result : out std_logic_vector
  );

  -- Check the expected result against the actual.
  procedure check_slv (
    i_name     : in  string;
    i_actual   : in  std_logic_vector;
    i_expected : in  std_logic_vector
  );

  -- Check the expected result against the actual.
  procedure check_unsigned (
    i_name     : in  string;
    i_actual   : in  unsigned;
    i_expected : in  unsigned
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

  procedure check_slv (
    i_name     : in  string;
    i_actual   : in  std_logic_vector;
    i_expected : in  std_logic_vector
  ) is

    -- Each iteration clears one delta cycle.
    constant c_num_delta_settling_iterations : natural := 32;

  begin

    -- Run a few 0 ns waits to settle the delta delays.
    for lv_iteration in natural range 1 to c_num_delta_settling_iterations loop
      wait for 0 ns;
    end loop;
    check(
      i_actual = i_expected,
      i_name & " mismatch: got 0x" & to_hstring(i_actual) & ", expected 0x" & to_hstring(i_expected)
    );

  end procedure;


  -- Check the expected result against the actual.
  procedure check_unsigned (
    i_name     : in  string;
    i_actual   : in  unsigned;
    i_expected : in  unsigned
  ) is begin

    check_slv(
      i_name => i_name,
      i_actual => std_logic_vector(i_actual),
      i_expected => std_logic_vector(i_expected)
    );

  end procedure;

end package body;
