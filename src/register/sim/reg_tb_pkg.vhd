------------------------------------------------------------------------------------------------------------------------
-- Helper package for reg_tb testbench. Defines command types and procedures for stimulus/checker coordination.
-- This package serves as a template for future testbenches in the project.
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library lil_cpu;
  use lil_cpu.lil_cpu_pkg.all;

package reg_tb_pkg is

  type t_stimuli_cmd is (CMD_IDLE, CMD_RESET, CMD_LOAD_DATA, CMD_SET_OUTPUT_EN, CMD_SET_OUTPUT_DIS, CMD_WAIT_CYCLE);
  type t_check_cmd is (CMD_IDLE, CMD_VERIFY_OUTPUT, CMD_VERIFY_HIGHZ);

  ----------------------------------------------------------------------------------------------------------------------
  -- Stimulus procedures. Drive inputs to the DUT.
  ----------------------------------------------------------------------------------------------------------------------
  procedure trigger_reset (
    signal stimuli_ack : in  std_logic;
    signal stimuli_cmd : out t_stimuli_cmd
  );

  procedure load_register (
    signal stimuli_ack : in  std_logic;
    constant data               : in  t_bus_data;
    signal stimuli_cmd : out t_stimuli_cmd;
    signal stimuli_param : out t_bus_data
  );

  procedure set_output_enabled (
    signal stimuli_ack : in  std_logic;
    signal stimuli_cmd : out t_stimuli_cmd
  );

  procedure set_output_disabled (
    signal stimuli_ack : in  std_logic;
    signal stimuli_cmd : out t_stimuli_cmd
  );

  procedure wait_clock_cycle (
    signal stimuli_ack : in  std_logic;
    signal stimuli_cmd : out t_stimuli_cmd
  );

  ----------------------------------------------------------------------------------------------------------------------
  -- Checker procedures: Verify outputs from DUT.
  ----------------------------------------------------------------------------------------------------------------------
  procedure verify_output (
    signal check_ack : in  std_logic;
    constant expected           : in  t_bus_data;
    signal check_cmd : out t_check_cmd;
    signal check_param : out t_bus_data
  );

  procedure verify_highz (
    signal check_ack : in  std_logic;
    signal check_cmd : out t_check_cmd
  );

  -- Utility procedures
  procedure clock_sync (
    signal clk : in std_logic
  );

end package;

package body reg_tb_pkg is

  procedure trigger_reset (
    signal stimuli_ack : in  std_logic;
    signal stimuli_cmd : out t_stimuli_cmd
  ) is
  begin
    stimuli_cmd <= CMD_RESET;
    wait until stimuli_ack = '1';
    stimuli_cmd <= CMD_IDLE;
  end procedure;

  procedure load_register (
    signal stimuli_ack : in  std_logic;
    constant data               : in  t_bus_data;
    signal stimuli_cmd : out t_stimuli_cmd;
    signal stimuli_param : out t_bus_data
  ) is
  begin
    stimuli_param <= data;
    stimuli_cmd   <= CMD_LOAD_DATA;
    wait until stimuli_ack = '1';
    stimuli_cmd <= CMD_IDLE;
  end procedure;

  procedure set_output_enabled (
    signal stimuli_ack : in  std_logic;
    signal stimuli_cmd : out t_stimuli_cmd
  ) is
  begin
    stimuli_cmd <= CMD_SET_OUTPUT_EN;
    wait until stimuli_ack = '1';
    stimuli_cmd <= CMD_IDLE;
  end procedure;

  procedure set_output_disabled (
    signal stimuli_ack : in  std_logic;
    signal stimuli_cmd : out t_stimuli_cmd
  ) is
  begin
    stimuli_cmd <= CMD_SET_OUTPUT_DIS;
    wait until stimuli_ack = '1';
    stimuli_cmd <= CMD_IDLE;
  end procedure;

  procedure wait_clock_cycle (
    signal stimuli_ack : in  std_logic;
    signal stimuli_cmd : out t_stimuli_cmd
  ) is
  begin
    stimuli_cmd <= CMD_WAIT_CYCLE;
    wait until stimuli_ack = '1';
    stimuli_cmd <= CMD_IDLE;
  end procedure;

  procedure verify_output (
    signal check_ack : in  std_logic;
    constant expected           : in  t_bus_data;
    signal check_cmd : out t_check_cmd;
    signal check_param : out t_bus_data
  ) is
  begin
    check_param <= expected;
    check_cmd   <= CMD_VERIFY_OUTPUT;
    wait until check_ack = '1';
    check_cmd <= CMD_IDLE;
  end procedure;

  procedure verify_highz (
    signal check_ack : in  std_logic;
    signal check_cmd : out t_check_cmd
  ) is
  begin
    check_cmd <= CMD_VERIFY_HIGHZ;
    wait until check_ack = '1';
    check_cmd <= CMD_IDLE;
  end procedure;

  procedure clock_sync (
    signal clk : in std_logic
  ) is
  begin
    wait until rising_edge(clk);
  end procedure;

end package body;
