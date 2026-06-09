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

entity program_counter_tb is
  generic (
    runner_cfg : runner_cfg_t := runner_cfg_default
  );
end entity;

architecture tb of program_counter_tb is

  -- DUT signals.
  signal dut_i_clk       : std_logic := '0';
  signal dut_i_reset     : std_logic;
  signal dut_i_count_en  : std_logic;
  signal dut_i_output_en : std_logic;
  signal dut_o_addr      : t_addr;

begin

  ----------------------------------------------------------------------------------------------------------------------
  -- Generate the clock.
  ----------------------------------------------------------------------------------------------------------------------

  dut_i_clk <= not dut_i_clk after c_clk_period / 2;

  ----------------------------------------------------------------------------------------------------------------------
  -- Instantiate the DUT.
  ----------------------------------------------------------------------------------------------------------------------

  cmp_dut : entity lil_cpu_lib.program_counter(rtl)
    port map (
      i_clk       => dut_i_clk,
      i_reset     => dut_i_reset,
      i_count_en  => dut_i_count_en,
      i_output_en => dut_i_output_en,
      o_addr      => dut_o_addr
    );

  ----------------------------------------------------------------------------------------------------------------------
  -- Test Sequencer.
  ----------------------------------------------------------------------------------------------------------------------

  proc_test_sequencer : process

    variable v_exp_addr : t_addr;

    constant c_addr_test_name : string := "o_addr";

    -- Reset the register.
    procedure trigger_reset is
    begin

      dut_i_reset <= '1';
      wait until rising_edge(dut_i_clk);
      dut_i_reset <= '0';

    end procedure;

  begin

    -- Initialize inputs.
    dut_i_reset     <= '0';
    dut_i_count_en  <= '0';
    dut_i_output_en <= '0';

    test_runner_setup(runner, runner_cfg);

    while test_suite loop

      wait until rising_edge(dut_i_clk);

      -- Test reset clears register to zero.
      if run("test_reset") then
        wait until rising_edge(dut_i_clk);
        dut_i_output_en <= '1';
        check_slv(c_addr_test_name, dut_o_addr, v_exp_addr);
        trigger_reset;
        v_exp_addr      := x"0";
        check_slv(c_addr_test_name, dut_o_addr, v_exp_addr);
        dut_i_count_en  <= '1';
        wait until rising_edge(dut_i_clk);
        trigger_reset;
        v_exp_addr      := x"0";
        check_slv(c_addr_test_name, dut_o_addr, v_exp_addr);
      end if;

      -- Test addr increments on rising edge when count is enabled.
      if run("test_count_en") then
        trigger_reset;
        dut_i_output_en <= '1';
        dut_i_count_en  <= '1';
        for lv_iteration in natural range 1 to 10 loop
          wait until rising_edge(dut_i_clk);
          v_exp_addr := std_logic_vector(to_unsigned(lv_iteration, t_addr'length));
          check_slv(c_addr_test_name, dut_o_addr, v_exp_addr);
        end loop;
      end if;

      -- Test output is high-Z when output disabled.
      if run("test_output_disabled_highz") then
        trigger_reset;
        dut_i_output_en <= '0';
        v_exp_addr      := (others => 'Z');
        check_slv(c_addr_test_name, dut_o_addr, v_exp_addr);
      end if;

      -- Test register holds data when count is disabled.
      if run("test_count_disabled_holds_count") then
        trigger_reset;
        dut_i_count_en  <= '1';
        dut_i_output_en <= '1';
        check_slv(c_addr_test_name, dut_o_addr, v_exp_addr);
        wait until rising_edge(dut_i_clk);
        v_exp_addr      := x"1";
        dut_i_count_en  <= '0';
        -- Wait multiple cycles with count disabled.
        for lv_iteration in natural range 1 to 10 loop
          wait until rising_edge(dut_i_clk);
          check_slv(c_addr_test_name, dut_o_addr, v_exp_addr);
        end loop;
      end if;

    end loop;

    test_runner_cleanup(runner);
  end process;

end architecture;
