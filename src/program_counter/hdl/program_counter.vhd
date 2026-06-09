------------------------------------------------------------------------------------------------------------------------
-- Program Counter. Keeps track of the instruction address.
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library lil_cpu_lib;
  use lil_cpu_lib.lil_cpu_pkg.all;

entity program_counter is
  port (
    i_clk       : in  std_logic;
    i_reset     : in  std_logic;
    i_count_en  : in  std_logic;
    i_output_en : in  std_logic;
    o_addr      : out t_addr
  );
end entity;

architecture rtl of program_counter is

  signal addr_internal : unsigned(t_addr'range) := (others => '0');

begin

  proc_reg : process(i_clk)
  begin
    if rising_edge(i_clk) then

      -- Reset the data or increment the count depending on control signals.
      if i_reset then
        addr_internal <= (others => '0');
      elsif i_count_en then
        addr_internal <= addr_internal + 1;
      end if;

    end if;
  end process;

  -- Buffer the output data.
  o_addr <= buffer_output_to_bus(
      i_en   => i_output_en,
      i_data => std_logic_vector(addr_internal)
    );

end architecture;
