library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity Fetch_TB_example2 is
end entity Fetch_TB_example2;

architecture behavioral of Fetch_TB_example2 is
	component Fetch
		port(
			--INPUT
			clk 			: in std_logic;
			rst_l			: in std_logic;
			br_taken 	: in std_logic;
			br_addr		: in std_logic_vector(9 downto 0);
			--OUTPUT
			IR				: out std_logic_vector(31 downto 0);		--Instruction Register
			pc_addr		: out std_logic_vector(9  downto 0)			--Address of the output PC, but didn't want to call it pc
		);
	end component;
	
	constant CLK_PERIOD : time := 10 ns;
	constant WAIT_TIME : integer := 10000;
	
	signal clk 				: std_logic := '0';
	signal rst_l 			: std_logic := '1';
	signal branch_taken 	: std_logic := '0';
	signal branch_addr  	: std_logic_vector(9 downto 0) := (others => '0');
	signal IR 				: std_logic_vector(31 downto 0);
	signal pc_addr 		: std_logic_vector(9 downto 0);
	
begin

	dut : Fetch
		port map (
			clk => clk,
			rst_l => rst_l,
			br_taken => branch_taken,
			br_addr => branch_addr,
			IR => IR,
			pc_addr => pc_addr
		);
		
	clk_process : process begin
		clk <= '0';
		wait for CLK_PERIOD/2;
		clk <= '1';
		wait for CLK_PERIOD/2;
	end process;
	
	stm_process: process begin
		rst_l <= '1';
		branch_taken <= '0';
		wait for CLK_PERIOD * 5;
		branch_addr <= B"0000000111";			--JAL 007
		branch_taken <= '1';
		wait for CLK_PERIOD;
		branch_taken <= '0';
		
		wait for CLK_PERIOD * 10;
		branch_addr <= B"0000010001";			-- J 009
		branch_taken <= '1';
		wait for CLK_PERIOD;
		branch_taken <= '0';
		
		wait for CLK_PERIOD * 4;
		branch_addr <= B"0000001111";			-- BEQZ 00F
		branch_taken <= '1';
		wait for CLK_PERIOD;
		branch_taken <= '0';
		
		wait for CLK_PERIOD * 2;
		branch_addr <= B"0000010001";			-- J 09
		branch_taken <= '1';
		wait for CLK_PERIOD;
		branch_taken <= '0';
		
		wait for CLK_PERIOD * 4;
		branch_addr <= B"0000001111"; 		-- BEQZ 00F
		branch_taken <= '1';
		wait for CLK_PERIOD;
		branch_taken <= '0';
		
		wait for CLK_PERIOD * 3;
		branch_addr <= B"0000010001";			-- J 009
		branch_taken <= '1';
		wait for CLK_PERIOD;
		branch_taken <= '0';
		
		wait for CLK_PERIOD * 8;
		branch_addr <= B"0000010001";			-- J 009
		branch_taken <= '1';
		wait for CLK_PERIOD;
		branch_taken <= '0';
		
		wait for CLK_PERIOD * 4;
		branch_addr <= B"0000001111";			-- BEQZ 00F
		branch_taken <= '1';
		wait for CLK_PERIOD;
		branch_taken <= '0';
		
		wait for CLK_PERIOD * 2;
		branch_addr <= B"0000010001";			-- J 009
		branch_taken <= '1';
		wait for CLK_PERIOD;
		branch_taken <= '0';
		
		wait for CLK_PERIOD * 8;
		
		while 1 loop								--gets stuck in a loop
			branch_addr <= B"0000010001";		-- J 009
			branch_taken <= '1';
			wait for CLK_PERIOD;
			branch_taken <= '0';
			wait for CLK_PERIOD * 8;
		end loop;
		wait;
	end process;

end architecture behavioral;