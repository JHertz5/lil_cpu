------------------------------------------------------------------------------------------------------------------------
-- RAM module for data and instruction storage.
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library lil_cpu_lib;
  use lil_cpu_lib.lil_cpu_pkg.all;

entity ram is
  generic (
    g_init : t_ram := (others => (others => '0'))
  );
  port (
    i_clk    : in  std_logic;
    i_wr_rdn : in  std_logic;
    i_addr   : in  t_addr;
    i_data   : in  t_bus_data;
    o_data   : out t_bus_data
  );
end entity;

architecture rtl of ram is

  signal ram_internal : t_ram := g_init;

begin

  proc_reg : process(i_clk)

    variable v_addr_int : natural range t_ram'range;

  begin
    if rising_edge(i_clk) then

      v_addr_int := to_integer(i_addr);

      -- Read data from the RAM.
      if i_wr_rdn = '0' then
        o_data <= ram_internal(v_addr_int);
      else
        ram_internal(v_addr_int) <= i_data;
      end if;

    end if;
  end process;

end architecture;
