library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity UART_TB is
end entity UART_TB;

architecture behavioral of UART_TB is

signal ADC_CLK_10	 	: std_logic;
signal KEY 				: std_logic_vector(1 downto 0) := "11";
signal RX 				: std_logic;		
signal TX 				: std_logic;
			
constant clk_period	: time := 100 ns;
constant baud_delay	: time := 52 uS;
constant delay			: time := 127 ns;

component UART is
	port(
		ADC_CLK_10 : in std_logic;
		KEY : in std_logic_vector(1 downto 0);
		RX : in  std_logic;
		Tx : out std_logic
	);
end component UART;

begin

-- Unit under test
uut : UART port map(
	ADC_CLK_10 	=> ADC_CLK_10,
	KEY   		=> KEY,
	TX 			=> TX,
	RX				=> RX
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
	RX <= '1';
	
	-- Send a character 0100 0001
	wait for baud_delay * 3;
	RX <= '0';
	wait for baud_delay;
	RX <= '1';
	wait for baud_delay;
	RX <= '0';
	wait for baud_delay * 5;
	RX <= '1';
	wait for baud_delay;
	RX <= '0';
	wait for baud_delay;
	RX <= '1';
	
	-- Wait
	wait;	
end process;

end architecture behavioral;