------------------------------------------------------------------------------------------------------------------------
-- Memory module, consisting of the Memory Address Register (MAR) and a Read-Only Memory.
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library lil_cpu_lib;
  use lil_cpu_lib.lil_cpu_pkg.all;

entity memory is
  generic (
    g_init : t_ram := (others => (others => '0'))
  );
  port (
    i_clk      : in  std_logic;
    i_load_mar : in  std_logic;
    i_addr     : in  t_addr;
    o_data     : out t_bus_data
  );
end entity;

architecture rtl of memory is

  signal mar_data : t_bus_data;
  signal mar_addr : t_addr;

begin

  -- Instantiate the Memory Address Register.
  cmp_memory_address_register : entity work.reg(rtl)
    port map (
      i_clk  => i_clk,
      i_load => i_load_mar,
      i_data => x"0" & std_logic_vector(i_addr),
      o_data => mar_data
    );

  -- Extract the address from the Memory Address Register data.
  mar_addr <= unsigned(mar_data(mar_addr'range));

  -- Instantiate the RAM. For this design, it is configured to be read-only.
  cmp_rom : entity work.ram(rtl)
    generic map (
      g_init => g_init
    )
    port map (
      i_clk    => i_clk,
      i_wr_rdn => '0',
      i_addr   => mar_addr,
      i_data   => (others => '0'),
      o_data   => o_data
    );

end architecture;
