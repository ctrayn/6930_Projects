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
		MAX10_CLK1_50		: in  std_logic;
		MAX10_CLK2_50		: in  std_logic;
		RST_L					: in  std_logic;
		KEY1					: in  std_logic;
		RX						: in  std_logic;
		-- OUTPUT
		TX						: out std_logic;

		-- TEMP: for testing
		br_taken	: in std_logic;
		br_addr	: in std_logic_vector(9 downto 0);
		w_inst	: in std_logic_vector(31 downto 0);
		w_data	: in std_logic_vector(31 downto 0)
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
			w_inst			: in std_logic_vector(31 downto 0);
			w_data			: in std_logic_vector(31 downto 0);
			-- OUTPUT
			Imm				: out std_logic_vector(31 downto 0);
			pc_out			: out std_logic_vector(9  downto 0);
			inst_out			: out std_logic_vector(31 downto 0);
			RS1				: out std_logic_vector(31 downto 0);
			RS2				: out std_logic_vector(31 downto 0)
		);
	end component;

	-- Singnals
	-- Between fetch and decode
	signal pc_FD 			: std_logic_vector(9 downto 0);
	signal inst_FD 		: std_logic_vector(31 downto 0);
	-- Between decode and execute
	signal pc_DE 			: std_logic_vector(9 downto 0);
	signal inst_DE 		: std_logic_vector(31 downto 0);
	signal imm_DE			: std_logic_vector(31 downto 0);
	signal rs1_DE			: std_logic_vector(31 downto 0);
	signal rs2_DE			: std_logic_vector(31 downto 0);
	-- Between execute and memory

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
		w_inst => w_inst,					-- TEST!!!
		w_data => w_data,					-- TEST!!!
		Imm => imm_DE,
		pc_out => pc_DE,
		inst_out => inst_DE,
		RS1 => rs1_DE,
		RS2 => rs2_DE
	);
end architecture behavioral;
