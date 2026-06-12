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
    o_addr      : out t_addr
  );
end entity;

architecture rtl of program_counter is

begin

  proc_reg : process(i_clk)
  begin
    if rising_edge(i_clk) then

      -- Reset the data or increment the count depending on control signals.
      if i_reset then
        o_addr <= (others => '0');
      elsif i_count_en then
        o_addr <= o_addr + 1;
      end if;

    end if;
  end process;

end architecture;
