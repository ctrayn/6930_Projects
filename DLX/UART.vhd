library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.common.all;

entity UART is
	port
	(
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
	);										--Ground is pin 30 on J1 (black wire); Leave power disconnected (red wire)
end entity UART;

architecture behavioral of UART is

	type STATE_TYPE is (WAITING, READING, CHAR, SINT, UINT, WRITING, DIVIDE);
	signal state, div_state : STATE_TYPE := WAITING;
	type RX_STATE_TYPE is (WAITING, READING, STORE, WRITING);
	signal rx_state : RX_STATE_TYPE := WAITING;
	
	signal TX_flag, RX_flag 	: std_logic;
	signal data_tx				 	: std_logic_Vector(7 downto 0);
	signal data_rx					: unsigned(7 downto 0);
	signal pll_clk, pll_lock 	: std_logic;
	signal rst_h 					: std_logic;
	signal rdreq 					: std_logic;
	signal d_tx_in					: std_logic_vector(35 downto 0);
	signal d_tx_type				: std_logic_vector(1 downto 0);
	signal d_tx_out, d_tx_8b	: std_logic_vector(7 downto 0);
	signal d_tx_empty				: std_logic;
	signal in_rd_req,out_wr_req: std_logic;
	signal in_empty				: std_logic;
	signal numer, quotient		: std_logic_vector(31 downto 0);
	signal remainder, u_remain	: std_logic_vector(4 downto 0);
	signal d_tx_temp				: std_logic_vector(31 downto 0);
	signal u_numer, u_quotient	: std_logic_vector(31 downto 0);
	signal resend_data			: std_logic_vector(7 downto 0);
	signal resend_flag			: std_logic;
	signal number					: std_logic_vector(31 downto 0) := (others => '0');
	signal negative				: std_logic;
	signal d_tx_write				: std_logic_vector(7 downto 0) := (others => '0');
	signal d_tx_wr_flag			: std_logic := '0';
	signal true						: std_logic;
	
	type stack_type is array (0 to 127) of std_logic_vector(7 downto 0);
--	type stack_type is array (natural range <>) of std_logic_vector;
	signal stack	: stack_type; --(31 downto 0) := (others => (others => '0'));
	signal stk_ptr	: natural := 0;	--points to next open space
	
	constant clk_div : unsigned(15 downto 0) := x"0208"; -- This is based on our clk being 10Mhz 10M/19200
	constant ASCII_ZERO	: unsigned(7 downto 0) 	:= X"30";
	constant ASCII_NINE	: unsigned(7 downto 0) 	:= X"39";
	constant ASCII_NEG	: unsigned(7 downto 0) 	:= X"2E";
	constant ASCII_CR		: unsigned(7 downto 0)	:= X"0D";
	
	component my_UART
		port
		(
			clk   	: in 	std_logic;
			clk_div 	: in  unsigned(15 downto 0);
			rst_l 	: in 	std_logic;
			TX 		: out std_logic;
			RX 		: in 	std_logic;
			rdreq		: out std_logic;
			TX_flag 	: in 	std_logic;
			RX_flag 	: out std_logic;
			data_tx 	: in  unsigned(7 downto 0);
			data_rx 	: out unsigned(7 downto 0)
		);
	end component;	
	
	component UART_FIFO
		port
		(
			aclr		: in  STD_LOGIC ;
			clock		: in  STD_LOGIC ;
			data		: in  STD_LOGIC_VECTOR (35 DOWNTO 0);
			rdreq		: in  STD_LOGIC ;
			wrreq		: in  STD_LOGIC ;
			empty		: out STD_LOGIC ;
			full		: out STD_LOGIC ;
			q			: out STD_LOGIC_VECTOR (35 DOWNTO 0)
		);
	end component;
	
	component TX_FIFO IS
	port
		(
			aclr		: IN STD_LOGIC ;
			clock		: IN STD_LOGIC ;
			data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			rdreq		: IN STD_LOGIC ;
			wrreq		: IN STD_LOGIC ;
			empty		: OUT STD_LOGIC ;
			q			: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
		);
	end component;
	
	component U_DIV is
	port
		(
			denom		: IN  STD_LOGIC_VECTOR (4  DOWNTO 0);
			numer		: IN  STD_LOGIC_VECTOR (31 DOWNTO 0);
			quotient	: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
			remain	: OUT STD_LOGIC_VECTOR (4  DOWNTO 0)
		);
	end component;
	
	component UnsignedDiv is
	port
		(
			denom		: IN  STD_LOGIC_VECTOR (4  DOWNTO 0);
			numer		: IN  STD_LOGIC_VECTOR (31 DOWNTO 0);
			quotient	: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
			remain	: OUT STD_LOGIC_VECTOR (4  DOWNTO 0)
		);
	end component;
	
	signal mult_result 	: std_logic_vector(35 downto 0); 
	signal mult_data 		: std_logic_vector(31 downto 0);
	component MULT IS
	PORT
	(
		dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		result	: OUT STD_LOGIC_VECTOR (35 DOWNTO 0)
	);
	end component;
	
	signal d_rx_out 	: std_logic_vector(31 downto 0) := (others => '0');
	signal d_rx_wr		: std_logic := '0';
	component RX_FIFO IS
	PORT
	(
		aclr		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		rdreq		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		empty		: OUT STD_LOGIC ;
		q			: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
	end component;
	
begin
	rst_h <= not rst_l;
	TX_flag <= not in_empty;
	d_tx_type <= d_tx_in(33 downto 32);
	TX_empty <= d_tx_empty;
	d_tx_write <= d_tx_out or resend_data;
	d_tx_wr_flag <= resend_flag or out_wr_req;
		
	fifo_uart: UART_FIFO
		port map
		(
			aclr 	=> rst_h,
			clock => clk,
			data	=> d_tx,
			rdreq => rdreq,
			wrreq => wr_req,
			empty => d_tx_empty,
			full	=> TX_full,
			q		=>	d_tx_in
		);
	
	fifo_tx: TX_FIFO
		port map
		(
			aclr	=> rst_h,
			clock	=> clk,
			data	=> d_tx_write,
			rdreq => in_rd_req,
			wrreq	=> d_tx_wr_flag,
			empty	=> in_empty,
			q		=> d_tx_8b
		);
		
	dut : my_UART
		port map
		(
			clk => clk,
			clk_div => clk_div,
			rst_l => rst_l,
			TX => TX,
			RX => RX,
			rdreq	=> in_rd_req,
			TX_flag => TX_flag,
			RX_flag => RX_flag,
			data_tx => unsigned(d_tx_8b),
			data_rx => data_rx
		);
		
	div : U_DIV
		port map
		(
			denom		=> TEN,
			numer		=> numer,
			quotient	=> quotient,
			remain	=> remainder
		);

	udiv : UnsignedDIV
		port map
		(
			denom		=> TEN,
			numer		=> u_numer,
			quotient	=> u_quotient,
			remain	=> u_remain
		);
		
	umult: MULT
		port map
		(
			dataa		=> mult_data,
			result	=> mult_result
		);
		
	fifo_rx : RX_FIFO
		port map
		(
			aclr		=> rst_h,
			clock		=> clk,
			data		=> d_rx_out,
			rdreq		=> rd_req,
			wrreq		=> d_rx_wr,
			empty		=> RX_empty,
			q			=> d_rx
		);
		
	--RX
	--Process to take RX data and accumulate it until an <enter> is pressed by the user
	process(clk, rst_l, RX_FLAG) begin
		if rst_l = '0' then
			resend_data <= (others => '0');
			resend_flag <= '0';
			rx_state <= WAITING;
			number <= (others => '0');
			mult_data <= (others => '0');
			negative <= '0';
			d_rx_wr <= '0';
			d_rx_out <= (others => '0');
		else
			if rising_edge(clk) then
			
				case rx_state is
					when WAITING =>
						if RX_FLAG = '1' then
							rx_state <= READING;
						else
							rx_state <= WAITING;
						end if;
						resend_data <= (others => '0');
						resend_flag <= '0';
						number <= number;
						negative <= negative;
						d_rx_wr <= '0';
						d_rx_out <= (others => '0');
					
					when READING =>
						if data_rx >= ASCII_ZERO and data_rx <= ASCII_NINE then
							true <= '0';
							mult_data <= number;
							rx_state <= STORE;
							negative <= negative;
						elsif data_rx = ASCII_NEG then
							true <= '0';
							mult_data <= (others => '0');
							rx_state <= WAITING;
							negative <= '1';
						elsif data_rx = ASCII_CR then
							true <= '1';
							rx_state <= WRITING;
							negative <= negative;
							mult_data <= (others => '0');
						else
							true <= '0';
							mult_data <= (others => '0');
							rx_state <= WAITING;
							negative <= negative;
						end if;
						resend_data <= std_logic_vector(data_rx);
						resend_flag <= '1';
						number <= number;
						d_rx_wr <= '0';
						d_rx_out <= (others => '0');
						
					when STORE =>
						number <= std_logic_vector(unsigned(mult_result(31 downto 0)) + unsigned(data_rx) - ASCII_ZERO);	--convert to hex and store
						rx_state <= WAITING;
						negative <= negative;
						mult_data <= (others => '0');
						resend_data <= (others => '0');
						resend_flag <= '0';
						d_rx_wr <= '0';
						d_rx_out <= (others => '0');
						
					when WRITING =>
						if negative = '1' then
							d_rx_out <= std_logic_vector(unsigned(not number) + 1);
						else
							d_rx_out <= number;
						end if;
						d_rx_wr <= '1';
						rx_state <= WAITING;
						number <= (others => '0');
						negative <= '0';
						mult_data <= (others => '0');
						resend_data <= (others => '0');
						resend_flag <= '0';
						
				
					when others =>
					resend_data <= (others => '0');
					resend_flag <= '0';
					rx_state <= WAITING;
					number <= (others => '0');
					mult_data <= (others => '0');
					negative <= '0';
					d_rx_wr <= '0';
					d_rx_out <= (others => '0');
				
				end case;	
			end if;
		end if;
	end process;
		
	
	--TX
	-- Process to take the data from the 32 bit register into the 8 bit register based on type
	process (clk, d_tx_empty, rst_l) begin
		if (rst_l = '0') then
			d_tx_out 	<= (others => '0');
			stk_ptr  	<= 0;
			out_wr_req  <= '0';
			state 		<= WAITING;
			stack			<= (others => (others => '0'));
			numer 		<= (others => '0');
			div_state 	<= WAITING;
		else
			if rising_edge(clk) then
				case state is
				
					when WAITING =>
						if d_tx_empty = '0' then
							state <= READING;
							rdreq <= '1';
						else
							state <= WAITING;
							rdreq <= '0';
						end if;
						stk_ptr  <= stk_ptr;
						out_wr_req   <= '0';
						d_tx_out <= (others => '0');
						stack		<= stack;
						numer 	<= (others => '0');
						div_state <= WAITING;
						d_tx_temp <= (others => '0');
						
					when READING =>
						if rdreq = '0' then
							if d_tx_type = char_t then
								state <= CHAR;
							elsif d_tx_type = int_t then
								state <= SINT;							
							elsif d_tx_type = uint_t then
								state <= UINT;
							else
								state <= WAITING;
							end if;
						else
							state <= READING;
						end if;
						d_tx_temp <= d_tx_in(31 downto 0);
						rdreq 	<= '0';
						numer 	<= (others => '0');
						div_state <= WAITING;
						stk_ptr  <= stk_ptr;
						out_wr_req   <= '0';
						d_tx_out <= (others => '0');
						
						
					when CHAR =>
						stack(stk_ptr) <= d_tx_in(7 downto 0);
						stk_ptr <= stk_ptr + 1;
						out_wr_req   <= '0';
						d_tx_temp <= d_tx_temp;
						d_tx_out <= d_tx_out;
						state <= WRITING;
						rdreq 	<= '0';
						div_state <= WAITING;
						
					when SINT =>
						if signed(d_tx_temp) = 0 then
							state <= WRITING;
							numer <= (others => '0');
							d_tx_temp 	<= d_tx_temp;
							
							if signed(d_tx_in) < 0 then
								stack(stk_ptr) <= MINUS;
								stk_ptr <= stk_ptr + 1;
							else
								stack <= stack;
								stk_ptr <= stk_ptr;
							end if;
							
						elsif signed(d_tx_temp) = -1 or signed(d_tx_temp) = 1 then
							numer <= (others => '0');
							state <= WRITING;
							stack(stk_ptr) <= std_logic_vector(unsigned(d_tx_temp(7 downto 0)) + unsigned(ASCII));
							d_tx_temp 	<= d_tx_temp;
						else
							div_state 	<= SINT;
							state 		<= DIVIDE;
							d_tx_temp 	<= quotient;
							stk_ptr 		<= stk_ptr + 1;
							numer 		<= d_tx_temp;
						end if;
						numer 		<= d_tx_temp;
						out_wr_req	<= '0';
						d_tx_out 	<= d_tx_out;
						rdreq 		<= '0';
					
					when UINT =>
						if signed(d_tx_temp) = 0 then
							state 		<= WRITING;
							div_state	<= WAITING;
							numer 		<= (others => '0');
						else
							state 		<= DIVIDE;
							div_state	<= UINT;
							u_numer 		<= d_tx_temp;
						end if;
						d_tx_temp	<= d_tx_temp;
						d_tx_out 	<= d_tx_out;
						out_wr_req 	<= '0';
						rdreq 		<= '0';
						stack 		<= stack;
						stk_ptr		<= stk_ptr;
							
					when WRITING =>
						if stk_ptr = 0 then
							state 		<= WAITING;
							stk_ptr 		<= 0;
							out_wr_req	<= '0';
							d_tx_out 	<= d_tx_out;
						else
							state 		<= WRITING;
							stk_ptr 		<= stk_ptr - 1;
							d_tx_out 	<= stack(stk_ptr - 1);
							out_wr_req 	<= '1';
						end if;
						rdreq 	<= '0';
						numer <= (others => '0');
						
					when DIVIDE =>
						state <= div_state;
						if div_state = SINT then
							d_tx_temp <= quotient;
							stack(stk_ptr) <= std_logic_vector(unsigned(remainder) + unsigned(ASCII));
						else
							d_tx_temp <= u_quotient;
							stack(stk_ptr) <= std_logic_vector(unsigned(u_remain) + unsigned(ASCII));
						end if;
						numer <= numer;
						rdreq <= '0';
						stk_ptr <= stk_ptr + 1;
						out_wr_req <= '0';
					
					when others =>
						stk_ptr  	<= 0;
						out_wr_req	<= '0';
						d_tx_out 	<= (others => '0');
						state 		<= WAITING;
						stack			<= (others => (others => '0'));
						rdreq 		<= '0';
						numer 		<= (others => '0');
						u_numer 		<= (others => '0');
						div_state	<= WAITING;
				
				end case;
			end if; 	-- rising_edge(clk)
		end if;		--rst_l
	end process;
	
end architecture behavioral;
