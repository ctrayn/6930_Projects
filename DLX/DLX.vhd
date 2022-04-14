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
		RST_L					: in  std_logic;
		RX						: in  std_logic;
		SW						: in std_logic_vector(9 downto 0);
		
		--OUTPUT
		HEX0 					: out std_logic_vector(7 downto 0);
		HEX1 					: out std_logic_vector(7 downto 0);
		HEX2 					: out std_logic_vector(7 downto 0);
		HEX3 					: out std_logic_vector(7 downto 0);
		HEX4 					: out std_logic_vector(7 downto 0);
		HEX5 					: out std_logic_vector(7 downto 0);
		LEDR					: out std_logic_vector(9 downto 0);
		TX						: out std_logic
		-- UNUSED
		--MAX10_CLK1_50		: in  std_logic;
		--MAX10_CLK2_50		: in  std_logic;
		--KEY 					: in std_logic_vector(1 downto 0);
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
			SW					: in std_logic_vector(9  downto 0);
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
			RS2				: out std_logic_vector(31 downto 0);
			tap_ram			: out std_logic_vector(31 downto 0);

			-- UART
			rx_data_empty	: in std_logic;
			rx_data			: in std_logic_vector(31 downto 0);
			rx_ack			: out std_logic := '0';

			-- Timer
			tmr_go			: out std_logic;
			tmr_stop			: out std_logic;
			tmr_rst			: out std_logic	
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
			TX_empty		: out std_logic;
			TX_full		: out std_logic;
			d_rx			: out std_logic_vector(31 downto 0);
			RX_empty		: out std_logic
		);
	end component;
	
	component Timer is
		port (
			--INPUT
			clk		: in std_logic;
			rst_l		: in std_logic;
			GO			: in std_logic;
			STOP		: in std_logic;
			Restart	: in std_logic;
			SW			: in std_logic_vector(9 downto 0);
			tap_ram	: in std_logic_vector(31 downto 0);
			
			--OUTPUT
			HEX0 		: out std_logic_vector(7 downto 0);
			HEX1 		: out std_logic_vector(7 downto 0);
			HEX2 		: out std_logic_vector(7 downto 0);
			HEX3 		: out std_logic_vector(7 downto 0);
			HEX4 		: out std_logic_vector(7 downto 0);
			HEX5 		: out std_logic_vector(7 downto 0)
		);
	end component;
	
	component pll IS
	PORT
	(
		areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		c0				: OUT STD_LOGIC 
	);
	end component;
	signal CLK : std_logic;

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
	signal tx_empty		: std_logic;
	signal tx_full			: std_logic;
	signal tx_write		: std_logic;
	signal tx_data 		: std_logic_vector(35 downto 0);
	signal rx_data			: std_logic_vector(31 downto 0);
	signal rx_ack			: std_logic;
	signal rx_empty		: std_logic;
	-- Timer signals
	signal tmr_go			: std_logic;
	signal tmr_stop		: std_logic;
	signal tmr_rst			: std_logic;
	-- Tap signals
	signal tap_ram			: std_logic_vector(31 downto 0);

begin
	LEDR <= SW;

	duart : UART port map (
		-- INPUT
		clk 			=> CLK,
		rst_l 		=> RST_L,
		RX 			=> RX,
		wr_req 		=> tx_write,	
		rd_req 		=> rx_ack,
		d_tx 			=> tx_data,
		--OUTPUT
		TX 			=> TX,		
		TX_empty 	=> tx_empty,
		TX_full 		=> tx_full,
		d_rx			=> rx_data,
		RX_empty		=> rx_empty
	);

	-- Instance of fetch
	fet : Fetch port map(
		-- INPUT
		clk => CLK,
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
		clk => CLK,
		rst_l	=> RST_L,
		SW => SW,
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
		RS2 => rs2_DE,
		tap_ram => tap_ram,
		-- UART
		rx_data_empty => rx_empty,
		rx_data => rx_data,
		rx_ack => rx_ack,
		-- Timer
		tmr_go => tmr_go,
		tmr_stop => tmr_stop,
		tmr_rst => tmr_rst
	);

	-- Instance of execute
	exc : Execute port map(
		--INPUT
		clk => CLK,
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
		data_tx => tx_data,
		tx_write => tx_write
	);

	-- Instance of memory
	mem : Memory port map(
		--INPUT
		clk => CLK,
		rst_l => rst_l,
		ALU_in => alu_EM,
		RS2_in => rs2_EM,
		inst_in => inst_EM,
		--OUTPUT
		data_out	=> wb_data,
		inst_out => wb_inst
	);
	
	tmr : Timer port map(
		--INPUT
		clk => ADC_CLK_10,
		rst_l => rst_l,
		GO => tmr_go,
		STOP => tmr_stop,
		Restart => tmr_rst,
		SW => SW,
		tap_ram => tap_ram,
		--OUTPUT
		HEX0 => HEX0,
		HEX1 => HEX1,
		HEX2 => HEX2,
		HEX3 => HEX3,
		HEX4 => HEX4,
		HEX5 => HEX5
	);
	
	clk_pll : PLL port map (
		areset => rst_l,
		inclk0 => ADC_CLK_10,
		c0		 => CLK
	);

end architecture behavioral;
