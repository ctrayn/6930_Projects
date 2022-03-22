library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity UART is
	port
	(
		--INPUT
		clk			: in std_logic;
		rst_l			: in std_logic;
		RX 			: in std_logic;			--Connected to pin 40 on J1 (white wire)
		wr_req		: in std_logic;
		d_tx			: in std_logic_vector(35 downto 0); 		-- The data should only be 32 bits; [33:32] : 00 is char, 01 is signed 10 is unsigned; [35:34] are unused but I couldn't only make the FIFO 36 bits
		
		--OUTPUT
		TX 			: out std_logic; 			--Connected to pin 39 on J1 (green wire)
		UART_empty	: out std_logic;
		UART_full	: out std_logic
	);										--Ground is pin 30 on J1 (black wire); Leave power disconnected (red wire)
end entity UART;

architecture behavioral of UART is

	type STATE_TYPE is (WAITING, READING, CHAR, SINT, UINT, WRITING, DIVIDE);
	signal state, div_state : STATE_TYPE := WAITING;
	
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
	
	type stack_type is array (0 to 127) of std_logic_vector(7 downto 0);
--	type stack_type is array (natural range <>) of std_logic_vector;
	signal stack	: stack_type; --(31 downto 0) := (others => (others => '0'));
	signal stk_ptr	: natural := 0;	--points to next open space
	
	constant clk_div : unsigned(15 downto 0) := x"0208"; -- This is based on our clk being 10Mhz 10M/19200
	
	constant char_t : std_logic_vector(1 downto 0) := B"00";
	constant int_t  : std_logic_vector(1 downto 0) := B"01";
	constant uint_t : std_logic_vector(1 downto 0) := B"10";
	constant MINUS	 : std_logic_vector(7 downto 0) := X"2D";
	constant TEN	 : std_logic_vector(4 downto 0) := B"01010";
	constant ASCII  : unsigned(7 downto 0) := X"30";
	
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
	
begin
	rst_h <= not rst_l;
	TX_flag <= not in_empty;
	d_tx_type <= d_tx_in(33 downto 32);
	UART_empty <= d_tx_empty;
		
	fifo_uart: UART_FIFO
		port map
		(
			aclr 	=> rst_h,
			clock => clk,
			data	=> d_tx,
			rdreq => rdreq,
			wrreq => wr_req,
			empty => d_tx_empty,
			full	=> UART_full,
			q		=>	d_tx_in
		);
	
	fifo_tx: TX_FIFO
		port map
		(
			aclr	=> rst_h,
			clock	=> clk,
			data	=> d_tx_out,
			rdreq => in_rd_req,
			wrreq	=> out_wr_req,
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
							numer 		<= (others => '0');
							d_tx_temp	<= (others => '0');
						else
							state 		<= DIVIDE;
							div_state	<= UINT;
							numer 		<= d_tx_temp;
							d_tx_temp	<= quotient;
						end if;
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
							stack(stk_ptr) <= std_logic_vector(unsigned(remainder) + unsigned(ASCII));
						end if;
						numer <= numer;
						rdreq <= '0';
						stk_ptr <= stk_ptr;
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
			end if;
		end if;
	end process;
	
end architecture behavioral;
