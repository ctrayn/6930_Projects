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
		SW						: in std_logic_vector(9  downto 0);
		pc_in					: in std_logic_vector(9  downto 0);
		inst_in				: in std_logic_vector(31 downto 0);
		wb_inst				: in std_logic_vector(31 downto 0);			--Write instruction
		wb_data				: in std_logic_vector(31 downto 0);			--Write data
		br_taken				: in std_logic;
		--OUTPUT
		Imm					: out std_logic_vector(31 downto 0);		--Immediate value
		pc_out				: out std_logic_vector(9  downto 0);		--Program counter, delayed by 1 cycle
		inst_out				: out std_logic_vector(31 downto 0);		--The instruction, delayed by 1 cycle
		RS1					: out std_logic_vector(31 downto 0);		--The data from RS1
		RS2					: out std_logic_vector(31 downto 0);			--The data from RS2
		tap_ram				: out std_logic_vector(31 downto 0);

		--UART
		rx_data_empty		: in std_logic;
		rx_data				: in std_logic_vector(31 downto 0);
		rx_ack				: out std_logic := '0';

		-- Timer
		tmr_go				: out std_logic := '0';
		tmr_stop				: out std_logic := '0';
		tmr_rst				: out std_logic := '0'
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
	opcode 	<= inst_in(31 downto 26);
	rd	   	<= to_integer(unsigned(inst_in(25 downto 21)));
	r1			<= to_integer(unsigned(inst_in(20 downto 16)));
	r2 		<= to_integer(unsigned(inst_in(15 downto 11)));
	im_val 	<= inst_in(15 downto 0);
	
	--Non-delayed signals
	process(SW, ram) begin
		tap_ram <= ram(to_integer(unsigned(SW(4 downto 0))));
	end process;

	--Signals that just get delayed and passed on
	process(clk) begin
		if rising_edge(clk) then
			if br_taken = '0' then
				inst_out <= inst_in;
			else
				inst_out <= (others => '0');
			end if;
			pc_out <= pc_in;
		end if;
	end process;

	-- UART
	process(clk) begin
		if rising_edge(clk) then
			if opIsUARTrx(wb_inst(31 downto 26)) = '1' and rx_data_empty = '0' then
				rx_ack <= '1';
			else
				rx_ack <= '0';
			end if;
		end if;
	end process;

	-- Timer
	process(clk) begin
		if rising_edge(clk) then
			if wb_inst(31 downto 26) = OP_TGO then
				tmr_go <= '1';
				tmr_stop <= '0';
				tmr_rst <= '0';
			elsif wb_inst(31 downto 26) = OP_TSP then
				tmr_go <= '0';
				tmr_stop <= '1';
				tmr_rst <= '0';
			elsif wb_inst(31 downto 26) = OP_TR then
				tmr_go <= '0';
				tmr_stop <= '0';
				tmr_rst <= '1';
			else
				tmr_go <= '0';
				tmr_stop <= '0';
				tmr_rst <= '0';
			end if;
		end if;
	end process;

	--Write
	process(clk) begin
		if rising_edge(clk) then
			if opIsWriteBack(wb_inst(31 downto 26)) = '1' and wb_inst(25 downto 21) /= B"00000" then
				ram(to_integer(unsigned(wb_inst(25 downto 21)))) <= wb_data;
			elsif wb_inst(31 downto 26) = OP_JAL or wb_inst(31 downto 26) = OP_JALR then
				ram(31) <= wb_data;
			elsif opIsUARTrx(wb_inst(31 downto 26)) = '1' then
				-- If there is data ready, store in rd
				if rx_data_empty = '0' then
					ram(to_integer(unsigned((wb_inst(20 downto 16))))) <= rx_data;
				-- If there isn't data ready
				else
					ram(0) <= ZEROS;
				end if;
			else
				ram(0) <= X"00000000"; -- Register 0 must allways contain 0
			end if;
		end if;
	end process;

	--Read
	process(clk) begin
		if rising_edge(clk) then
			case opcode is
				when OP_NOP =>
					RS1 <= (others => '0');
					RS2 <= (others => '0');
					Imm <= (others => '0');

				when OP_LW =>
					RS1 <= ram(r1);
					RS2(31 downto 16) <= (others => '0');
					RS2(15 downto 0)  <= im_val;
					Imm <= (others => '0');

				when OP_SW =>
					RS1 <= ram(r1);
					RS2 <= ram(rd);
					Imm(31 downto 16) <= (others => '0');
					Imm(15 downto 0)  <= im_val;

				when OP_JR | OP_JALR =>
					RS1 <= ram(r1);
					RS2 <= (others => '0');
					Imm <= (others => '0');

				when OP_J | OP_JAL =>
					RS1 <= (others => '0');
					RS2 <= (others => '0');
					Imm(31 downto 26) <= (others => '0');
					Imm(25 downto 0) <= inst_in(25 downto 0);

				when OP_BEQZ | OP_BNEZ =>
					RS1 <= ram(rd);
					RS2 <= (others => '0');
					Imm(31 downto 21) <= (others => '0');
					Imm(20 downto 0) <= inst_in(20 downto 0);

				when OP_ADD | OP_ADDU | OP_SUB | OP_SUBU =>
					RS1 <= ram(r1);
					RS2 <= ram(r2);
					Imm <= (others => '0');

				when OP_ADDI | OP_SUBI =>
					RS1 <= ram(r1);
					RS2 <= (others => '0');
					Imm(31 downto 16) <= (others => im_val(15));		--sign extend
					Imm(15 downto 0) <= im_val;

				when OP_ADDUI | OP_SUBUI =>
					RS1 <= ram(r1);
					RS2 <= (others => '0');
					Imm(31 downto 16) <= (others => '0');		--sign extend
					Imm(15 downto 0) <= im_val;

				when OP_AND | OP_OR | OP_XOR =>
					RS1 <= ram(r1);
					RS2 <= ram(r2);
					Imm <= (others => '0');

				when OP_ANDI | OP_ORI | OP_XORI =>
					RS1 <= ram(r1);
					RS2 <= (others => '0');
					Imm(31 downto 16) <= (others => '0');
					Imm(15 downto 0) <= im_val;

				when OP_SLL | OP_SRL | OP_SRA =>
					RS1 <= ram(r1);
					RS2 <= ram(r2);
					Imm <= (others => '0');

				when OP_SLLI | OP_SRLI | OP_SRAI =>
					RS1 <= ram(r1);
					RS2 <= ram(r2);
					Imm(31 downto 16) <= (others => '0');
					Imm(15 downto 0) <= im_val;

				when OP_SLT | OP_SLTU | OP_SGT | OP_SGTU =>
					RS1 <= ram(r1);
					RS2 <= ram(r2);
					Imm <= (others => '0');

				when OP_SLTI | OP_SGTI  =>
					RS1 <= ram(r1);
					RS2 <= (others => '0');
					Imm(31 downto 16) <= (others => im_val(15));		--sign extend
					Imm(15 downto 0) <= im_val;

				when OP_SLTUI | OP_SGTUI =>
					RS1 <= ram(r1);
					RS2 <= (others => '0');
					Imm(15 downto 0) <= im_val;
					Imm(16 downto 0) <= (others => '0');

				when OP_SLE | OP_SLEU | OP_SGE | OP_SGEU | OP_SEQ | OP_SNE =>
					RS1 <= ram(r1);
					RS2 <= ram(r2);
					Imm <= (others => '0');

				when OP_SLEI | OP_SGEI | OP_SEQI | OP_SNEI =>
					RS1 <= ram(r1);
					RS2 <= (others => '0');
					Imm(15 downto 0) <= im_val;
					Imm(31 downto 16) <= (others => im_val(15));		--sign extend

				when OP_SLEUI | OP_SGEUI =>
					RS1 <= ram(r1);
					RS2 <= (others => '0');
					Imm(15 downto 0) <= im_val;
					Imm(16 downto 0) <= (others => '0');
					
				when OP_PCH | OP_PD | OP_PDU =>
					RS1 <= ram(r1);
					RS2 <= (others => '0');
					Imm <= (others => '0');

				when others =>
					RS1 <= (others => '0');
					RS2 <= (others => '0');
					Imm <= (others => '0');

			end case;
		end if;
	end process;

end architecture behavioral;
