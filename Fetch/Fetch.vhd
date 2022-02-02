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
		--OUTPUT
		ir				: out std_logic_vector(31 downto 0);		-- Instruction Register
		pc_addr		: out std_logic_vector(9  downto 0)			-- Address of the output PC, but didn't want to call it pc
	);
end entity Fetch;

architecture behavioral of Fetch is
	component InstructionMemory 
		port(
			address	: in std_logic_vector(9 downto 0);
			clock		: in std_logic  := '1';
			q			: out std_logic_vector(31 downto 0)
		);
	end component;
	
	signal pc : unsigned(9 downto 0):= x"0000";
begin
	-- Instance of our instruction memory
	im : InstructionMemory port map (
		address => pc,
		clock => clk,
		q => ir
	);
	
	-- Assignment 
	pc_addr <= pc
	
	-- Main process
	process(clk) begin
		if rising_edge(clk) then
			-- PC logic
			if br_taken = '1' then
				pc <= br_addr;
			else
				pc <= pc + 1;
		end if;
	end process
end architecture behavioral;