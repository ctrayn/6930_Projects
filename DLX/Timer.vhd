library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.common.all;

entity Timer is
	Generic (
		DELAY : integer := 10_000;
	);
	port (
		--INPUT
		clk		: in std_logic;
		rst_l		: in std_logic;
		GO			: in std_logic;
		STOP		: in std_logic;
		Restart	: in std_logic;
		
		--OUTPUT
		HEX0 : out std_logic_vector(7 downto 0);
		HEX1 : out std_logic_vector(7 downto 0);
		HEX2 : out std_logic_vector(7 downto 0);
		HEX3 : out std_logic_vector(7 downto 0);
		HEX4 : out std_logic_vector(7 downto 0);
		HEX5 : out std_logic_vector(7 downto 0)
	);

end entity Timer;

architecture behavioral of Timer is
	--Without the dot
	type SegArray is array (0 to 9) of std_logic_vector(7 downto 0);
	constant numbers : SegArray := (X"C0", X"F9", X"A4", X"B0", X"99", X"92", X"82", X"F8", X"80", X"90");
	--With the dot
	type DSegArray is array (0 to 9) of std_logic_vector(7 downto 0);
	constant dnumbers : DSegArray := (X"40", X"79", X"24", X"30", X"19", X"12", X"02", X"78", X"00", X"10");
	
	signal min1, min2, sec1, sec2, mil1, mil2 : natural := 0;
	signal count : natural := 0;
	type STATE_TYPE is (IDLE, COUNTING, RESET);
	signal state : STATE_TYPE := IDLE;
	
begin

	HEX0 <=  numbers(mil1);
	HEX1 <=  numbers(mil2);
	HEX2 <= dnumbers(sec1);
	HEX3 <=  numbers(sec2);
	HEX4 <= dnumbers(min1);
	HEX5 <=  numbers(min2);
	
	process(clk, rst_l, Restart, Go, STOP) begin
		if (rst_l = '0') then
			mil1  <= 0;
			mil2  <= 0;
			sec1  <= 0;
			sec2  <= 0;
			min1  <= 0;
			min2  <= 0;
			count <= 0;
		else
		
			case state is
			
				when IDLE =>
					if (Restart = '1') then
						state <= RESET;
					elsif (Go = '1') then
						state <= COUNTING;
					else
						state <= IDLE;
					end if;
					mil1  <= mil1;
					mil2  <= mil2;
					sec1  <= sec1;
					sec2  <= sec2;
					min1  <= min1;
					min2  <= min2;
					count <= count;
					
				when COUNTING =>
					if (Restart = '1') then
						state <= RESET;
					elsif (STOP = '1') then
						state <= IDLE;
					else
						state <= COUNTING;
					end if;
					if (count > DELAY) then
						count <= 0;
						mil1 <= mil1 + 1;
						if (mil1 = 9) then
							mil1 <= 0;
							if (mil2 = 9) then
								mil2 <= 0;
								if (sec1 = 9) then
									sec1 <= 0;
									if (sec2 = 6) then
										sec2 <= 0;
										if (min1 = 9) then
											min1 <= 0;
											if (min2 = 6) then
												min2 <= 0;
											else
												min2 <= min2 + 1;
											end if;
										else
											min1 <= min1 + 1;
										end if;
									else
										sec2 <= sec2 + 1;
									end if;
								else
									sec1 <= sec1 + 1;
								end if;
							else
								mil2 <= mil2 + 1;
							end if;
						else
							mil1 <= mil1 + 1;
						end if;					
					end if;
				
				when RESET =>
					state <= IDLE;
					mil1  <= 0;
					mil2  <= 0;
					sec1  <= 0;
					sec2  <= 0;
					min1  <= 0;
					min2  <= 0;
					count <= 0;
					
				when others =>
					state <= IDLE;
					mil1  <= 0;
					mil2  <= 0;
					sec1  <= 0;
					sec2  <= 0;
					min1  <= 0;
					min2  <= 0;
					count <= 0;
					
			
			end case;
		end if;
	end process;

end architecture