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
--		KEY 					: in std_logic_vector(1 downto 0);
		RX						: in  std_logic;
		-- OUTPUT
		TX						: out std_logic
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
			br_taken			: in std_logic;
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
			clk 			: in std_logic;
			rst_l 		: in std_logic;
			pc_in 		: in std_logic_vector(9  downto 0);
			inst_in 		: in std_logic_vector(31 downto 0);
			RS1 			: in std_logic_vector(31 downto 0);
			RS2 			: in std_logic_vector(31 downto 0);
			Imm 			: in std_logic_vector(31 downto 0);
			MemWb_inst	: in std_logic_vector(31 downto 0);
			MemWb_data	: in std_logic_vector(31 downto 0);
			--OUTPUT
			ALU_out 		: out std_logic_vector(31 downto 0);
			br_taken 	: out std_logic;
			br_addr  	: out std_logic_vector(9 downto 0);
			RS2_out 		: out std_logic_vector(31 downto 0);
			inst_out 	: out std_logic_vector(31 downto 0);
			data_tx		: out std_logic_vector(35 downto 0);
			tx_write		: out std_logic
		);
	end component;

	component Memory is
		port (
			--INPUT
			clk 			: in std_logic;
			rst_l 		: in std_logic;
			ALU_in 		: in std_logic_vector(31 downto 0);
			RS2_in		: in std_logic_vector(31 downto 0);
			inst_in		: in std_logic_vector(31 downto 0);
			--OUTPUT
			data_out		: out std_logic_vector(31 downto 0);
			inst_out 	: out std_logic_vector(31 downto 0)
		);
	end component;
	
	component UART is
		port (
			--INPUT
			clk			: in std_logic;
			rst_l			: in std_logic;
			RX 			: in std_logic;			--Connected to pin 40 on J1 (white wire)
			wr_req		: in std_logic;
			rd_req		: in std_logic;
			d_tx			: in std_logic_vector(35 downto 0); 		-- The data should only be 32 bits; [33:32] : 00 is char, 01 is signed 10 is unsigned; [35:34] are unused but I couldn't only make the FIFO 36 bits
			
			--OUTPUT
			TX 			: out std_logic; 			--Connected to pin 39 on J1 (green wire)
			TX_empty	: out std_logic;
			TX_full	: out std_logic
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
	-- Between memory and execute
	signal inst_ME			: std_logic_vector(31 downto 0);
	signal data_ME			: std_logic_vector(31 downto 0);
	-- Between writeback and execute
	signal inst_WE			: std_logic_vector(31 downto 0);
	signal data_WE			: std_logic_vector(31 downto 0);
	-- UART signals
	signal empty, full	: std_logic;
	signal UART_write		: std_logic;
	signal data_tx			: std_logic_vector(35 downto 0);
	signal rx_rd_req		: std_logic;

begin

	duart : UART port map (
		-- INPUT
		clk 			=> ADC_CLK_10,
		rst_l 		=> RST_L,
		RX 			=> RX,
		wr_req 		=> UART_write,	
		rd_req 		=> rx_rd_req,
		d_tx 			=> data_tx,
		--OUTPUT
		TX 			=> TX,		
		TX_empty 	=> empty,
		TX_full 	=> full
	);

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
		br_taken => br_taken,
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
		MemWb_inst => wb_inst,	
		MemWb_data => wb_data,
		--OUTPUT
		ALU_out => alu_EM,
		br_taken => br_taken,
		br_addr => br_addr,
		RS2_out => rs2_EM,
		inst_out => inst_EM,
		data_tx => data_tx,
		tx_write => UART_write
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
