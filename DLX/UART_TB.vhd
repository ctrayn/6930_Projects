library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity UART_TB is
end entity UART_TB;

architecture behavioral of UART_TB is

signal clk	 			: std_logic;
signal rst_l			: std_logic;
signal RX, TX			: std_logic;

signal HEX0 			: std_logic_vector(7 downto 0);
signal HEX1 			: std_logic_vector(7 downto 0);
signal HEX2 			: std_logic_vector(7 downto 0);
signal HEX3 			: std_logic_vector(7 downto 0);
signal HEX4 			: std_logic_vector(7 downto 0);
signal HEX5 			: std_logic_vector(7 downto 0);
signal LEDR				: std_logic_vector(9 downto 0);
signal SW				: std_logic_vector(9 downto 0) := B"0000000000";

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
	);
end component DLX;

begin

	-- Unit under test
	dut : DLX port map (
		-- INPUT
		ADC_CLK_10 	=> clk,
		RST_L			=> rst_l,
		RX				=> RX,
		SW => SW,
		-- OUTPUT
		HEX0 => HEX0,
		HEX1 => HEX1,
		HEX2 => HEX2,
		HEX3 => HEX3,
		HEX4 => HEX4,
		HEX5 => HEX5,
		LEDR => LEDR,
		TX	=> TX
		
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