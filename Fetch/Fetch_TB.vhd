library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity Fetch_TB is
end entity Fetch_TB;

architecture behavioral of Fetch_TB is
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
--		rst_l <= '1';						--Use this chunk of test to just let the clock run on the dut
--		br_taken <= '0';
--		br_addr <= X"00000000";
--		wait;
		rst_l <= '1';
		branch_taken <= '0';
		wait for CLK_PERIOD/2;
		branch_addr <= B"0000000000";
		
		wait for CLK_PERIOD * 5;
		
		branch_addr <= B"0000000111";			-- JAL 007: multiply
		branch_taken <= '1';
		wait for CLK_PERIOD;
		branch_taken <= '0';
		
		wait for CLK_PERIOD * 6;
		
		branch_addr <= B"0000010000";			-- JAL 010: add
		branch_taken <= '1';
		wait for CLK_PERIOD;			
		branch_taken <= '0';
		
		wait for CLK_PERIOD * 5;
		
		branch_addr <= B"0000001101";			-- JR 00D: R31
		branch_taken <= '1';
		wait for CLK_PERIOD;
		branch_taken <= '0';
		
		wait for CLK_PERIOD * 3;
		
		branch_addr <= B"0000001010";			-- JAL 00A: loop
		branch_taken <= '1';
		wait for CLK_PERIOD;			
		branch_taken <= '0';
		
		wait for CLK_PERIOD * 2;
		
		branch_addr <= B"0000010101";			-- BNEZ 015: break
		branch_taken <= '1';
		wait for CLK_PERIOD;
		branch_taken <= '0';
		
		wait for CLK_PERIOD;
		
		branch_addr <= B"0000000101";			-- JR 005: R30
		branch_taken <= '1';
		wait for CLK_PERIOD;
		branch_taken <= '0';
		
		wait for CLK_PERIOD;
		
		branch_addr <= B"0000000010";			-- J 002: main
		branch_taken <= '1';
		wait for CLK_PERIOD;
		branch_taken <= '0';
		
		wait for CLK_PERIOD * 2;
		
		branch_addr <= B"0000010110";			-- BNEZ 016: exit
		branch_taken <= '1';
		wait for CLK_PERIOD;
		branch_taken <= '0';
		
		wait for CLK_PERIOD * 2;
		
		branch_addr <= B"0000010111";			-- J 017: done
		branch_taken <= '1';
		
		wait;
	end process;

end architecture behavioral;