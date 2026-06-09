------------------------------------------------------------------------------------------------------------------------
-- Testbench for the ALU module.
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library vunit_lib;
  context vunit_lib.vunit_context;

library lil_cpu_lib;
  use lil_cpu_lib.common_tb_pkg.all;
  use lil_cpu_lib.lil_cpu_pkg.all;

entity alu_tb is
  generic (
    runner_cfg : runner_cfg_t := runner_cfg_default
  );
end entity;

architecture tb of alu_tb is

  -- DUT signals. Even thought the module is combinatorial, the clock is used for test sequencing.
  signal dut_i_clk       : std_logic := '0';
  signal dut_i_subtract_en : std_logic;
  signal dut_i_output_en : std_logic;
  signal dut_i_data_a : t_bus_data;
  signal dut_i_data_b : t_bus_data;
  signal dut_o_sum      : t_bus_data;

begin

  ----------------------------------------------------------------------------------------------------------------------
  -- Generate the clock.
  ----------------------------------------------------------------------------------------------------------------------

  dut_i_clk <= not dut_i_clk after c_clk_period / 2;

  ----------------------------------------------------------------------------------------------------------------------
  -- Instantiate the DUT.
  ----------------------------------------------------------------------------------------------------------------------

  cmp_dut : entity lil_cpu_lib.alu(rtl)
    port map (
      i_subtract_en => dut_i_subtract_en,
      i_output_en => dut_i_output_en,
      i_data_a => dut_i_data_a,
      i_data_b => dut_i_data_b,
      o_sum => dut_o_sum
    );

  ----------------------------------------------------------------------------------------------------------------------
  -- Test Sequencer.
  ----------------------------------------------------------------------------------------------------------------------

  proc_test_sequencer : process

    variable v_exp_sum : t_bus_data;

    constant c_sum_test_name : string := "o_sum";

    -- Test with random data inputs.
    procedure get_random_expected_data(
      i_subtract_en : in std_logic;
      o_sum : out t_bus_data
    )  is

      variable v_test_data_a : t_bus_data;
      variable v_test_data_b : t_bus_data;

    begin

      -- Generate inputs.
        generate_random_slv(v_test_data_a);
        dut_i_data_a <= v_test_data_a;
        generate_random_slv(v_test_data_b);
        dut_i_data_b <= v_test_data_b;

        -- Calculate result.
        o_sum :=
          std_logic_vector(signed(v_test_data_a) - signed(v_test_data_b)) when i_subtract_en else
          std_logic_vector(signed(v_test_data_a) + signed(v_test_data_b));

    end procedure;

  begin

    -- Initialize inputs.
    dut_i_subtract_en <= '0';
    dut_i_output_en <= '0';
    dut_i_data_a <= (others => '0');
    dut_i_data_b <= (others => '0');

    test_runner_setup(runner, runner_cfg);
    set_stop_level(failure);

    while test_suite loop

      wait until rising_edge(dut_i_clk);

      -- Test sum is correct when adding.
      if run("test_add") then
        dut_i_output_en <= '1';
        dut_i_subtract_en <= '0';
        for lv_iteration in natural range 1 to 10 loop
          wait until rising_edge(dut_i_clk);
          get_random_expected_data(dut_i_subtract_en, v_exp_sum);
          check_slv(c_sum_test_name, dut_o_sum, v_exp_sum);
        end loop;
      end if;

      -- Test sum is correct when subtracting.
      if run("test_sub") then
        dut_i_output_en <= '1';
        dut_i_subtract_en <= '1';
        for lv_iteration in natural range 1 to 10 loop
          wait until rising_edge(dut_i_clk);
          get_random_expected_data(dut_i_subtract_en, v_exp_sum);
          check_slv(c_sum_test_name, dut_o_sum, v_exp_sum);
        end loop;
      end if;

      -- Test output is high-Z when output disabled.
      if run("test_output_disabled_highz") then
        get_random_expected_data('-', v_exp_sum);
        dut_i_output_en <= '0';
        v_exp_sum      := (others => 'Z');
        check_slv(c_sum_test_name, dut_o_sum, v_exp_sum);
      end if;

      -- Test zero input.
      if run("test_zero_input") then
        dut_i_data_a <= (others => '0');
        dut_i_data_b <= (others => '0');
        dut_i_output_en <= '1';
        v_exp_sum      := (others => '0');
        dut_i_subtract_en <= '0';
        check_slv(c_sum_test_name, dut_o_sum, v_exp_sum);
        dut_i_subtract_en <= '1';
        check_slv(c_sum_test_name, dut_o_sum, v_exp_sum);
      end if;

    end loop;

    test_runner_cleanup(runner);
  end process;

end architecture;
