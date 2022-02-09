---------------------------------------------------------
-- DLX Processor
--
-- Jonah Boe
-- Calvin Passmore
-- Utah State University
-- ECE 6930, Spring 2022
---------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity DLX is

end entity DLX;

architecture behavioral of DLX is
	component Decode is
		port (
			--INPUT 
			clk		: in std_logic;
			rst_l		: in std_logic;
			pc_in		: in std_logic_vector(9  downto 0);
			IR_in		: in std_logic_vector(31 downto 0);
			w_addr	: in std_logic_vector(4  downto 0);			--Write address
			w_data	: in std_logic_vector(31 downto 0);			--Write data
			--OUTPUT
			Imm		: out std_logic_vector(31 downto 0);		-- Immediate value
			pc_out	: out std_logic_vector(9  downto 0);			--Program counter, delayed by 1 cycle
			IR_out	: out std_logic_vector(31 downto 0);		--The instruction, delayed by 1 cycle
			RS1		: out std_logic_vector(31 downto 0);		--The data from RS1
			RS2		: out std_logic_vector(31 downto 0)			--The data from RS2
		);
	end component;
begin

end architecture behavioral;