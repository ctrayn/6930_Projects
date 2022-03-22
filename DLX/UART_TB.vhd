library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity UART_TB is
end entity UART_TB;

architecture behavioral of UART_TB is

signal clk	 			: std_logic;
signal rst_l			: std_logic;
signal RX, TX			: std_logic;
signal wr_req			: std_logic;

signal d_tx				: std_logic_vector(35 downto 0);
signal empty, full	: std_logic;
			
constant clk_period	: time := 100 ns;
constant baud_delay	: time := 52 uS;
constant delay			: time := 127 ns;
constant DATACHAR		: std_logic_vector(35 downto 0) := X"000000048";
constant DATAINT		: std_logic_vector(35 downto 0) := X"1F5353535";
constant DATAUINT		: std_logic_vector(35 downto 0) := X"235353535";

component UART is
	port(		--INPUT
		clk			: in std_logic;
		rst_l			: in std_logic;
		RX 			: in std_logic;			--Connected to pin 40 on J1 (white wire)
		wr_req		: in std_logic;
		d_tx			: in std_logic_vector(35 downto 0); 		-- The data should only be 32 bits; [33:32] : 00 is char, 01 is signed 10 is unsigned; [35:34] are unused but I couldn't only make the FIFO 36 bits
		
		--OUTPUT
		TX 			: out std_logic; 			--Connected to pin 39 on J1 (green wire)
		UART_empty	: out std_logic;
		UART_full	: out std_logic
	);
end component UART;

begin

	-- Unit under test
	dut : UART 
	port map(
		clk 			=> clk,
		rst_l 		=> rst_l,
		TX 			=> TX,
		RX				=> RX,
		wr_req 		=> wr_req,
		d_tx 			=> d_tx,
		UART_empty 	=> empty,
		UART_full 	=> full
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
		d_tx <= DATACHAR;
		rst_l <= '1';
		
		wr_req <= '0';
		wait for clk_period * 2;
		wr_req <= '1';
		wait for clk_period;
		
		d_tx <= DATAINT;
		wr_req <= '0';
		wait for clk_period * 2;
		wr_req <= '1';
		wait for clk_period;
		wr_req <= '0';
		
		d_tx <= DATAUINT;
		wait for clk_period * 2;
		wr_req <= '1';
		wait for clk_period;
		wr_req <= '0';
				
		wait;	
	end process;

end architecture behavioral;