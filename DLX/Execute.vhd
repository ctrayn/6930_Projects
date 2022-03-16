---------------------------------------------------------
-- DLX Processor
--
-- Jonah Boe
-- Calvin Passmore
-- Utah State University
-- ECE 6930, Spring 2022
---------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.common.all;

entity Execute is
	port (
		--INPUT
		clk 		: in std_logic;
		rst_l 	: in std_logic;
		pc_in 	: in std_logic_vector(9  downto 0);
		inst_in 	: in std_logic_vector(31 downto 0);
		RS1 		: in std_logic_vector(31 downto 0);
		RS2 		: in std_logic_vector(31 downto 0);
		Imm 		: in std_logic_vector(31 downto 0);
		inst_ME	: in std_logic_vector(31 downto 0);
		data_ME	: in std_logic_vector(31 downto 0);
		inst_WE	: in std_logic_vector(31 downto 0);
		data1_WE	: in std_logic_vector(31 downto 0);
		data2_WE	: in std_logic_vector(31 downto 0);
		--OUTPUT
		ALU_out 	: out std_logic_vector(31 downto 0);
		br_taken : out std_logic;
		br_addr  : out std_logic_vector(9 downto 0);
		RS2_out 	: out std_logic_vector(31 downto 0);
		inst_out : out std_logic_vector(31 downto 0)
	);
end entity Execute;

architecture behavioral of Execute is
	signal opcode 	: std_logic_vector(5 downto 0);
	signal InTwo	: std_logic_vector(31 downto 0);
	signal branch	: std_logic := '0';

begin
	opcode <= inst_in(31 downto 26);
	br_taken <= branch;
	--signals that just get delayed and passed on
	process (clk) begin
		if rising_edge(clk) then
			if branch = '0' then
				RS2_out <= RS2;
				inst_out <= inst_in;
			else
				RS2_out <= (others => '0');
				inst_out <= (others => '0');
			end if;
		end if;
	end process;

	--MUX RS2 and Imm
	process(clk, Imm, RS2, opcode) begin
		if OpIsImmediate(opcode) = '1' then
			InTwo <= Imm;
		else
			InTwo <= RS2;
		end if;
	end process;

	--ALU process
	process (clk) begin
		if rising_edge(clk) then
			case opcode is
				when OP_NOP | OP_LW =>
					branch <= '0';
					ALU_out <= ZEROS;

				when OP_SW =>
					branch <= '0';
					ALU_out <= std_logic_vector(unsigned(RS1) + unsigned(Imm));

				when OP_J =>
					branch <= '1';
					br_addr <= inst_in(9 downto 0);
					ALU_out <= ZEROS;

				when OP_JAL =>
					branch <= '1';
					br_addr <= inst_in(9 downto 0);
					ALU_out(31 downto 10) <= (others => '0');
					ALU_out(9 downto 0) <= pc_in;

				when OP_JR =>
					branch <= '1';
					br_addr <= RS1(9 downto 0);
					ALU_out <= ZEROS;

				when OP_JALR =>
					branch <= '1';
					br_addr <= RS1(9 downto 0);
					ALU_out(31 downto 10) <= (others => '0');
					ALU_out(9 downto 0) <= pc_in;

				when OP_BEQZ =>
					if (RS1 = ZEROS) then
						branch <= '1';
					else
						branch <= '0';
					end if;
					br_addr <= inst_in(9 downto 0);
					ALU_out <= ZEROS;

				when OP_BNEZ =>
					if (RS1 = ZEROS) then
						branch <= '0';
					else
						branch <= '1';
					end if;
					br_addr <= inst_in(9 downto 0);
					ALU_out <= ZEROS;

				when OP_ADD | OP_ADDI =>
					branch <= '0';
					ALU_out <= std_logic_vector(signed(RS1) + signed(InTwo));

				when OP_ADDU | OP_ADDUI =>
					branch <= '0';
					ALU_out <= std_logic_vector(unsigned(RS1) + unsigned(InTwo));

				when OP_SUB | OP_SUBI =>
					branch <= '0';
					ALU_out <= std_logic_vector(signed(RS1) - signed(InTwo));

				when OP_SUBU | OP_SUBUI =>
					branch <= '0';
					ALU_out <= std_logic_vector(unsigned(RS1) - unsigned(InTwo));

				when OP_AND | OP_ANDI =>
					branch <= '0';
					ALU_out <= RS1 and InTwo;

				when OP_OR | OP_ORI =>
					branch <= '0';
					ALU_out <= RS1 or InTwo;

				when OP_XOR | OP_XORI =>
					branch <= '0';
					ALU_out <= RS1 xor InTwo;

				when OP_SLL | OP_SLLI =>
					branch <= '0';
					ALU_out <= std_logic_vector(shift_left(unsigned(RS1), to_integer(unsigned(InTwo))));

				when OP_SRL | OP_SRLI =>
					ALU_out <= std_logic_vector(shift_right(unsigned(RS1), to_integer(unsigned(InTwo))));

				when OP_SRA | OP_SRAI =>
					ALU_out <= std_logic_vector(shift_right(signed(RS1), to_integer(unsigned(InTwo))));

				when OP_SLT | OP_SLTI =>
					branch <= '0';
					if (signed(RS1) < signed(InTwo)) then
						ALU_out <= X"00000001";
					else
						ALU_out <= X"00000000";
					end if;

				when OP_SLTU | OP_SLTUI =>
					branch <= '0';
					if (unsigned(RS1) < unsigned(InTwo)) then
						ALU_out <= X"00000001";
					else
						ALU_out <= X"00000000";
					end if;

				when OP_SGT | OP_SGTI =>
					branch <= '0';
					if (signed(RS1) > signed(InTwo)) then
						ALU_out <= X"00000001";
					else
						ALU_out <= X"00000000";
					end if;

				when OP_SGTU | OP_SGTUI =>
					branch <= '0';
					if (unsigned(RS1) > unsigned(InTwo)) then
						ALU_out <= X"00000001";
					else
						ALU_out <= X"00000000";
					end if;

				when OP_SLE | OP_SLEI =>
					branch <= '0';
					if (signed(RS1) <= signed(InTwo)) then
						ALU_out <= X"00000001";
					else
						ALU_out <= X"00000000";
					end if;

				when OP_SLEU | OP_SLEUI =>
					branch <= '0';
					if (unsigned(RS1) <= unsigned(InTwo)) then
						ALU_out <= X"00000001";
					else
						ALU_out <= X"00000000";
					end if;

				when OP_SGE | OP_SGEI =>
					branch <= '0';
					if (signed(RS1) >= signed(InTwo)) then
						ALU_out <= X"00000001";
					else
						ALU_out <= X"00000000";
					end if;

				when OP_SGEU | OP_SGEUI =>
					branch <= '0';
					if (unsigned(RS1) >= unsigned(InTwo)) then
						ALU_out <= X"00000001";
					else
						ALU_out <= X"00000000";
					end if;

				when OP_SEQ | OP_SEQI =>
					branch <= '0';
					if (unsigned(RS1) = unsigned(InTwo)) then
						ALU_out <= X"00000001";
					else
						ALU_out <= X"00000000";
					end if;

				when OP_SNE | OP_SNEI =>
					branch <= '0';
					if (unsigned(RS1) = unsigned(InTwo)) then
						ALU_out <= X"00000000";
					else
						ALU_out <= X"00000001";
					end if;

				when others =>
					branch <= '0';
					ALU_out <= ZEROS;

			end case;
		end if;
	end process;
end architecture behavioral;
