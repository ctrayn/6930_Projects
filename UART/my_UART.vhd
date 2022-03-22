library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity my_UART is
	port (
		clk   	: in  std_logic;
		clk_div  : in  unsigned(15 downto 0);
		rst_l 	: in  std_logic;
		
		tx 		: out std_logic := '1';
		rx 		: in  std_logic;
		
		rdreq		: out std_logic;
		tx_flag 	: in  std_logic;
		rx_flag 	: out std_logic := '0';
		data_tx 	: in  unsigned(7 downto 0);
		data_rx	: out unsigned(7 downto 0)
	);
end entity my_UART;

architecture behavioral of my_UART is
 
	type STATE_TYPE is (IDLE, START, DATA);
	
	signal state_rx 		: STATE_TYPE := IDLE;
	signal next_state_rx : STATE_TYPE := IDLE;
	signal sync_rx			: unsigned(15 downto 0) := x"0000";
	signal position_rx 	: unsigned(3 downto 0) := x"0";
	signal data_out 		: unsigned(7 downto 0) := (others => '0');
	
	signal state_tx 		: STATE_TYPE := IDLE;
	signal next_state_tx : STATE_TYPE := IDLE;
	signal sync_tx			: unsigned(15 downto 0) := x"0000";
	signal position_tx 	: unsigned(3 downto 0) := x"0";
	
	-- Signals for debugging
	signal sample_rx		: std_logic := '0';
	
begin
	-- Assignments
	data_rx <= data_out;
	
	
	-- RX
	-- Sync
	process (clk, rst_l) begin
		if rising_edge(clk) then
			if (rst_l = '0') then
				sync_rx <= x"0000";
				position_rx <= x"0";
				data_out <= x"00";
				rx_flag <= '0';
			elsif state_rx = IDLE and next_state_rx = START then
				sync_rx <= x"0000";
				position_rx <= x"0";
				data_out <= x"00";
			elsif state_rx = START and next_state_rx = START then
				sync_rx <= sync_rx + 1;
			elsif state_rx = START and next_state_rx = DATA then
				sync_rx <= x"0000";
			elsif state_rx = DATA and next_state_rx = DATA then
				-- Sync bits with the sender
				if sync_rx = clk_div then
					position_rx <= position_rx + 1;
					sync_rx <= x"0000";
				-- Sample once in the midle. Right shift on unsigned is logical. This is esentialy div by 2.
				elsif sync_rx = shift_right(clk_div, 1) then
					data_out(to_integer(position_rx)) <= rx;
					sync_rx <= sync_rx + 1;
					sample_rx <= '1';
				else
					sync_rx <= sync_rx + 1;
					sample_rx <= '0';
				end if;
			elsif state_rx = DATA and next_state_rx = IDLE then
				rx_flag <= '1';
			else
				rx_flag <= '0';
			end if;
			state_rx <= next_state_rx;
		end if;
	end process;
	
	-- Async
	process (rx, position_rx, rst_l, sync_rx, state_rx, clk_div) begin
		if rst_l = '0' then
			next_state_rx <= IDLE;
		elsif state_rx = IDLE and rx = '0' then
			next_state_rx <= START;
		elsif state_rx = START and sync_rx >= clk_div then
			next_state_rx <= DATA;
		elsif state_rx = DATa and position_rx >= x"8" then
			next_state_rx <= IDLE;
		else
			next_state_rx <= state_rx;
		end if;
	end process;

	
	-- TX
	-- Sync
	process (clk, rst_l) begin
		if rising_edge(clk) then
			if (rst_l = '0') then
				sync_tx <= X"0000";
				position_tx <= x"0";
				tx <= '1';
				rdreq <= '0';
			elsif state_tx = IDLE and next_state_tx = START then
				sync_tx <= x"0000";
				position_tx <= x"0";
				tx <= '0';
				rdreq <= '1';
			elsif state_tx = START and next_state_tx = START then
				sync_tx <= sync_tx + 1;
				rdreq <= '0';
			elsif state_tx = START and next_state_tx = DATA then
				sync_tx <= x"0000";
				rdreq <= '0';
			elsif state_tx = DATA and next_state_tx = DATA then
				-- Sync bits with the sender
				if sync_tx = clk_div then
					position_tx <= position_tx + 1;
					sync_tx <= x"0000";
				-- send the next bit
				else
					tx <= data_tx(to_integer(position_tx));
					sync_tx <= sync_tx + 1;
				end if;
				rdreq <= '0';
			elsif state_tx = DATA and next_state_tx = IDLE then
				tx <= '1';
				rdreq <= '0';
			end if;
			state_tx <= next_state_tx;
		end if;
	end process;
	
	-- Async
	process (tx_flag, position_tx, rst_l, sync_tx, state_tx, clk_div) begin
		if rst_l = '0' then
			next_state_tx <= IDLE;
		elsif state_tx = IDLE and tx_flag = '1' then
			next_state_tx <= START;
		elsif state_tx = START and sync_tx >= clk_div then
			next_state_tx <= DATA;
		elsif state_tx = DATA and position_tx >= x"8" then
			next_state_tx <= IDLE;
		else
			next_state_tx <= state_tx;
		end if;
	end process;

end architecture behavioral;