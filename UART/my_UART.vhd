library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity my_UART is
	port (
		clk   : in std_logic;			--Assuming this would be the Baud Rate
		rst_l : in std_logic;			--Direct from Key inputs
		
		TX : in  std_logic;
		RX : out std_logic;
		
		TX_flag : in  std_logic;
		RX_flag : out std_logic;
		data_tx : in  unsigned(7 downto 0);
		data_rx : out unsigned(7 downto 0)
	);
end entity my_UART;

architecture behavioral of my_UART is 

begin

end architecture behavioral;