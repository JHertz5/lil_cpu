------------------------------------------------------------------------------------------------------------------------
-- Testbench for reg module.
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library vunit_lib;
  context vunit_lib.vunit_context;

library lil_cpu;
  use lil_cpu.common_tb_pkg.all;
  use lil_cpu.lil_cpu_pkg.all;

entity reg_tb is
  generic (
    runner_cfg : runner_cfg_t := runner_cfg_default
  );
end entity;

architecture tb of reg_tb is

  -- DUT signals.
  signal dut_i_clk       : std_logic := '0';
  signal dut_i_reset     : std_logic;
  signal dut_i_load      : std_logic;
  signal dut_i_output_en : std_logic;
  signal dut_i_data      : t_bus_data;
  signal dut_o_data      : t_bus_data;

begin

  ----------------------------------------------------------------------------------------------------------------------
  -- Generate the clock.
  ----------------------------------------------------------------------------------------------------------------------

  dut_i_clk <= not dut_i_clk after c_clk_period / 2;

  ----------------------------------------------------------------------------------------------------------------------
  -- Instantiate the DUT.
  ----------------------------------------------------------------------------------------------------------------------

  cmp_dut : entity lil_cpu.reg(rtl)
    port map (
      i_clk       => dut_i_clk,
      i_reset     => dut_i_reset,
      i_load      => dut_i_load,
      i_output_en => dut_i_output_en,
      i_data      => dut_i_data,
      o_data      => dut_o_data
    );

  ----------------------------------------------------------------------------------------------------------------------
  -- Test Sequencer.
  ----------------------------------------------------------------------------------------------------------------------

  proc_test_sequencer : process

    variable v_exp_data : t_bus_data;

    -- Reset the register.
    procedure trigger_reset is
    begin

      dut_i_reset <= '1';
      wait until rising_edge(dut_i_clk);
      dut_i_reset <= '0';

    end procedure;

    -- Load new data into the register.
    procedure load_register (
      constant i_load_data : in  t_bus_data
    ) is
    begin

      dut_i_data <= i_load_data;
      dut_i_load <= '1';
      wait until rising_edge(dut_i_clk);
      dut_i_load <= '0';
      dut_i_data <= (others => '0');

    end procedure;

  begin

    -- Initialize inputs
    dut_i_reset     <= '0';
    dut_i_load      <= '0';
    dut_i_output_en <= '0';
    dut_i_data      <= (others => '0');

    test_runner_setup(runner, runner_cfg);

    while test_suite loop

      wait until rising_edge(dut_i_clk);

      -- Test 1: Reset clears register to zero.
      if run("test_reset") then
        info("Running test_reset");
        generate_random_slv(v_exp_data);
        load_register(v_exp_data);
        wait until rising_edge(dut_i_clk);
        dut_i_output_en <= '1';
        check_slv(dut_o_data, v_exp_data);
        trigger_reset;
        v_exp_data      := x"00";
        check_slv(dut_o_data, v_exp_data);
      end if;

      -- Test 2: Data latches on rising edge when load is enabled.
      if run("test_load") then
        info("Running test_load");
        trigger_reset;
        generate_random_slv(v_exp_data);
        load_register(v_exp_data);
        dut_i_output_en <= '1';
        check_slv(dut_o_data, v_exp_data);
        generate_random_slv(v_exp_data);
        load_register(v_exp_data);
        check_slv(dut_o_data, v_exp_data);
      end if;

      -- Test 3: Output is high-Z when output disabled.
      if run("test_output_disabled_highz") then
        info("Running test_output_disabled_highz");
        trigger_reset;
        generate_random_slv(v_exp_data);
        load_register(v_exp_data);
        dut_i_output_en <= '0';
        check_slv(dut_o_data, t_bus_data'(others => 'Z'));
      end if;

      -- Test 4: Output reflects internal data when enabled.
      if run("test_output_enabled") then
        info("Running test_output_enabled");
        trigger_reset;
        generate_random_slv(v_exp_data);
        load_register(v_exp_data);
        dut_i_output_en <= '1';
        check_slv(dut_o_data, v_exp_data);
      end if;

      -- Test 5: Register holds data when load disabled.
      if run("test_load_disabled_holds_data") then
        info("Running test_load_disabled_holds_data");
        trigger_reset;
        generate_random_slv(v_exp_data);
        load_register(v_exp_data);
        dut_i_output_en <= '1';
        check_slv(dut_o_data, v_exp_data);
        -- Wait multiple cycles without loading new data.
        for lv_iteration in natural range 1 to 10 loop
          wait until rising_edge(dut_i_clk);
          check_slv(dut_o_data, v_exp_data);
        end loop;
      end if;

      -- Test 6: Sequential operations.
      if run("test_sequential_operations") then
        info("Running test_sequential_operations");
        trigger_reset;
        generate_random_slv(v_exp_data);
        load_register(v_exp_data);
        dut_i_output_en <= '1';
        check_slv(dut_o_data, v_exp_data);
        dut_i_output_en <= '0';
        check_slv(dut_o_data, t_bus_data'(others => 'Z'));
        dut_i_output_en <= '1';
        check_slv(dut_o_data, v_exp_data);
        generate_random_slv(v_exp_data);
        load_register(v_exp_data);
        check_slv(dut_o_data, v_exp_data);
      end if;

      -- Test 7: Simultaneous input and output.
      if run("test_simultaneous_input_output") then
        info("Running test_simultaneous_input_output");
        trigger_reset;
        generate_random_slv(v_exp_data);
        load_register(v_exp_data);
        dut_i_output_en <= '1';
        check_slv(dut_o_data, v_exp_data);
        -- Load new value while output is enabled.
        generate_random_slv(v_exp_data);
        load_register(v_exp_data);
        -- Output should now reflect new value.
        check_slv(dut_o_data, v_exp_data);
      end if;

    end loop;

    test_runner_cleanup(runner);
  end process;

end architecture;
