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
		ir				: out std_logic_vector(31 downto 0);							-- Instruction Register
		pc_addr		: out std_logic_vector(9  downto 0) := (others => '0')	-- Address of the output PC, but didn't want to call it pc
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
	
	signal pc_in	: std_logic_vector(9 downto 0):= B"0000000000";
	signal pc_out 	: std_logic_vector(9 downto 0):= B"0000000000";
begin
	-- Instance of our instruction memory
	im : InstructionMemory port map (
		address => pc_out,
		clock => clk,
		q => ir
	);
	
	-- Some assignments
	pc_in <= std_logic_vector(unsigned(pc_out) + 1);
	
	-- Main process
	process(clk, rst_l) begin
		if rising_edge(clk) then
			-- PC logic
			if rst_l = '0' then
				pc_out <= B"0000000000";
			elsif br_taken = '1' then
				pc_out <= br_addr;
			else
				pc_out <= pc_in;
			end if;
			pc_addr <= pc_out;
		end if;
	end process;
end architecture behavioral;