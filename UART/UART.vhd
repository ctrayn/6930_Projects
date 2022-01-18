library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity UART is
	port (
		--INPUT
		ADC_CLK_10 : in std_logic;
		KEY : in std_logic_vector(1 downto 0);
		
		--OUTPUT
		RX : in  std_logic;			--Connected to pin 40 on J1 (white wire)
		Tx : out std_logic 			--Connected to pin 39 on J1 (green wire)
	);										--Ground is pin 30 on J1 (black wire); Leave power disconnected (red wire)
end entity UART;

architecture behavioral of UART is

	type STATE_TYPE is (START, RxTx, DEB);
	signal state : STATE_TYPE := START;
	
	signal TX_flag, RX_flag : std_logic;
	signal data_tx, data_rx : unsigned(7 downto 0);
	signal pll_clk, pll_lock : std_logic;
	
	constant clk_div : unsigned(15 downto 0) := x"0208"; -- This is based on our clk being 10Mhz 10M/19200
	
	constant A_upper : unsigned(7 downto 0) := X"41";
	constant Z_upper : unsigned(7 downto 0) := X"5A";
	constant a_lower : unsigned(7 downto 0) := X"61";
	constant z_lower : unsigned(7 downto 0) := X"7A";
	constant twenty  : unsigned(7 downto 0) := X"14";
	
	component my_UART
		port
		(
			clk   	: in 	std_logic;
			clk_div 	: in  unsigned(15 downto 0);
			rst_l 	: in 	std_logic;
			TX 		: out std_logic;
			RX 		: in 	std_logic;
			TX_flag 	: in 	std_logic;
			RX_flag 	: out std_logic;
			data_tx 	: in  unsigned(7 downto 0);
			data_rx 	: out unsigned(7 downto 0)
		);
	end component;	
	
begin
		
	dut : my_UART
		port map
		(
			clk => ADC_CLK_10,
			clk_div => clk_div,
			rst_l => KEY(0),
			TX => TX,
			RX => RX,
			TX_flag => TX_flag,
			RX_flag => RX_flag,
			data_tx => data_tx,
			data_rx => data_rx
		);

	process (ADC_CLK_10, KEY(0), RX_flag) begin
		if (KEY(0) = '0') then
			state <= START;
			TX_flag <= '0';
			data_tx <= A_upper;
		else
			if rising_edge(ADC_CLK_10) then
				case state is
					when START =>
						if (RX_flag = '1') then
							state <= RxTx;
						else
							state <= START;
						end if;
						TX_flag <= '0';
						data_tx <= data_tx;
						
					when RxTx => 
						if ((data_rx >= A_upper) and (data_rx <= Z_upper)) then
							data_tx <= data_rx + twenty;
						elsif ((data_rx >= a_lower) and (data_rx <= z_lower)) then
							data_tx <= data_rx - twenty;
						else
							data_tx <= x"45";
						end if;
						state <= START;
						TX_flag <= '1';
						
					when DEB =>
						if (RX_flag = '0') then
							state <= START;
						else
							state <= DEB;
						end if;
						TX_flag <= '0';
						data_tx <= data_tx;						
					
					when others =>
						data_tx <= (others => '0');
						TX_flag <= '0';
						state <= START;
						
				end case;
			end if;
		end if;
	end process;
	
end architecture behavioral;
