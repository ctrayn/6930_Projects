library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity UART_TB is
end entity UART_TB;

architecture behavioral of UART_TB is

signal clk	 			: std_logic;
signal rst_l			: std_logic;
signal RX, TX			: std_logic;
--signal wr_req			: std_logic;

signal d_tx				: std_logic_vector(35 downto 0);
signal empty, full	: std_logic;
			
constant clk_period	: time := 100 ns;
constant baud_delay	: time := 52 uS;
constant delay			: time := 127 ns;
constant DATACHAR		: std_logic_vector(35 downto 0) := X"000000048";
constant DATAINT		: std_logic_vector(35 downto 0) := X"1F5353535";
constant DATAUINT		: std_logic_vector(35 downto 0) := X"235353535";

component DLX is
	port(
		-- INPUT
		ADC_CLK_10 			: in 	std_logic;
		RST_L					: in  std_logic;
--		KEY 					: in std_logic_vector(1 downto 0);
		RX						: in  std_logic;
		-- OUTPUT
		TX						: out std_logic
	);
end component DLX;

begin

	-- Unit under test
	dut : DLX port map (
		-- INPUT
		ADC_CLK_10 	=> clk,
		RST_L			=> rst_l,
		RX				=> RX,
		-- OUTPUT
		TX				=> TX
		
	);

	-- Process for the clock
	clk_process : process begin
		clk <= '0';
		wait for clk_period / 2;
		clk <= '1';
		wait for clk_period / 2;
	end process;
	
	-- Main process
	test_process : process begin
		rst_l <= '1';
		
		--Start bits
		RX <= '1';
		wait for baud_delay;
		RX <= '0';
		wait for baud_delay;
		
		--0011_1001
		RX <= '1';
		wait for baud_delay;
		RX <= '0';
		wait for baud_delay;
		RX <= '0';
		wait for baud_delay;
		RX <= '1';
		wait for baud_delay;
		RX <= '1';
		wait for baud_delay;
		RX <= '1';
		wait for baud_delay;
		RX <= '0';
		wait for baud_delay;
		RX <= '0';
		wait for baud_delay;
		--Stop bits
		RX <= '1';
		wait for baud_delay;
		wait for baud_delay;
		wait for baud_delay;
		--Start bits
		RX <= '0';
		wait for baud_delay;
		--0000_1101
		RX <= '1';
		wait for baud_delay;
		RX <= '0';
		wait for baud_delay;
		RX <= '1';
		wait for baud_delay;
		RX <= '1';
		wait for baud_delay;
		RX <= '0';
		wait for baud_delay;
		RX <= '0';
		wait for baud_delay;
		RX <= '0';
		wait for baud_delay;
		RX <= '0';
		wait for baud_delay;
				
		wait;	
	end process;

end architecture behavioral;