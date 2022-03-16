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
		inst_in				: in std_logic_vector(31 downto 0);
		wb_inst				: in std_logic_vector(31 downto 0);			--Write instruction
		wb_data				: in std_logic_vector(31 downto 0);			--Write data
		stall					: in std_logic;									
		br_taken				: in std_logic;									--If a jump happens, clear the contents of this stage
		ALU_in				: in std_logic_vector(31 downto 0);
		--OUTPUT
		Imm					: out std_logic_vector(31 downto 0);		--Immediate value
		pc_out				: out std_logic_vector(9  downto 0);		--Program counter, delayed by 1 cycle
		inst_out				: out std_logic_vector(31 downto 0);		--The instruction, delayed by 1 cycle
		RS1					: out std_logic_vector(31 downto 0);		--The data from RS1
		RS2					: out std_logic_vector(31 downto 0)			--The data from RS2_loc
	);
end entity Decode;

architecture behavioral of Decode is

	-- Build a 2-D array type for the RAM
	subtype reg_t is std_logic_vector(31 downto 0);
	type memory_t is array(31 downto 0) of reg_t;

	-- Declare the RAM signal.
	signal ram 			: memory_t;
	signal opcode 		: std_logic_vector(5  downto 0);
	signal rd			: natural;
	signal r1			: natural;
	signal r2			: natural;
	signal im_val		: std_logic_vector(15 downto 0);
	signal pc_output	: std_logic_vector(9 downto 0);
	signal inst_output: std_logic_vector(31 downto 0);
	signal true 		: std_logic_vector(1 downto 0);
	signal wb_rs1		: std_logic_vector(4 downto 0);
	signal wb_OP		: std_logic_vector(5 downto 0);
	signal RS1_loc, RS2_loc, Imm_loc : std_logic_vector(31 downto 0);

begin
	RS1 <= RS1_loc;
	RS2 <= RS2_loc;
	Imm <= Imm_loc;

	--rename some parts of the input instruction
	opcode 	<= inst_in(31 downto 26);
	rd	   	<= to_integer(unsigned(inst_in(25 downto 21)));
	r1			<= to_integer(unsigned(inst_in(20 downto 16)));
	r2 		<= to_integer(unsigned(inst_in(15 downto 11)));
	im_val 	<= inst_in(15 downto 0);
	pc_out 	<= pc_output;
	inst_out <= inst_output;
	wb_rs1   <= wb_inst(25 downto 21);
	wb_OP		<= wb_inst(31 downto 26);

	--Signals that just get delayed and passed on
	process(clk, stall, rst_l) begin
		if rising_edge(clk) then
			if rst_l = '0' then
				pc_output <= (others => '0');
				inst_output <= (others => '0');
			elsif stall = '1' then
				pc_output <= pc_output;
				inst_output <= inst_output;
			else
				pc_output <= pc_in;
				inst_output <= inst_in;
			end if;
		end if;
	end process;

	--Write
	process(clk, br_taken) begin
		if rising_edge(clk) and br_taken = '0' then					-- Don't write anything if a branch is taken
			if wb_OP = OP_LW and wb_rs1 /= B"00000" then 
				true <= B"10";
				ram(to_integer(unsigned(wb_rs1))) <= wb_data;
			elsif (unsigned(wb_OP) >= unsigned(OP_ADD)) and (unsigned(wb_OP) <= unsigned(OP_SNEI)) and wb_rs1 /= B"00000" then 
				true <= B"01";
				ram(to_integer(unsigned(wb_rs1))) <= ALU_in;						
--			if opIsWriteBack(wb_inst(31 downto 26)) = '1' and wb_inst(25 downto 21) /= B"00000" then
--				true <= '1';
--				ram(to_integer(unsigned(wb_inst(25 downto 21)))) <= wb_data;
			elsif wb_inst(31 downto 26) = OP_JAL or wb_inst(31 downto 26) = OP_JALR then
				true <= B"00";
				ram(31) <= wb_data;
			else
				true <= B"00";
				ram(0) <= X"00000000"; -- Register 0 must allways contain 0
			end if;
		end if;
	end process;

	--Read
	process(clk, rst_l, stall, br_taken) begin
		if (rst_l = '0') or (br_taken = '1') then			--Clear the stage
				RS1_loc <= (others => '0');
				RS2_loc <= (others => '0');
				Imm_loc <= (others => '0');
		elsif stall = '1' then
			RS1_loc <= RS1_loc;
			RS2_loc <= RS2_loc;
			Imm_loc <= Imm_loc;
		else
			if rising_edge(clk) then
				case opcode is
					when OP_NOP =>
						RS1_loc <= (others => '0');
						RS2_loc <= (others => '0');
						Imm_loc <= (others => '0');

					when OP_LW =>
						RS1_loc <= (others => '0');
--						RS2_loc <= ram(r1);
						RS2_loc <= (others => '0');
						Imm_loc(31 downto 16) <= (others => '0');
						Imm_loc(15 downto 0)  <= im_val;

					when OP_SW =>
						RS1_loc <= ram(r1);
						RS2_loc <= ram(rd);
						Imm_loc(31 downto 16) <= (others => '0');
						Imm_loc(15 downto 0)  <= im_val;

					when OP_JR | OP_JALR =>
						RS1_loc <= ram(r1);
						RS2_loc <= (others => '0');
						Imm_loc <= (others => '0');

					when OP_J | OP_JAL =>
						RS1_loc <= (others => '0');
						RS2_loc <= (others => '0');
						Imm_loc(31 downto 26) <= (others => '0');
						Imm_loc(25 downto 0) <= inst_in(25 downto 0);

					when OP_BEQZ | OP_BNEZ =>
						RS1_loc <= ram(rd);
						RS2_loc <= (others => '0');
						Imm_loc(31 downto 21) <= (others => '0');
						Imm_loc(20 downto 0) <= inst_in(20 downto 0);

					when OP_ADD | OP_ADDU | OP_SUB | OP_SUBU =>
						RS1_loc <= ram(r1);
						RS2_loc <= ram(r2);
						Imm_loc <= (others => '0');

					when OP_ADDI | OP_SUBI =>
						RS1_loc <= ram(r1);
						RS2_loc <= (others => '0');
						Imm_loc(31 downto 16) <= (others => im_val(15));		--sign extend
						Imm_loc(15 downto 0) <= im_val;

					when OP_ADDUI | OP_SUBUI =>
						RS1_loc <= ram(r1);
						RS2_loc <= (others => '0');
						Imm_loc(31 downto 16) <= (others => '0');		--sign extend
						Imm_loc(15 downto 0) <= im_val;

					when OP_AND | OP_OR | OP_XOR =>
						RS1_loc <= ram(r1);
						RS2_loc <= ram(r2);
						Imm_loc <= (others => '0');

					when OP_ANDI | OP_ORI | OP_XORI =>
						RS1_loc <= ram(r1);
						RS2_loc <= (others => '0');
						Imm_loc(31 downto 16) <= (others => '0');
						Imm_loc(15 downto 0) <= im_val;

					when OP_SLL | OP_SRL | OP_SRA =>
						RS1_loc <= ram(r1);
						RS2_loc <= ram(r2);
						Imm_loc <= (others => '0');

					when OP_SLLI | OP_SRLI | OP_SRAI =>
						RS1_loc <= ram(r1);
						RS2_loc <= ram(r2);
						Imm_loc(31 downto 16) <= (others => '0');
						Imm_loc(15 downto 0) <= im_val;

					when OP_SLT | OP_SLTU | OP_SGT | OP_SGTU =>
						RS1_loc <= ram(r1);
						RS2_loc <= ram(r2);
						Imm_loc <= (others => '0');

					when OP_SLTI | OP_SGTI  =>
						RS1_loc <= ram(r1);
						RS2_loc <= (others => '0');
						Imm_loc(31 downto 16) <= (others => im_val(15));		--sign extend
						Imm_loc(15 downto 0) <= im_val;

					when OP_SLTUI | OP_SGTUI =>
						RS1_loc <= ram(r1);
						RS2_loc <= (others => '0');
						Imm_loc(15 downto 0) <= im_val;
						Imm_loc(16 downto 0) <= (others => '0');

					when OP_SLE | OP_SLEU | OP_SGE | OP_SGEU | OP_SEQ | OP_SNE =>
						RS1_loc <= ram(r1);
						RS2_loc <= ram(r2);
						Imm_loc <= (others => '0');

					when OP_SLEI | OP_SGEI | OP_SEQI | OP_SNEI =>
						RS1_loc <= ram(r1);
						RS2_loc <= (others => '0');
						Imm_loc(15 downto 0) <= im_val;
						Imm_loc(31 downto 16) <= (others => im_val(15));		--sign extend

					when OP_SLEUI | OP_SGEUI =>
						RS1_loc <= ram(r1);
						RS2_loc <= (others => '0');
						Imm_loc(15 downto 0) <= im_val;
						Imm_loc(16 downto 0) <= (others => '0');

					when others =>
						RS1_loc <= (others => '0');
						RS2_loc <= (others => '0');
						Imm_loc <= (others => '0');

				end case;
			end if;
		end if;
	end process;

end architecture behavioral;
