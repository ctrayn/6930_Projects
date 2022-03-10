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
		ALU_MW	: in std_logic_vector(31 downto 0);
		OP_EM		: in std_logic_vector(31 downto 0);
		OP_MW		: in std_logic_vector(31 downto 0);
		--OUTPUT
		ALU_out 	: out std_logic_vector(31 downto 0);
		br_taken : out std_logic;
		br_addr  : out std_logic_vector(9 downto 0);
		RS2_out 	: out std_logic_vector(31 downto 0);
		inst_out : out std_logic_vector(31 downto 0)
	);
end entity Execute;

architecture behavioral of Execute is
	signal opcode : std_logic_vector(5 downto 0);
	signal InTwo, InOne : std_logic_vector(31 downto 0);
	
	signal memwr_rd, exmem_rd, rs1_new	: std_logic_vector(4 downto 0);
	signal exmem_OP, memwr_OP : std_logic_vector(31 downto 0);
	signal ALU_readback : std_logic_vector(31 downto 0);	

begin
	opcode <= inst_in(31 downto 26);
	ALU_out <= ALU_readback;
	--signals that just get delayed and passed on
	process (clk) begin
		if rising_edge(clk) then
			RS2_out <= RS2;
			inst_out <= inst_in;
			exmem_OP <= inst_in;
			memwr_OP <= exmem_op;
		end if;
	end process;

	exmem_rd <= OP_EM(25 downto 21);		--Last cycles OPCODE
	memwr_rd <= OP_MW(25 downto 21);		--2 cycles ago OPCODE
	rs1_new  <= inst_in(20 downto 16);
	--MUX RS2 and Imm
	process(clk, Imm, RS2, opcode) begin
		if OpIsRegister(opcode) = '1' and (exmem_rd = rs1_new) then
			InTwo <= ALU_readback;
		elsif OpIsRegister(opcode) = '1' and (memwr_rd = rs1_new) then
			InTwo <= ALU_MW;
		elsif OpIsImmediate(opcode) = '1' then
			InTwo <= Imm;
		else
			InTwo <= RS2;
		end if;
	end process;
	
	--Data hazard Read After Write: Mux RS1
	process(clk, inst_in) begin
		if (exmem_rd = rs1_new) then		--Data Hazards
			InOne <= ALU_readback;
		elsif(memwr_rd = rs1_new) then
			InOne <= ALU_MW;				--two cycles ago alu output
		else
			InOne <= RS1;
		end if;
	end process;
	
	--Data hazard, Reading register before writeback: Mux RS1

	--ALU process
	process (clk) begin
		if rising_edge(clk) then
			case opcode is
				when OP_NOP | OP_LW =>
					br_taken <= '0';
					ALU_readback <= ZEROS;

				when OP_SW =>
					br_taken <= '0';
					ALU_readback <= std_logic_vector(unsigned(InOne) + unsigned(Imm));

				when OP_J =>
					br_taken <= '1';
					br_addr <= inst_in(9 downto 0);
					ALU_readback <= ZEROS;

				when OP_JAL =>
					br_taken <= '1';
					br_addr <= inst_in(9 downto 0);
					ALU_readback(31 downto 10) <= (others => '0');
					ALU_readback(9 downto 0) <= pc_in;

				when OP_JR =>
					br_taken <= '1';
					br_addr <= InOne(9 downto 0);
					ALU_readback <= ZEROS;

				when OP_JALR =>
					br_taken <= '1';
					br_addr <= InOne(9 downto 0);
					ALU_readback(31 downto 10) <= (others => '0');
					ALU_readback(9 downto 0) <= pc_in;

				when OP_BEQZ =>
					if (InOne = ZEROS) then
						br_taken <= '1';
					else
						br_taken <= '0';
					end if;
					br_addr <= inst_in(9 downto 0);
					ALU_readback <= ZEROS;

				when OP_BNEZ =>
					if (InOne = ZEROS) then
						br_taken <= '0';
					else
						br_taken <= '1';
					end if;
					br_addr <= inst_in(9 downto 0);
					ALU_readback <= ZEROS;

				when OP_ADD | OP_ADDI =>
					br_taken <= '0';
					ALU_readback <= std_logic_vector(signed(InOne) + signed(InTwo));

				when OP_ADDU | OP_ADDUI =>
					br_taken <= '0';
					ALU_readback <= std_logic_vector(unsigned(InOne) + unsigned(InTwo));

				when OP_SUB | OP_SUBI =>
					br_taken <= '0';
					ALU_readback <= std_logic_vector(signed(InOne) - signed(InTwo));

				when OP_SUBU | OP_SUBUI =>
					br_taken <= '0';
					ALU_readback <= std_logic_vector(unsigned(InOne) - unsigned(InTwo));

				when OP_AND | OP_ANDI =>
					br_taken <= '0';
					ALU_readback <= InOne and InTwo;

				when OP_OR | OP_ORI =>
					br_taken <= '0';
					ALU_readback <= InOne or InTwo;

				when OP_XOR | OP_XORI =>
					br_taken <= '0';
					ALU_readback <= InOne xor InTwo;

				when OP_SLL | OP_SLLI =>
					br_taken <= '0';
					ALU_readback <= std_logic_vector(shift_left(unsigned(InOne), to_integer(unsigned(InTwo))));

				when OP_SRL | OP_SRLI =>
					ALU_readback <= std_logic_vector(shift_right(unsigned(InOne), to_integer(unsigned(InTwo))));

				when OP_SRA | OP_SRAI =>
					ALU_readback <= std_logic_vector(shift_right(signed(InOne), to_integer(unsigned(InTwo))));

				when OP_SLT | OP_SLTI =>
					br_taken <= '0';
					if (signed(InOne) < signed(InTwo)) then
						ALU_readback <= X"00000001";
					else
						ALU_readback <= X"00000000";
					end if;

				when OP_SLTU | OP_SLTUI =>
					br_taken <= '0';
					if (unsigned(InOne) < unsigned(InTwo)) then
						ALU_readback <= X"00000001";
					else
						ALU_readback <= X"00000000";
					end if;

				when OP_SGT | OP_SGTI =>
					br_taken <= '0';
					if (signed(InOne) > signed(InTwo)) then
						ALU_readback <= X"00000001";
					else
						ALU_readback <= X"00000000";
					end if;

				when OP_SGTU | OP_SGTUI =>
					br_taken <= '0';
					if (unsigned(InOne) > unsigned(InTwo)) then
						ALU_readback <= X"00000001";
					else
						ALU_readback <= X"00000000";
					end if;

				when OP_SLE | OP_SLEI =>
					br_taken <= '0';
					if (signed(InOne) <= signed(InTwo)) then
						ALU_readback <= X"00000001";
					else
						ALU_readback <= X"00000000";
					end if;

				when OP_SLEU | OP_SLEUI =>
					br_taken <= '0';
					if (unsigned(InOne) <= unsigned(InTwo)) then
						ALU_readback <= X"00000001";
					else
						ALU_readback <= X"00000000";
					end if;

				when OP_SGE | OP_SGEI =>
					br_taken <= '0';
					if (signed(InOne) >= signed(InTwo)) then
						ALU_readback <= X"00000001";
					else
						ALU_readback <= X"00000000";
					end if;

				when OP_SGEU | OP_SGEUI =>
					br_taken <= '0';
					if (unsigned(InOne) >= unsigned(InTwo)) then
						ALU_readback <= X"00000001";
					else
						ALU_readback <= X"00000000";
					end if;

				when OP_SEQ | OP_SEQI =>
					br_taken <= '0';
					if (unsigned(InOne) = unsigned(InTwo)) then
						ALU_readback <= X"00000001";
					else
						ALU_readback <= X"00000000";
					end if;

				when OP_SNE | OP_SNEI =>
					br_taken <= '0';
					if (unsigned(InOne) = unsigned(InTwo)) then
						ALU_readback <= X"00000000";
					else
						ALU_readback <= X"00000001";
					end if;

				when others =>
					br_taken <= '0';
					ALU_readback <= ZEROS;

			end case;
		end if;
	end process;
end architecture behavioral;
