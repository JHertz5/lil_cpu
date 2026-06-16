------------------------------------------------------------------------------------------------------------------------
-- Testbench for the control module.
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library vunit_lib;
  context vunit_lib.vunit_context;

library lil_cpu_lib;
  use lil_cpu_lib.common_tb_pkg.all;
  use lil_cpu_lib.lil_cpu_pkg.all;

entity control_tb is
  generic (
    runner_cfg : runner_cfg_t := runner_cfg_default
  );
end entity;

architecture tb of control_tb is

  -- DUT signals.
  signal dut_i_clk                  : std_logic := '0';
  signal dut_i_load_instruction_reg : std_logic;
  signal dut_i_instruction          : t_bus_data;
  signal dut_o_operand              : t_bus_data;
  signal dut_o_control_word         : t_control_word;

begin

  ----------------------------------------------------------------------------------------------------------------------
  -- Generate the clock.
  ----------------------------------------------------------------------------------------------------------------------

  dut_i_clk <= not dut_i_clk after c_clk_period / 2;

  ----------------------------------------------------------------------------------------------------------------------
  -- Instantiate the DUT.
  ----------------------------------------------------------------------------------------------------------------------

  cmp_dut : entity lil_cpu_lib.control(rtl)
    port map (
      i_clk                  => dut_i_clk,
      i_load_instruction_reg => dut_i_load_instruction_reg,
      i_instruction          => dut_i_instruction,
      o_operand              => dut_o_operand,
      o_control_word         => dut_o_control_word
    );

  ----------------------------------------------------------------------------------------------------------------------
  -- Test Sequencer.
  ----------------------------------------------------------------------------------------------------------------------

  proc_test_sequencer : process

    variable v_instruction      : t_bus_data;
    variable v_exp_operand      : t_bus_data;
    variable v_exp_control_word : t_control_word;

    constant c_operand_test_name      : string := "o_operand";
    constant c_control_word_test_name : string := "o_control_word";

    -- Load an instruction into the instruction register.
    procedure load_instruction (
      i_instruction : in t_bus_data
    ) is
    begin

      dut_i_instruction          <= i_instruction;
      dut_i_load_instruction_reg <= '1';
      wait until rising_edge(dut_i_clk);
      dut_i_load_instruction_reg <= '0';

    end procedure;

    -- Extract the operand from an instruction.
    function extract_operand (
      i_instruction : in t_bus_data
    ) return t_bus_data is

      variable v_operand : t_bus_data;

    begin

      v_operand := x"0" & i_instruction(t_addr'range);
      return v_operand;

    end function;

    -- Check a control word against an expected result.
    procedure check_control_word (
      constant i_expected : t_control_word
    ) is
    begin

      -- Run a few 0 ns waits to settle the delta delays.
      for lv_iteration in natural range 1 to c_num_delta_settling_iterations loop
        wait for 0 ns;
      end loop;

      for lv_control_signal in t_control_signal loop
        check_std_logic(
          i_name     => c_control_word_test_name & "(" & to_string(lv_control_signal) &  ")",
          i_actual   => dut_o_control_word(lv_control_signal),
          i_expected => i_expected(lv_control_signal)
        );
      end loop;

    end procedure;

    procedure check_fetch_cycle is
    begin

      -- Check that the Program Counter is loaded into Memory.
      v_exp_control_word := (
        EN_PC => '1',
        LOAD_MEM => '1',
        others => '0'
      );
      check_control_word(v_exp_control_word);
      wait until rising_edge(dut_i_clk);

      dut_i_instruction          <= v_instruction;
      dut_i_load_instruction_reg <= '1';

      -- Check that Memory data is loaded into the Instruction Register.
      v_exp_control_word := (
        EN_MEM => '1',
        LOAD_IR => '1',
        COUNT_PC => '1',
        others => '0'
      );
      check_control_word(v_exp_control_word);
      wait until rising_edge(dut_i_clk);

    end procedure;

  begin

    -- Initialize inputs.
    dut_i_load_instruction_reg <= '0';
    dut_i_instruction          <= (others => '0');

    test_runner_setup(runner, runner_cfg);
    set_stop_level(failure);

    while test_suite loop

      -- Test instruction can be loaded and operand is extracted correctly.
      if run("test_load_instruction") then
        v_instruction := x"AB";
        v_exp_operand := extract_operand(v_instruction);
        load_instruction(v_instruction);
        wait until rising_edge(dut_i_clk);
        check_slv(c_operand_test_name, dut_o_operand, v_exp_operand);

        v_instruction := x"CD";
        v_exp_operand := extract_operand(v_instruction);
        load_instruction(v_instruction);
        wait until rising_edge(dut_i_clk);
        check_slv(c_operand_test_name, dut_o_operand, v_exp_operand);
      end if;

      -- Test instruction register holds value when load is disabled.
      if run("test_holds_instruction") then
        v_instruction := x"12";
        v_exp_operand := extract_operand(v_instruction);
        load_instruction(v_instruction);
        wait until rising_edge(dut_i_clk);
        check_slv(c_operand_test_name, dut_o_operand, v_exp_operand);

        -- Hold for multiple cycles without loading.
        for lv_iteration in natural range 1 to 5 loop
          wait until rising_edge(dut_i_clk);
          check_slv(c_operand_test_name, dut_o_operand, v_exp_operand);
        end loop;
      end if;

      -- Test the LDA instruction.
      if run("test_lda") then
        -- Load a LDA instruction.
        v_instruction := x"01";
        v_exp_operand := extract_operand(v_instruction);

        check_fetch_cycle;

        dut_i_load_instruction_reg <= '0';

        -- Check that operand from the Instruction Register is loaded into Memory.
        v_exp_control_word := (
          EN_IR => '1',
          LOAD_MEM => '1',
          others => '0'
        );
        check_control_word(v_exp_control_word);
        wait until rising_edge(dut_i_clk);

        -- Check that operand from the Instruction Register is loaded into Memory.
        v_exp_control_word := (
          EN_MEM => '1',
          LOAD_AR => '1',
          others => '0'
        );
        check_control_word(v_exp_control_word);
        wait until rising_edge(dut_i_clk);

        -- Check that nothing occurs in this stage.
        v_exp_control_word := (others => '0');
        check_control_word(v_exp_control_word);
        wait until rising_edge(dut_i_clk);

      end if;

    end loop;

    test_runner_cleanup(runner);
  end process;

end architecture;
