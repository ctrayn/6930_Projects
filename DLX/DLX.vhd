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

entity DLX is
	port(
		-- INPUT
		ADC_CLK_10 			: in 	std_logic;
		--MAX10_CLK1_50		: in  std_logic;
		--MAX10_CLK2_50		: in  std_logic;
		RST_L					: in  std_logic;
		--KEY1					: in  std_logic;
		--RX						: in  std_logic;
		-- OUTPUT
		--TX						: out std_logic;

		-- TEMP: for testing
--		br_taken	: in  std_logic;
--		br_addr	: in  std_logic_vector(9 downto 0);
		wb_inst	: in  std_logic_vector(31 downto 0);
		wb_data	: in  std_logic_vector(31 downto 0);
--		pc_DE 	: out std_logic_vector(9 downto 0);
--		inst_DE 	: out std_logic_vector(31 downto 0);
--		imm_DE	: out std_logic_vector(31 downto 0);
--		rs1_DE	: out std_logic_vector(31 downto 0);
--		rs2_DE	: out std_logic_vector(31 downto 0)
		alu_ex		: out std_logic_vector(31 downto 0);
		rs2_ex		: out std_logic_vector(31 downto 0);
		inst_ex		: out std_logic_vector(31 downto 0)
	);
end entity DLX;

architecture behavioral of DLX is

	-- Components
	component Fetch is
		port (
			-- INPUT
			clk 				: in std_logic;
			rst_l				: in std_logic;
			br_taken 		: in std_logic;
			br_addr			: in std_logic_vector(9 downto 0);
			-- OUTPUT
			inst_out			: out std_logic_vector(31 downto 0);
			pc_out			: out std_logic_vector(9 downto 0)
		);
	end component;

	component Decode is
		port (
			-- INPUT
			clk				: in std_logic;
			rst_l				: in std_logic;
			pc_in				: in std_logic_vector(9  downto 0);
			inst_in			: in std_logic_vector(31 downto 0);
			wb_inst			: in std_logic_vector(31 downto 0);
			wb_data			: in std_logic_vector(31 downto 0);
			-- OUTPUT
			Imm				: out std_logic_vector(31 downto 0);
			pc_out			: out std_logic_vector(9  downto 0);
			inst_out			: out std_logic_vector(31 downto 0);
			RS1				: out std_logic_vector(31 downto 0);
			RS2				: out std_logic_vector(31 downto 0)
		);
	end component;
	
	component Execute is
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
	end component;

	-- Singnals
	-- Between fetch and decode
	signal pc_FD 			: std_logic_vector(9  downto 0);
	signal inst_FD 		: std_logic_vector(31 downto 0);
	-- Between decode and execute
	signal pc_DE 			: std_logic_vector(9  downto 0);
	signal inst_DE 		: std_logic_vector(31 downto 0);
	signal imm_DE			: std_logic_vector(31 downto 0);
	signal rs1_DE			: std_logic_vector(31 downto 0);
	signal rs2_DE			: std_logic_vector(31 downto 0);
	-- Between execute and memory
--	signal alu_ex			: std_logic_vector(31 downto 0);
	signal br_taken		: std_logic;
	signal br_addr			: std_logic_vector(9  downto 0);
--	signal rs2_ex			: std_logic_vector(31 downto 0);
--	signal inst_ex			: std_logic_vector(31 downto 0);
	-- Between memory and writeBack


begin

	-- Instance of fetch
	fet : Fetch port map(
		clk => ADC_CLK_10,
		rst_l => RST_L,
		br_taken => br_taken,			-- TEST!!!
		br_addr => br_addr,				-- TEST!!!
		inst_out	=> inst_FD,
		pc_out => pc_FD
	);

	-- Instance of decode
	dec : Decode port map(
		clk => ADC_CLK_10,
		rst_l	=> RST_L,
		pc_in	=> pc_FD,
		inst_in => inst_FD,
		wb_inst => wb_inst,				-- TEST!!!
		wb_data => wb_data,				-- TEST!!!
		Imm => imm_DE,
		pc_out => pc_DE,
		inst_out => inst_DE,
		RS1 => rs1_DE,
		RS2 => rs2_DE
	);
	
	exc : Execute port map(
		--INPUT
		clk => ADC_CLK_10,
		rst_l => RST_L,
		pc_in => pc_DE,
		inst_in => inst_DE,
		RS1 => rs1_DE,
		RS2 => rs2_DE,
		Imm => imm_DE,
		--OUTPUT
		ALU_out => alu_ex,
		br_taken => br_taken,
		br_addr => br_addr,
		RS2_out => rs2_ex,
		inst_out => inst_ex
	);
end architecture behavioral;
