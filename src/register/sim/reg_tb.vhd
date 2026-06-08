------------------------------------------------------------------------------------------------------------------------
-- Testbench for reg module.
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library vunit_lib;
  context vunit_lib.vunit_context;

library lil_cpu;
  use lil_cpu.common_tb_pkg.all;
  use lil_cpu.reg_tb_pkg.all;
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
  signal dut_i_input_en  : std_logic;
  signal dut_i_output_en : std_logic;
  signal dut_i_data      : t_bus_data;
  signal dut_o_data      : t_bus_data;

  -- Inter-process communication signals.
  signal stimuli_cmd   : t_stimuli_cmd := CMD_IDLE;
  signal stimuli_param : t_bus_data    := (others => '0');
  signal stimuli_ack   : std_logic     := '0';

  signal check_cmd   : t_check_cmd  := CMD_IDLE;
  signal check_param : t_bus_data   := (others => '0');
  signal check_ack   : std_logic    := '0';

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
      i_input_en  => dut_i_input_en,
      i_output_en => dut_i_output_en,
      i_data      => dut_i_data,
      o_data      => dut_o_data
    );

  ----------------------------------------------------------------------------------------------------------------------
  -- Drive inputs based on commands from sequencer.
  ----------------------------------------------------------------------------------------------------------------------

  proc_stimulus : process
  begin
    -- Initialize inputs
    dut_i_reset     <= '0';
    dut_i_input_en  <= '0';
    dut_i_output_en <= '0';
    dut_i_data      <= (others => '0');

    loop
      wait until stimuli_cmd /= CMD_IDLE or rising_edge(dut_i_clk);

      case stimuli_cmd is

        when CMD_IDLE =>
          null;

        when CMD_RESET =>
          dut_i_reset <= '1';
          wait until rising_edge(dut_i_clk);
          dut_i_reset <= '0';

        when CMD_LOAD_DATA =>
          dut_i_data     <= stimuli_param;
          dut_i_input_en <= '1';
          wait until rising_edge(dut_i_clk);
          dut_i_input_en <= '0';
          dut_i_data     <= (others => '0');

        when CMD_SET_OUTPUT_EN =>
          dut_i_output_en <= '1';

        when CMD_SET_OUTPUT_DIS =>
          dut_i_output_en <= '0';

        when CMD_WAIT_CYCLE =>
          wait until rising_edge(dut_i_clk);

      end case;

      -- End by acknowledging that the stimulus command has been completed.
      if stimuli_cmd /= CMD_IDLE then
          stimuli_ack <= '1';
          wait until rising_edge(dut_i_clk);
          stimuli_ack <= '0';
      end if;

    end loop;
  end process;

  ----------------------------------------------------------------------------------------------------------------------
  -- Validate outputs based on commands from sequencer.
  ----------------------------------------------------------------------------------------------------------------------

  proc_checker : process
  begin

      wait until rising_edge(dut_i_clk);

      case check_cmd is

        when CMD_IDLE =>
          null;

        when CMD_VERIFY_OUTPUT =>
          check(dut_o_data = check_param, "o_data mismatch: got " & to_string(dut_o_data) & ", expected " & to_string(check_param));
          check_ack <= '1';
          wait until rising_edge(dut_i_clk);
          check_ack <= '0';

        when CMD_VERIFY_HIGHZ =>
          check(dut_o_data = (dut_o_data'range => 'Z'), "o_data should be high-Z, got " & to_string(dut_o_data));
          check_ack <= '1';
          wait until rising_edge(dut_i_clk);
          check_ack <= '0';

      end case;

  end process;

  ----------------------------------------------------------------------------------------------------------------------
  -- Test Sequencer.
  ----------------------------------------------------------------------------------------------------------------------

  proc_test_sequencer : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop

      wait until rising_edge(dut_i_clk);

      -- Test 1: Reset clears register to zero.
      if run("test_reset") then
        info("Running test_reset");
        load_register(stimuli_ack, x"AA", stimuli_cmd, stimuli_param);
        wait_clock_cycle(stimuli_ack, stimuli_cmd);
        set_output_enabled(stimuli_ack, stimuli_cmd);
        verify_output(check_ack, x"AA", check_cmd, check_param);
        trigger_reset(stimuli_ack, stimuli_cmd);
        verify_output(check_ack, x"00", check_cmd, check_param);
      end if;

      -- Test 2: Data latches on rising edge when input enabled.
      if run("test_input_latching") then
        info("Running test_input_latching");
        trigger_reset(stimuli_ack, stimuli_cmd);
        load_register(stimuli_ack, x"55", stimuli_cmd, stimuli_param);
        set_output_enabled(stimuli_ack, stimuli_cmd);
        verify_output(check_ack, x"55", check_cmd, check_param);
        load_register(stimuli_ack, x"AA", stimuli_cmd, stimuli_param);
        verify_output(check_ack, x"AA", check_cmd, check_param);
      end if;

      -- Test 3: Output is high-Z when output disabled.
      if run("test_output_disabled_highz") then
        info("Running test_output_disabled_highz");
        trigger_reset(stimuli_ack, stimuli_cmd);
        load_register(stimuli_ack, x"CC", stimuli_cmd, stimuli_param);
        set_output_disabled(stimuli_ack, stimuli_cmd);
        verify_highz(check_ack, check_cmd);
      end if;

      -- Test 4: Output reflects internal data when enabled.
      if run("test_output_enabled") then
        info("Running test_output_enabled");
        trigger_reset(stimuli_ack, stimuli_cmd);
        load_register(stimuli_ack, x"DD", stimuli_cmd, stimuli_param);
        set_output_enabled(stimuli_ack, stimuli_cmd);
        verify_output(check_ack, x"DD", check_cmd, check_param);
      end if;

      -- Test 5: Register holds data when input disabled.
      if run("test_input_disabled_holds_data") then
        info("Running test_input_disabled_holds_data");
        trigger_reset(stimuli_ack, stimuli_cmd);
        load_register(stimuli_ack, x"77", stimuli_cmd, stimuli_param);
        set_output_enabled(stimuli_ack, stimuli_cmd);
        verify_output(check_ack, x"77", check_cmd, check_param);
        -- Wait multiple cycles without loading new data.
        wait_clock_cycle(stimuli_ack, stimuli_cmd);
        verify_output(check_ack, x"77", check_cmd, check_param);
        wait_clock_cycle(stimuli_ack, stimuli_cmd);
        verify_output(check_ack, x"77", check_cmd, check_param);
      end if;

      -- Test 6: Sequential operations.
      if run("test_sequential_operations") then
        info("Running test_sequential_operations");
        trigger_reset(stimuli_ack, stimuli_cmd);
        load_register(stimuli_ack, x"11", stimuli_cmd, stimuli_param);
        set_output_enabled(stimuli_ack, stimuli_cmd);
        verify_output(check_ack, x"11", check_cmd, check_param);
        set_output_disabled(stimuli_ack, stimuli_cmd);
        verify_highz(check_ack, check_cmd);
        set_output_enabled(stimuli_ack, stimuli_cmd);
        verify_output(check_ack, x"11", check_cmd, check_param);
        load_register(stimuli_ack, x"22", stimuli_cmd, stimuli_param);
        verify_output(check_ack, x"22", check_cmd, check_param);
      end if;

      -- Test 7: Simultaneous input and output.
      if run("test_simultaneous_input_output") then
        info("Running test_simultaneous_input_output");
        trigger_reset(stimuli_ack, stimuli_cmd);
        load_register(stimuli_ack, x"FF", stimuli_cmd, stimuli_param);
        set_output_enabled(stimuli_ack, stimuli_cmd);
        verify_output(check_ack, x"FF", check_cmd, check_param);
        -- Load new value while output is enabled.
        load_register(stimuli_ack, x"88", stimuli_cmd, stimuli_param);
        -- Output should now reflect new value.
        verify_output(check_ack, x"88", check_cmd, check_param);
      end if;

    end loop;

    test_runner_cleanup(runner);
  end process;

end architecture;
