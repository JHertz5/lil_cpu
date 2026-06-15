---------------------------------------------------------------------------------------------------------------
-- The Control module that takes instructions and enacts them using the control signals.
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library lil_cpu_lib;
  use lil_cpu_lib.lil_cpu_pkg.all;

entity control is
  port (
    i_clk                  : in  std_logic;
    i_load_instruction_reg : in  std_logic;
    i_instruction          : out t_bus_data;
    o_operand              : out t_bus_data;
    o_control_word         : out t_control_word
  );
end entity;

architecture rtl of control is

  type t_instruction is record
    opcode  : t_opcode_slv;
    operand : t_addr;
  end record;

  signal instruction_slv : t_bus_data;
  signal instruction     : t_instruction;

  signal reset_count : std_logic;
  signal state_count : t_state;

begin

  -- Instantiate the instruction register.
  cmp_instruction_register : entity lil_cpu_lib.reg(rtl)
    port map (
      i_clk   => i_clk,
      i_reset => '0',
      i_load  => i_load_instruction_reg,
      i_data  => i_instruction,
      o_data  => instruction_slv
    );

  -- Break the instruction out into the opcode and the operand.
  instruction <= (
    opcode  => instruction_slv(c_bus_width - 1  downto t_addr'high + 1),
    operand => unsigned(instruction_slv(t_addr'range))
  );
  -- Output the operand.
  o_operand <= x"0" & std_logic_vector(instruction.operand);

  -- Instantiate the state counter.
  cmp_state_counter : entity lil_cpu_lib.counter(rtl)
    port map (
      i_clk      => i_clk,
      i_reset    => reset_count,
      i_count_en => '1',
      o_count    => state_count
    );

  -- There are at most five microinstructions within
  reset_count <= state_count ?>= c_num_microinstruction_states;

  -- Instantiate the instruction decoder.
  cmp_instruction_decoder : entity lil_cpu_lib.instruction_decoder(rtl)
    port map (
      i_opcode       => instruction.opcode,
      i_state_count  => state_count,
      o_control_word => o_control_word
    );

end architecture;
