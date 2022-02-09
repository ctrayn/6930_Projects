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

entity Decode is
	port (
		--INPUT 
		clk					: in std_logic;
		rst_l					: in std_logic;
		pc_in					: in std_logic_vector(9  downto 0);
		instruction_in		: in std_logic_vector(31 downto 0);
		w_instruction		: in std_logic_vector(4  downto 0);			--Write address
		w_data				: in std_logic_vector(31 downto 0);			--Write data
		--OUTPUT
		Imm					: out std_logic_vector(31 downto 0);		--Immediate value
		pc_out				: out std_logic_vector(9  downto 0);		--Program counter, delayed by 1 cycle
		instruction_out	: out std_logic_vector(31 downto 0);		--The instruction, delayed by 1 cycle
		RS1					: out std_logic_vector(31 downto 0);		--The data from RS1
		RS2					: out std_logic_vector(31 downto 0)			--The data from RS2
	);
end entity Decode;

architecture behavioral of Decode is
	
	-- Build a 2-D array type for the RAM
	subtype reg_t is std_logic_vector(31 downto 0);
	type memory_t is array(31 downto 0) of reg_t;
	
	-- Declare the RAM signal.
	signal ram 		: memory_t;
	signal opcode 	: std_logic_vector(5  downto 0);
	signal rd		: natural;
	signal r1		: natural;
	signal r2		: natural;
	signal im_val	: std_logic_vector(15 downto 0);
	
begin

	--rename some parts of the input instruction
	opcode 	<= instruction_in(31 downto 26);
	rd	   	<= to_integer(unsigned(instruction_in(25 downto 21)));
	r1			<= to_integer(unsigned(instruction_in(20 downto 16)));
	r2 		<= to_integer(unsigned(instruction_in(15 downto 11)));
	im_val 	<= instruction_in(15 downto 0);
	
	--Signals that just get delayed and passed on
	process(clk) begin
		if rising_edge(clk) then
			pc_out <= pc_in;
			instruction_out <= instruction_in;
		end if;
	end process;
	
	--Write
	process(clk) begin
		if rising_edge(clk) and opIsWriteBack(w_instruction(31 downto 26)) = '1' and w_instruction(25 downto 21) /= B"00000" then
			ram(to_integer(unsigned(w_instruction(25 downto 21)))) <= w_data;
		else
			ram(0) <= X"00000000";
		end if;
	end process;
	
	--Read
	process(clk) begin
		if rising_edge(clk) then
			if opcode = OP_NOP or opcode = OP_J or opcode = OP_JAL then
				RS1 <= (others => '0');
				RS2 <= (others => '0');
				Imm <= (others => '0');
			elsif opcode = OP_LW or opcode = OP_SW then
				RS1 <= ram(r1);
				RS2 <= ram(rd);
				Imm(15 downto 0) <= im_val;
				Imm(31 downto 16) <= (others => '0');	
			elsif opcode = OP_JR or opcode = OP_JALR or opcode = OP_BEQZ or opcode = OP_BNEZ then
				RS1 <= ram(r1);
				RS2 <= (others => '0');
				Imm <= (others => '0');
			elsif opcode = OP_ADDI or opcode = OP_SUBI or opcode = OP_SLTI or opcode = OP_SGTI or opcode = OP_SLEI or opcode = OP_SGEI or
					opcode = OP_SEQI or opcode = OP_SNEI then
				RS1 <= ram(r1);
				RS2 <= (others => '0');
				Imm(15 downto 0) <= im_val;
				Imm(31 downto 16) <= (others => im_val(15));	
			elsif opcode = OP_ADDUI or opcode = OP_SUBUI or opcode = OP_ANDI or opcode = OP_ORI or opcode = OP_XORI or opcode = OP_SLLI or
					opcode = OP_SRLI or opcode = OP_SRAI or opcode = OP_SLTUI or opcode =OP_SGTUI or opcode = OP_SLEUI or opcode = OP_SGEUI then
				RS1 <= ram(r1);
				RS2 <= (others => '0');
				Imm(15 downto 0) <= im_val;
				Imm(31 downto 16) <= (others => '0');		
			elsif opcode = OP_ADD or opcode = OP_ADDU or opcode = OP_SUB or opcode = OP_SUBU or opcode = OP_AND or opcode = OP_OR or
					opcode = OP_XOR or opcode = OP_SLL or opcode = OP_SRL or opcode = OP_SRA or opcode = OP_SLT or opcode = OP_SLTU or 
					opcode = OP_SGT or opcode = OP_SGTU or opcode = OP_SLE or opcode = OP_SLEU or opcode = OP_SGE or opcode = OP_SGEU or
					opcode = OP_SEQ or opcode = OP_SNE then
				RS1 <= ram(r1);
				RS2 <= ram(r2);
				Imm <= (others => '0');
			else
				RS1 <= (others => '0');
				RS2 <= (others => '0');
				Imm <= (others => '0');
			end if;
		end if;
	end process;

end architecture behavioral;