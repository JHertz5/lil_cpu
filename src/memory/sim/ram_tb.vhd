------------------------------------------------------------------------------------------------------------------------
-- Testbench for the reg module.
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library vunit_lib;
  context vunit_lib.vunit_context;

library lil_cpu_lib;
  use lil_cpu_lib.common_tb_pkg.all;
  use lil_cpu_lib.lil_cpu_pkg.all;

entity ram_tb is
  generic (
    runner_cfg : runner_cfg_t := runner_cfg_default
  );
end entity;

architecture tb of ram_tb is

  -- DUT signals.
  signal dut_i_clk       : std_logic := '0';
  signal dut_i_wr_rdn : std_logic;
  signal dut_i_addr : t_addr;
  signal dut_i_data : t_bus_data;
  signal dut_o_data : t_bus_data;

  -- Generate a RAM data object full of randomised data.
  function generate_random_ram_contents return t_ram is
    variable v_random_data : t_bus_data;
    variable v_result : t_ram;
  begin

    -- Generate random data for each RAM address.
    for lv_address in t_ram'range loop
      generate_random_slv(v_random_data);
      v_result(lv_address) := v_random_data;
    end loop;

    return v_result;

  end function;

  constant c_ram_init : t_ram := generate_random_ram_contents;


begin

  ----------------------------------------------------------------------------------------------------------------------
  -- Generate the clock.
  ----------------------------------------------------------------------------------------------------------------------

  dut_i_clk <= not dut_i_clk after c_clk_period / 2;

  ----------------------------------------------------------------------------------------------------------------------
  -- Instantiate the DUT.
  ----------------------------------------------------------------------------------------------------------------------

  cmp_dut : entity lil_cpu_lib.ram(rtl)
    generic map (
      g_init => c_ram_init
    )
    port map (
      i_clk       => dut_i_clk,
      i_wr_rdn => dut_i_wr_rdn,
      i_addr => dut_i_addr,
      i_data => dut_i_data,
      o_data => dut_o_data
    );

  ----------------------------------------------------------------------------------------------------------------------
  -- Test Sequencer.
  ----------------------------------------------------------------------------------------------------------------------

  proc_test_sequencer : process

    variable v_exp_ram : t_ram;

    constant c_data_test_name : string := "o_data";

    procedure check_ram_contents (
      i_expected : t_ram
    ) is
    begin

      dut_i_wr_rdn <= '0';
      -- Loop through the RAM, checking each address.
      for lv_address in t_ram'range loop
        dut_i_addr <= to_unsigned(lv_address, dut_i_addr'length);
        wait until rising_edge(dut_i_clk);
        check_slv(c_data_test_name, dut_o_data, i_expected(lv_address));
      end loop;

    end procedure;

    procedure write_ram_contents (
      i_ram_data : t_ram
    ) is
    begin

      dut_i_wr_rdn <= '1';
      -- Loop through the RAM, writing to each address.
      for lv_address in t_ram'range loop
        dut_i_data <= i_ram_data(lv_address);
        dut_i_addr <= to_unsigned(lv_address, dut_i_addr'length);
        wait until rising_edge(dut_i_clk);
      end loop;

    end procedure;

  begin

    -- Initialize inputs.
    dut_i_wr_rdn     <= '0';
    dut_i_addr      <= (others => '0');
    dut_i_data      <= (others => '0');

    test_runner_setup(runner, runner_cfg);
    set_stop_level(failure);

    while test_suite loop

      wait until rising_edge(dut_i_clk);

      -- Test initial RAM contents.
      if run("test_init") then
        check_ram_contents(c_ram_init);
      end if;

      -- Test write-read cycles.
      if run("test_write_read") then
        for lv_iteration in natural range 1 to 10 loop
          v_exp_ram := generate_random_ram_contents;
          write_ram_contents(v_exp_ram);
          wait until rising_edge(dut_i_clk);
          check_ram_contents(v_exp_ram);
        end loop;
      end if;

    end loop;

    test_runner_cleanup(runner);
  end process;

end architecture;
