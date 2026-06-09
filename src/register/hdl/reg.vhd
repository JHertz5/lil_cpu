------------------------------------------------------------------------------------------------------------------------
-- General purpose register. Can load data from the bus and output data to the bus.
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library lil_cpu_lib;
  use lil_cpu_lib.lil_cpu_pkg.all;

entity reg is
  generic (
    g_is_instruction_reg : boolean := false
  );
  port (
    i_clk       : in  std_logic;
    i_reset     : in  std_logic;
    i_load      : in  std_logic;
    i_output_en : in  std_logic;
    i_data      : in  t_bus_data;
    o_data      : out t_bus_data
  );
end entity;

architecture rtl of reg is

  signal data_internal : t_bus_data;

begin

  proc_reg : process(i_clk)
  begin
    if rising_edge(i_clk) then

      -- Reset the data or latch the incoming data depending on control signals.
      if i_reset then
        data_internal <= (others => '0');
      elsif i_load then
        data_internal <= i_data;
      end if;

    end if;
  end process;

  -- TODO #21 handle the instruction register.
  -- Buffer the output data.
  o_data <= buffer_output_to_bus(
      i_en   => i_output_en,
      i_data => data_internal
    );

end architecture;
