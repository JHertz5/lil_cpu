------------------------------------------------------------------------------------------------------------------------
-- Testbench for the program counter module.
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library vunit_lib;
  context vunit_lib.vunit_context;

library lil_cpu_lib;
  use lil_cpu_lib.common_tb_pkg.all;
  use lil_cpu_lib.lil_cpu_pkg.all;

entity counter_tb is
  generic (
    runner_cfg : runner_cfg_t := runner_cfg_default
  );
end entity;

architecture tb of counter_tb is

  -- DUT signals.
  signal dut_i_clk      : std_logic := '0';
  signal dut_i_reset    : std_logic;
  signal dut_i_count_en : std_logic;
  signal dut_o_count     : t_addr;

begin

  ----------------------------------------------------------------------------------------------------------------------
  -- Generate the clock.
  ----------------------------------------------------------------------------------------------------------------------

  dut_i_clk <= not dut_i_clk after c_clk_period / 2;

  ----------------------------------------------------------------------------------------------------------------------
  -- Instantiate the DUT.
  ----------------------------------------------------------------------------------------------------------------------

  cmp_dut : entity lil_cpu_lib.counter(rtl)
    port map (
      i_clk      => dut_i_clk,
      i_reset    => dut_i_reset,
      i_count_en => dut_i_count_en,
      o_count    => dut_o_count
    );

  ----------------------------------------------------------------------------------------------------------------------
  -- Test Sequencer.
  ----------------------------------------------------------------------------------------------------------------------

  proc_test_sequencer : process

    variable v_exp_count : t_addr;

    constant c_count_test_name : string := "o_count";

    -- Reset the register.
    procedure trigger_reset is
    begin

      dut_i_reset <= '1';
      wait until rising_edge(dut_i_clk);
      dut_i_reset <= '0';

    end procedure;

  begin

    -- Initialize inputs.
    dut_i_reset    <= '0';
    dut_i_count_en <= '0';

    test_runner_setup(runner, runner_cfg);
    set_stop_level(failure);

    while test_suite loop

      wait until rising_edge(dut_i_clk);

      -- Test reset clears register to zero.
      if run("test_reset") then
        wait until rising_edge(dut_i_clk);
        check_unsigned(c_count_test_name, dut_o_count, (dut_o_count'range => 'U'));
        v_exp_count     := x"0";
        trigger_reset;
        check_unsigned(c_count_test_name, dut_o_count, v_exp_count);
        dut_i_count_en <= '1';
        wait until rising_edge(dut_i_clk);
        trigger_reset;
        check_unsigned(c_count_test_name, dut_o_count, v_exp_count);
      end if;

      -- Test count increments on rising edge when count is enabled.
      if run("test_count_en") then
        trigger_reset;
        dut_i_count_en <= '1';
        for lv_iteration in natural range 1 to 10 loop
          wait until rising_edge(dut_i_clk);
          v_exp_count := to_unsigned(lv_iteration, dut_o_count'length);
          check_unsigned(c_count_test_name, dut_o_count, v_exp_count);
        end loop;
      end if;

      -- Test register holds data when count is disabled.
      if run("test_count_disabled_holds_count") then
        trigger_reset;
        dut_i_count_en <= '1';
        v_exp_count     := x"0";
        check_unsigned(c_count_test_name, dut_o_count, v_exp_count);
        wait until rising_edge(dut_i_clk);
        v_exp_count     := x"1";
        dut_i_count_en <= '0';
        -- Wait multiple cycles with count disabled.
        for lv_iteration in natural range 1 to 10 loop
          wait until rising_edge(dut_i_clk);
          check_unsigned(c_count_test_name, dut_o_count, v_exp_count);
        end loop;
      end if;

    end loop;

    test_runner_cleanup(runner);
  end process;

end architecture;
