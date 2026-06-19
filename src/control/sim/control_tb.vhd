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

    variable v_instruction : t_bus_data;
    variable v_exp_operand : t_bus_data;
    -- variable v_exp_control_word : t_control_word;

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

    type t_control_word_array is array(natural range <>) of t_control_word;

    procedure check_microinstruction_sequence (
      constant i_expected_sequence : t_control_word_array;
      constant i_instruction       : t_bus_data
    ) is

      constant c_fetch_cycle : t_control_word_array(1 to 2) := (
        (EN_PC => '1', LOAD_MEM => '1', others => '0'),
        (EN_MEM => '1', LOAD_IR => '1', COUNT_PC => '1', others => '0')
      );

      constant c_expected_sequence : t_control_word_array(1 to c_num_microinstruction_states) :=
        c_fetch_cycle & i_expected_sequence;

      variable v_exp_control_word : t_control_word;

    begin

      dut_i_instruction <= i_instruction;

      for lv_stage in c_expected_sequence'range loop
        v_exp_control_word := c_expected_sequence(lv_stage);
        -- Assert the load IR input if that control signal is asserted.
        dut_i_load_instruction_reg <= v_exp_control_word(LOAD_IR) ?= '1';
        -- Check the control word.
        check_control_word(c_expected_sequence(lv_stage));
        wait until rising_edge(dut_i_clk);
      end loop;

    end procedure;

    variable v_expected_sequence : t_control_word_array(1 to 3);

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
        v_instruction := x"01";

        v_expected_sequence := (
          (EN_IR => '1', LOAD_MEM => '1', others => '0'),
          (EN_MEM => '1', LOAD_AR => '1', others => '0'),
          (others => '0')
        );
        check_microinstruction_sequence(
          i_expected_sequence => v_expected_sequence,
          i_instruction       => v_instruction
        );

      end if;

      -- Test the ADD instruction.
      if run("test_add") then
        v_instruction := x"11";

        v_expected_sequence := (
          (EN_IR => '1', LOAD_MEM => '1', others => '0'),
          (EN_MEM => '1', LOAD_BR => '1', others => '0'),
          (EN_ALU => '1', LOAD_AR => '1', others => '0')
        );
        check_microinstruction_sequence(
          i_expected_sequence => v_expected_sequence,
          i_instruction       => v_instruction
        );

      end if;

      -- Test the SUB instruction.
      if run("test_sub") then
        v_instruction := x"21";

        v_expected_sequence := (
          (EN_IR => '1', LOAD_MEM => '1', others => '0'),
          (EN_MEM => '1', LOAD_BR => '1', others => '0'),
          (EN_ALU => '1', LOAD_AR => '1', SUB_ALU => '1', others => '0')
        );
        check_microinstruction_sequence(
          i_expected_sequence => v_expected_sequence,
          i_instruction       => v_instruction
        );

      end if;

      -- Test the LOR instruction.
      if run("test_lor") then
        v_instruction := x"E1";

        v_expected_sequence := (
          (EN_AR => '1', LOAD_OR => '1', others => '0'),
          (others => '0'),
          (others => '0')
        );
        check_microinstruction_sequence(
          i_expected_sequence => v_expected_sequence,
          i_instruction       => v_instruction
        );

      end if;

      -- Test the HLT instruction.
      if run("test_hlt") then
        v_instruction := x"F0";
        v_exp_operand := extract_operand(v_instruction);

        v_expected_sequence := (
          (HLT => '1', others => '0'),
          (HLT => '1', others => '0'),
          (HLT => '1', others => '0')
        );
        check_microinstruction_sequence(
          i_expected_sequence => v_expected_sequence,
          i_instruction       => v_instruction
        );

      end if;

    end loop;

    test_runner_cleanup(runner);
  end process;

end architecture;
