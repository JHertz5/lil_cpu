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

    case to_integer(i_state_count) is

      -- Load Program Count to Memory.
      when 0 =>
        o_control_word <= (
          EN_PC    => '1',
          LOAD_MEM => '1',
          others   => '0'
        );

      -- Load Instruction to Control. Increment the Program Count.
      when 1 =>
        o_control_word <= (
          EN_MEM   => '1',
          LOAD_IR  => '1',
          COUNT_PC => '1',
          others   => '0'
        );

      when 2 =>
        case v_opcode is

          -- Load Operand to Memory.
          when LDA | ADD | SUB =>
            o_control_word <= (
              EN_IR    => '1',
              LOAD_MEM => '1',
              others   => '0'
            );

          -- Load Register A to Output Register.
          when LOR =>
            o_control_word <= (
              EN_AR   => '1',
              LOAD_OR => '1',
              others  => '0'
            );

          when others =>
            o_control_word <= (others => '0');

        end case;

      when 3 =>
        case v_opcode is

          -- Load Memory to Register A.
          when LDA =>
            o_control_word <= (
              EN_MEM  => '1',
              LOAD_AR => '1',
              others  => '0'
            );

          -- Load Memory to Register B.
          when ADD | SUB =>
            o_control_word <= (
              EN_MEM  => '1',
              LOAD_BR => '1',
              others  => '0'
            );

          when others =>
            o_control_word <= (others => '0');

        end case;

      when 4 =>
        case v_opcode is

          -- Load ALU to Register A.
          when ADD =>
            o_control_word <= (
              EN_ALU  => '1',
              LOAD_AR => '1',
              others  => '0'
            );

          -- Load ALU to Register A, with subtraction enabled.
          when SUB =>
            o_control_word <= (
              EN_ALU  => '1',
              LOAD_AR => '1',
              SUB_ALU => '1',
              others  => '0'
            );

          when others =>
            o_control_word <= (others => '0');

        end case;

    end case;

  end process;

end architecture;
