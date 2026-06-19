------------------------------------------------------------------------------------------------------------------------
-- Testbench for the whole CPU.
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library std;
  use std.textio.all;

library vunit_lib;
  context vunit_lib.vunit_context;

library lil_cpu_lib;
  use lil_cpu_lib.common_tb_pkg.all;
  use lil_cpu_lib.lil_cpu_pkg.all;

entity cpu_tb is
  generic (
    runner_cfg : runner_cfg_t := runner_cfg_default;
    g_program_filename_base : string
  );
end entity;

architecture rtl of cpu_tb is

  -- DUT signals.
  signal dut_i_clk      : std_logic := '1';
  signal dut_o_data     : t_bus_data;
  signal dut_o_hlt     : std_logic;

  -- Read the program memory from a file.
  function get_program_memory(
    i_filename_base : string
  ) return t_ram is
    file mem_file : text open read_mode is i_filename_base & ".mem";
    variable v_hex_line : line;
    variable v_result : t_ram;
  begin

    for lv_addr in t_ram'low to t_ram'high loop
      readline(mem_file, v_hex_line);
      hread(v_hex_line, v_result(lv_addr));
    end loop;
    return v_result;
  end function;

  -- Read the expected data from a file.
  function get_program_expected_data(
    i_filename_base : string
  ) return t_bus_data is
    file exp_file : text open read_mode is i_filename_base & ".exp";
    variable v_hex_line : line;
    variable v_result : t_bus_data;
  begin

    readline(exp_file, v_hex_line);
    hread(v_hex_line, v_result);
    return v_result;

  end function;

  constant c_mem_init : t_ram := get_program_memory(g_program_filename_base);
  constant c_exp_data : t_bus_data := get_program_expected_data(g_program_filename_base);

begin

  ----------------------------------------------------------------------------------------------------------------------
  -- Generate the clock.
  ----------------------------------------------------------------------------------------------------------------------

  dut_i_clk <= not dut_i_clk after c_clk_period / 2;

  ----------------------------------------------------------------------------------------------------------------------
  -- Instantiate the DUT.
  ----------------------------------------------------------------------------------------------------------------------

  cmp_dut : entity lil_cpu_lib.cpu(rtl)
    generic map (
      g_mem_init => c_mem_init
    )
    port map (
      i_clk      => dut_i_clk,
      o_data     => dut_o_data,
      o_hlt     => dut_o_hlt
    );

  ----------------------------------------------------------------------------------------------------------------------
  -- Test Sequencer.
  ----------------------------------------------------------------------------------------------------------------------

  proc_test_sequencer : process

    constant c_data_test_name : string := "o_data";

    constant c_timeout : time := c_ram_depth * c_num_microinstruction_states * c_clk_period;

  begin

    test_runner_setup(runner, runner_cfg);
    set_stop_level(failure);

    while test_suite loop

      wait until rising_edge(dut_i_clk);

      -- Test initial RAM contents.
      if run("test_program") then

        -- Wait for the timeout to complete.
        wait until dut_o_hlt for c_timeout;

        -- Check that the timeout wasn't triggered.
        check_true(
          dut_o_hlt = '1',
          "Timed out while waiting for HLT to be asserted."
        );

        -- Check the output data.
        check_slv(c_data_test_name, dut_o_data, c_exp_data);

      end if;

    end loop;

    test_runner_cleanup(runner);
  end process;

end architecture;
