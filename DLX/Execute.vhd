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
	signal InTwo : std_logic_vector(31 downto 0);
	
begin
	opcode <= inst_in(31 downto 26);
	
	--signals that just get delayed and passed on
	process (clk) begin
		if rising_edge(clk) then
			RS2_out <= RS2;
			br_addr <= inst_in(9 downto 0);
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
				when OP_NOP | OP_LW | OP_SW | OP_J | OP_JAL => 
					br_taken <= '0';
					ALU_out <= ZEROS;
					
				when OP_JR | OP_JALR =>
					br_taken <= '0';
					ALU_out <= RS1;
					
				when OP_BEQZ =>
					if (RS1 = ZEROS) then
						br_taken <= '1';
					else 
						br_taken <= '0';
					end if;
					ALU_out <= ZEROS;
					
				when OP_BNEZ =>
					if (RS1 = ZEROS) then
						br_taken <= '0';
					else 
						br_taken <= '1';
					end if;
					ALU_out <= ZEROS;	
	
				when OP_ADD | OP_ADDI =>
					br_taken <= '0';
					ALU_out <= std_logic_vector(signed(RS1) + signed(InTwo));
					
				when OP_ADDU | OP_ADDUI =>
					br_taken <= '0';
					ALU_out <= std_logic_vector(unsigned(RS1) + unsigned(InTwo));
									
				when OP_SUB | OP_SUBI =>
					br_taken <= '0';
					ALU_out <= std_logic_vector(signed(RS1) - signed(InTwo));
					
				when OP_SUBU | OP_SUBUI =>
					br_taken <= '0';
					ALU_out <= std_logic_vector(unsigned(RS1) - unsigned(InTwo));
					
				when OP_AND | OP_ANDI =>
					br_taken <= '0';
					ALU_out <= RS1 and InTwo;
				
				when OP_OR | OP_ORI =>
					br_taken <= '0';
					ALU_out <= RS1 or InTwo;
					
				when OP_XOR | OP_XORI =>
					br_taken <= '0';
					ALU_out <= RS1 xor InTwo;
					
				when OP_SLL | OP_SLLI =>
					br_taken <= '0';
					ALU_out(31 downto to_integer(unsigned(InTwo))) <= RS1(31 - to_integer(unsigned(InTwo)) downto 0);
					ALU_out(to_integer(unsigned(InTwo)) downto 0) <= ZEROS(to_integer(unsigned(InTwo)) downto 0);
					
				when OP_SRL | OP_SRLI =>
					br_taken <= '0';
					ALU_out(31 downto 31 - to_integer(unsigned(InTwo))) <= ZEROS(to_integer(unsigned(InTwo)) downto 0);
					ALU_out(31 - to_integer(unsigned(InTwo)) downto 0) <= RS1(31 downto to_integer(unsigned(InTwo)));
					
				when OP_SRA | OP_SRAI =>
					br_taken <= '0';
					if (RS1(31) = '0') then
						ALU_out(31 downto 31 - to_integer(unsigned(InTwo))) <= ZEROS(to_integer(unsigned(InTwo)) downto 0);
						ALU_out(31 - to_integer(unsigned(InTwo)) downto 0) <= RS1(31 downto to_integer(unsigned(InTwo)));
					else
						ALU_out(31 downto 31 - to_integer(unsigned(InTwo))) <= ONES(to_integer(unsigned(InTwo)) downto 0);
						ALU_out(31 - to_integer(unsigned(InTwo)) downto 0)  <= RS1(31 downto to_integer(unsigned(InTwo)));
					end if;
					
				when OP_SLT | OP_SLTI =>
					br_taken <= '0';
					if (signed(RS1) < signed(InTwo)) then
						ALU_out <= X"00000001";
					else
						ALU_out <= X"00000000";					
					end if;
					
				when OP_SLTU | OP_SLTUI =>
					br_taken <= '0';
					if (unsigned(RS1) < unsigned(InTwo)) then
						ALU_out <= X"00000001";
					else
						ALU_out <= X"00000000";					
					end if;
					
				when OP_SGT | OP_SGTI =>
					br_taken <= '0';
					if (signed(RS1) > signed(InTwo)) then
						ALU_out <= X"00000001";
					else
						ALU_out <= X"00000000";					
					end if;
					
				when OP_SGTU | OP_SGTUI =>
					br_taken <= '0';
					if (unsigned(RS1) > unsigned(InTwo)) then
						ALU_out <= X"00000001";
					else
						ALU_out <= X"00000000";					
					end if;
					
				when OP_SLE | OP_SLEI =>
					br_taken <= '0';
					if (signed(RS1) <= signed(InTwo)) then
						ALU_out <= X"00000001";
					else
						ALU_out <= X"00000000";					
					end if;
					
				when OP_SLEU | OP_SLEUI =>
					br_taken <= '0';
					if (unsigned(RS1) <= unsigned(InTwo)) then
						ALU_out <= X"00000001";
					else
						ALU_out <= X"00000000";					
					end if;
					
				when OP_SGE | OP_SGEI =>
					br_taken <= '0';
					if (signed(RS1) >= signed(InTwo)) then
						ALU_out <= X"00000001";
					else
						ALU_out <= X"00000000";					
					end if;
					
				when OP_SGEU | OP_SGEUI =>
					br_taken <= '0';
					if (unsigned(RS1) >= unsigned(InTwo)) then
						ALU_out <= X"00000001";
					else
						ALU_out <= X"00000000";					
					end if;
					
				when OP_SEQ | OP_SEQI =>
					br_taken <= '0';
					if (unsigned(RS1) = unsigned(InTwo)) then
						ALU_out <= X"00000001";
					else
						ALU_out <= X"00000000";					
					end if;
					
				when OP_SNE | OP_SNEI =>
					br_taken <= '0';
					if (unsigned(RS1) = unsigned(InTwo)) then
						ALU_out <= X"00000000";
					else
						ALU_out <= X"00000001";					
					end if;
					
				when others =>
					br_taken <= '0';
					ALU_out <= ZEROS;
					
			end case;
		end if;
	end process;
end architecture behavioral;

