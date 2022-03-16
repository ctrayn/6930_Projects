---------------------------------------------------------
-- DLX Processor
--
-- Jonah Boe
-- Calvin Passmore
-- Utah State University
-- ECE 6930, Spring 2022
---------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity Fetch is
	port (
		--INPUT
		clk 			: in std_logic;
		rst_l			: in std_logic;
		br_taken 	: in std_logic;
		br_addr		: in std_logic_vector(9 downto 0);
		stall			: in std_logic;
		--OUTPUT
		inst_out		: out std_logic_vector(31 downto 0);							-- Instruction Register
		pc_out		: out std_logic_vector(9  downto 0) := (others => '0')	-- Address of the output PC, but didn't want to call it pc
	);
end entity Fetch;

architecture behavioral of Fetch is
	component InstructionMemory
		port(
			address	: in std_logic_vector(9 downto 0);
			clken		: in STD_LOGIC  := '1';
			clock		: in std_logic  := '1';
			q			: out std_logic_vector(31 downto 0)
		);
	end component;

	signal pc_out_loc : std_logic_vector(9 downto 0):= B"0000000000";
	signal not_stall : std_logic;

begin
	not_stall <= not stall;
	
	-- Instance of our instruction memory
	im : InstructionMemory port map (
		address => pc_out_loc,
		clken => not_stall,
		clock => clk,
		q => inst_out
	);

	-- Main process
	process(clk, rst_l) begin
		if rising_edge(clk) then
			-- PC logic
			if rst_l = '0' then
				pc_out_loc <= B"0000000000";
				
			elsif br_taken = '1' then
				pc_out_loc <= br_addr;
				
			elsif stall = '1' then
				pc_out_loc <= pc_out_loc;
				
			else
				pc_out_loc <= std_logic_vector(unsigned(pc_out_loc) + 1);
				
			end if;
			pc_out <= pc_out_loc;
		end if;
	end process;
end architecture behavioral;
