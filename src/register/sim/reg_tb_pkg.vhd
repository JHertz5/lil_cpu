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
    signal i_ack : in  std_logic;
    signal o_cmd : out t_stimuli_cmd
  );

  procedure load_register (
    signal i_ack : in  std_logic;
    constant i_load_data : in  t_bus_data;
    signal o_cmd : out t_stimuli_cmd;
    signal o_load_data : out t_bus_data
  );

  procedure set_output_enabled (
    signal i_ack : in  std_logic;
    signal o_cmd : out t_stimuli_cmd
  );

  procedure set_output_disabled (
    signal i_ack : in  std_logic;
    signal o_cmd : out t_stimuli_cmd
  );

  procedure wait_clock_cycle (
    signal i_ack : in  std_logic;
    signal o_cmd : out t_stimuli_cmd
  );

  ----------------------------------------------------------------------------------------------------------------------
  -- Checker procedures: Verify outputs from DUT.
  ----------------------------------------------------------------------------------------------------------------------
  procedure verify_output (
    signal i_ack : in  std_logic;
    constant i_exp_data           : in  t_bus_data;
    signal o_cmd : out t_check_cmd;
    signal o_exp_data : out t_bus_data
  );

  procedure verify_highz (
    signal i_ack : in  std_logic;
    signal o_cmd : out t_check_cmd
  );

end package;

package body reg_tb_pkg is

  procedure trigger_reset (
    signal i_ack : in  std_logic;
    signal o_cmd : out t_stimuli_cmd
  ) is
  begin
    o_cmd <= CMD_RESET;
    wait until i_ack = '1';
    o_cmd <= CMD_IDLE;
  end procedure;

  procedure load_register (
    signal i_ack : in  std_logic;
    constant i_load_data               : in  t_bus_data;
    signal o_cmd : out t_stimuli_cmd;
    signal o_load_data : out t_bus_data
  ) is
  begin
    o_load_data <= i_load_data;
    o_cmd   <= CMD_LOAD_DATA;
    wait until i_ack = '1';
    o_cmd <= CMD_IDLE;
  end procedure;

  procedure set_output_enabled (
    signal i_ack : in  std_logic;
    signal o_cmd : out t_stimuli_cmd
  ) is
  begin
    o_cmd <= CMD_SET_OUTPUT_EN;
    wait until i_ack = '1';
    o_cmd <= CMD_IDLE;
  end procedure;

  procedure set_output_disabled (
    signal i_ack : in  std_logic;
    signal o_cmd : out t_stimuli_cmd
  ) is
  begin
    o_cmd <= CMD_SET_OUTPUT_DIS;
    wait until i_ack = '1';
    o_cmd <= CMD_IDLE;
  end procedure;

  procedure wait_clock_cycle (
    signal i_ack : in  std_logic;
    signal o_cmd : out t_stimuli_cmd
  ) is
  begin
    o_cmd <= CMD_WAIT_CYCLE;
    wait until i_ack = '1';
    o_cmd <= CMD_IDLE;
  end procedure;

  procedure verify_output (
    signal i_ack : in  std_logic;
    constant i_exp_data           : in  t_bus_data;
    signal o_cmd : out t_check_cmd;
    signal o_exp_data : out t_bus_data
  ) is
  begin
    o_exp_data <= i_exp_data;
    o_cmd   <= CMD_VERIFY_OUTPUT;
    wait until i_ack = '1';
    o_cmd <= CMD_IDLE;
  end procedure;

  procedure verify_highz (
    signal i_ack : in  std_logic;
    signal o_cmd : out t_check_cmd
  ) is
  begin
    o_cmd <= CMD_VERIFY_HIGHZ;
    wait until i_ack = '1';
    o_cmd <= CMD_IDLE;
  end procedure;

end package body;
