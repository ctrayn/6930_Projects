library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity TestBench is
end entity TestBench;

architecture behavioral of TestBench is
	component DLX
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
	end component;

	constant CLK_PERIOD  : time := 10 ns;
	constant WAIT_TIME   : integer := 10000;

	signal clk           : std_logic := '0';
	signal rst_l         : std_logic := '1';
	signal RX				: std_logic := '0';
	signal TX				: std_logic;
	signal SW				: std_logic_vector(9 downto 0) := (others => '0');
begin

   -- Our unit under test
	dut : DLX
		port map (
			ADC_CLK_10 => clk,
			RST_L => rst_l,
			RX => RX,
			TX => TX,
			SW => SW
		);

   -- Clock process
	clk_process : process begin
		clk <= '0';
		wait for CLK_PERIOD/2;
		clk <= '1';
		wait for CLK_PERIOD/2;
	end process;

   -- Test process
	stm_process: process begin
		rst_l <= '1';
		wait;
	end process;

end architecture behavioral;
