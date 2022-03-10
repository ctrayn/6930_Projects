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
		RST_L					: in  std_logic
		--KEY1					: in  std_logic;
		--RX						: in  std_logic;
		-- OUTPUT
		--TX						: out std_logic
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
	end component;

	component Memory is
		port (
			--INPUT
			clk 		: in std_logic;
			rst_l 	: in std_logic;
			ALU_in 	: in std_logic_vector(31 downto 0);
			RS2_in	: in std_logic_vector(31 downto 0);
			inst_in	: in std_logic_vector(31 downto 0);
			--OUTPUT
			data_out	: out std_logic_vector(31 downto 0);
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
	signal alu_EM			: std_logic_vector(31 downto 0);
	signal rs2_EM			: std_logic_vector(31 downto 0);
	signal inst_EM			: std_logic_vector(31 downto 0);
	-- Between execute and fetch
	signal br_taken		: std_logic;
	signal br_addr			: std_logic_vector(9  downto 0);
	-- Between memory and decode
	signal wb_data			: std_logic_vector(31 downto 0);
	signal wb_inst 		: std_logic_vector(31 downto 0);

begin

	-- Instance of fetch
	fet : Fetch port map(
		-- INPUT
		clk => ADC_CLK_10,
		rst_l => RST_L,
		br_taken => br_taken,
		br_addr => br_addr,
		-- OUTPUT
		inst_out	=> inst_FD,
		pc_out => pc_FD
	);

	-- Instance of decode
	dec : Decode port map(
		-- INPUT
		clk => ADC_CLK_10,
		rst_l	=> RST_L,
		pc_in	=> pc_FD,
		inst_in => inst_FD,
		wb_inst => wb_inst,
		wb_data => wb_data,
		-- OUTPUT
		Imm => imm_DE,
		pc_out => pc_DE,
		inst_out => inst_DE,
		RS1 => rs1_DE,
		RS2 => rs2_DE
	);

	-- Instance of execute
	exc : Execute port map(
		--INPUT
		clk => ADC_CLK_10,
		rst_l => RST_L,
		pc_in => pc_DE,
		inst_in => inst_DE,
		RS1 => rs1_DE,
		RS2 => rs2_DE,
		Imm => imm_DE,
		ALU_MW => wb_data,
		OP_EM => inst_EM,
		OP_MW	=> wb_inst,
		--OUTPUT
		ALU_out => alu_EM,
		br_taken => br_taken,
		br_addr => br_addr,
		RS2_out => rs2_EM,
		inst_out => inst_EM
	);

	-- Instance of memory
	mem : Memory port map(
		--INPUT
		clk => ADC_CLK_10,
		rst_l => rst_l,
		ALU_in => alu_EM,
		RS2_in => rs2_EM,
		inst_in => inst_EM,
		--OUTPUT
		data_out	=> wb_data,
		inst_out => wb_inst
	);

end architecture behavioral;
