------------------------------------------------------------------------------------------------------------------------
-- Arithmetic Logic Unit. Avoiding numeric_std to make things interesting.
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library lil_cpu_lib;
  use lil_cpu_lib.lil_cpu_pkg.all;

entity alu is
  port (
    i_subtract_en : in  std_logic;
    i_output_en : in  std_logic;
    i_data_a      : in  t_bus_data;
    i_data_b      : in  t_bus_data;
    o_sum      : out t_bus_data
  );
end entity;

architecture rtl of alu is

  -- Data B after being potentially inverted.
  signal data_b_processed : t_bus_data;

  signal sum_internal : t_bus_data;

  ----------------------------------------------------------------------------------------------------------------------
  -- Calculate the sum of two values, with a carry in available.
  ----------------------------------------------------------------------------------------------------------------------
  function add (
    i_a : t_bus_data;
    i_b : t_bus_data;
    i_carry : std_logic
  ) return t_bus_data is

    variable v_carry : std_logic := i_carry;
    variable v_a_xor_b : std_logic;
    variable v_result : t_bus_data;

  begin

    for lv_bit in v_result'low to v_result'high loop
      v_a_xor_b := i_a(lv_bit) xor i_b(lv_bit);
      v_result(lv_bit) := v_a_xor_b xor v_carry;
      v_carry := (v_a_xor_b and v_carry) or (i_a(lv_bit) and i_b(lv_bit));
    end loop;

    return v_result;

  end function;

begin

  -- XOR to negate data B if subtracting.
  data_b_processed <= i_data_b xor i_subtract_en;
  -- 2's complement negation is invert and add 1, so add 1 to the inverted data B with the carry.
  sum_internal <= add(i_data_a, data_b_processed, i_subtract_en);

  -- Buffer the output data.
  o_sum <= buffer_output_to_bus(
      i_en   => i_output_en,
      i_data => sum_internal
    );

end architecture;
