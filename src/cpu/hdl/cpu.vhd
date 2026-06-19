------------------------------------------------------------------------------------------------------------------------
-- The top-level file where the modules are brought together to form a CPU.
------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library lil_cpu_lib;
  use lil_cpu_lib.lil_cpu_pkg.all;

entity cpu is
  generic (
    g_mem_init : t_ram := (others => (others => '0'))
  );
  port (
    i_clk  : in  std_logic;
    o_data : out t_bus_data;
    o_hlt  : out std_logic
  );
end entity;

architecture rtl of cpu is

  signal control_word : t_control_word;
  signal bus_data : t_bus_data;

  signal operand : t_bus_data;

  signal program_count : t_addr;
  signal program_count_slv : t_bus_data;
  signal memory_data : t_bus_data;
  signal reg_a_data : t_bus_data;
  signal reg_b_data : t_bus_data;
  signal alu_data : t_bus_data;

begin

  cmp_program_counter : entity lil_cpu_lib.counter(rtl)
   generic map(
      g_count_length => c_addr_width
  )
   port map(
      i_clk => i_clk,
      i_reset => '0',
      i_count_en => control_word(COUNT_PC),
      o_count => program_count
  );

  -- Extend program count to fit the bus length.
  program_count_slv <= std_logic_vector(resize(program_count, t_bus_data'length));

  cmp_memory : entity lil_cpu_lib.memory(rtl)
   generic map(
      g_init => (g_mem_init)
  )
   port map(
      i_clk => i_clk,
      i_load_mar => control_word(LOAD_MEM),
      i_addr => unsigned(bus_data(t_addr'range)),
      o_data => memory_data
  );

  cmp_reg_a : entity lil_cpu_lib.reg(rtl)
   port map(
      i_clk => i_clk,
      i_load => control_word(LOAD_AR),
      i_data => bus_data,
      o_data => reg_a_data
  );

  cmp_reg_b : entity lil_cpu_lib.reg(rtl)
   port map(
      i_clk => i_clk,
      i_load => control_word(LOAD_BR),
      i_data => bus_data,
      o_data => reg_b_data
  );

  cmp_alu : entity lil_cpu_lib.alu(rtl)
   port map(
      i_subtract_en => control_word(SUB_ALU),
      i_data_a => reg_a_data,
      i_data_b => reg_b_data,
      o_sum => alu_data
  );

  cmp_reg_out : entity lil_cpu_lib.reg(rtl)
   port map(
      i_clk => i_clk,
      i_load => control_word(LOAD_OR),
      i_data => bus_data,
      o_data => o_data
  );

  cmp_control : entity lil_cpu_lib.control(rtl)
   port map(
      i_clk => i_clk,
      i_load_instruction_reg => control_word(LOAD_IR),
      i_instruction => bus_data,
      o_operand => operand,
      o_control_word => control_word
  );

  -- Control the flow of data between modules with a multiplexer.
  with control_word select bus_data <=
    program_count_slv when (EN_PC => '1', others => '-'),
    memory_data when (EN_MEM => '1', others => '-'),
    operand when (EN_IR => '1', others => '-'),
    reg_a_data when (EN_AR => '1', others => '-'),
    alu_data when (EN_ALU => '1', others => '-'),
    (others => '-') when others;

  -- Output the HLT signal to show when the program is done.
  o_hlt <= control_word(HLT);

end architecture;
