------------------------------------------------------------------------------------------------------------------------
-- The Instruction Decoder takes the opcodes for instructions and decodes them into microinstructions to generate the
-- control word that drives all of the various control signals.
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library lil_cpu_lib;
  use lil_cpu_lib.lil_cpu_pkg.all;

entity instruction_decoder is
  port (
    i_opcode       : in  t_opcode_slv;
    i_state_count  : in  t_state;
    o_control_word : out t_control_word
  );
end entity;

architecture rtl of instruction_decoder is

begin

  proc_decode : process(all)

    type t_opcode is (LDA, ADD, SUB, LOR, HLT);

    -- Decode the opcode bits into a meaningful enum name.
    function slv_to_opcode (
      i_slv : t_opcode_slv
    ) return t_opcode is

      variable v_return : t_opcode;

    begin

      with i_slv select v_return :=
        LDA when x"0",
        ADD when x"1",
        SUB when x"2",
        LOR when x"E",
        HLT when x"F";
      return v_return;

    end function;

    variable v_opcode : t_opcode;

  begin

    v_opcode := slv_to_opcode(i_opcode);

    -- By default, all control signals are inactive.
    o_control_word <= (others => '0');

    case to_integer(i_state_count) is

      -- Load Program Count to Memory.
      when 0 =>
        o_control_word(EN_PC)    <= '1';
        o_control_word(LOAD_MEM) <= '1';

      -- Load Instruction to Control. Increment the Program Count.
      when 1 =>
        o_control_word(EN_MEM)   <= '1';
        o_control_word(LOAD_IR)  <= '1';
        o_control_word(COUNT_PC) <= '1';

      when 2 =>
        with v_opcode select o_control_word <=
          -- Load Operand to Memory.
          (
            EN_IR    => '1',
            LOAD_MEM => '1',
            others   => '0'
          ) when LDA | ADD | SUB,
          -- Load Register A to Output Register.
          (
            EN_AR   => '1',
            LOAD_OR => '1',
            others  => '0'
          ) when LOR,
          (
            HLT    => '1',
            others => '0'
          ) when HLT,
          (others => '0') when others;

      when 3 =>
        with v_opcode select o_control_word <=
          -- Load Memory to Register A.
          (
            EN_MEM  => '1',
            LOAD_AR => '1',
            others  => '0'
          ) when LDA,
          -- Load Memory to Register B.
          (
            EN_MEM  => '1',
            LOAD_BR => '1',
            others  => '0'
          ) when ADD | SUB,
          (others => '0') when others;

      when 4 =>
        with v_opcode select o_control_word <=
          -- Load ALU to Register A.
          (
            EN_ALU  => '1',
            LOAD_AR => '1',
            others  => '0'
          ) when ADD,
          -- Load ALU to Register A, with subtraction enabled.
          (
            EN_ALU  => '1',
            LOAD_AR => '1',
            SUB_ALU => '1',
            others  => '0'
          ) when SUB,
          (others => '0') when others;

    end case;

  end process;

end architecture;
