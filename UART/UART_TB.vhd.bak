library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity my_UART_TB is
end entity my_UART_TB;

architecture behavioral of my_UART_TB is

signal ADC_CLK_10	 	: std_logic;
signal rst_l			: std_logic;
 
constant clk_div		: unsigned(15 downto 0) := x"0208";	
signal rx 				: std_logic;		
signal tx 				: std_logic;
signal tx_flag 		: std_logic;
signal rx_flag 		: std_logic;
signal data_tx 		: unsigned(7 downto 0);
signal data_rx			: unsigned(7 downto 0);
			
constant clk_period	: time := 100 ns;
constant delay			: time := 127 ns;

component my_UART is
	port(
		clk   	: in  std_logic;
		clk_div  : in  unsigned(15 downto 0);
		rst_l 	: in  std_logic;
		tx 		: out std_logic;
		rx 		: in  std_logic;
		tx_flag 	: in  std_logic;
		rx_flag 	: out std_logic;
		data_tx 	: in  unsigned(7 downto 0);
		data_rx	: out unsigned(7 downto 0)
	);
end component my_UART;

begin

-- Unit under test
uut : my_UART port map(
	clk 		=> ADC_CLK_10,
	clk_div  => clk_div,
	rst_l    => RST_L,
	tx 		=> tx,
	rx			=> rx,
	tx_flag	=> tx_flag,
	rx_flag	=> rx_flag,
	data_tx	=> data_tx,
	data_rx	=> data_rx
);

-- Process for the clock
clk_process : process begin
	ADC_CLK_10 <= '0';
	wait for clk_period / 2;
	ADC_CLK_10 <= '1';
	wait for clk_period / 2;
end process;

-- Main process
test_process : process begin
	-- Setup
	rst_l <= '1';
	tx_flag <= '0';
	
	-- Send
	data_tx <= x"AB";
	wait for delay;
	tx_flag <= '1';
	wait for clk_period;
	tx_flag <= '0';
	
	-- Receive
	
	
	-- Wait
	wait;	
end process;

end architecture behavioral;