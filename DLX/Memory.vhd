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
use work.common.all;

entity Memory is
	port (
		--INPUT
		clk 		: in std_logic;
		rst_l 	: in std_logic;
		ALU_in 	: in std_logic_vector(31 downto 0);
		RS2_in	: in std_logic_vector(31 downto 0);
		Inst_in	: in std_logic_vector(31 downto 0);
		--OUTPUT
		Data_out	: out std_logic_vector(31 downto 0);
		Inst_out : out std_logic_vector(31 downto 0);
		ALU_out 	: out std_logic_vector(31 downto 0);
	);
end entity Memory;

architecture behavioral of Memory is

	component DataMemory is
		port (
			address	: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
			clock		: IN STD_LOGIC  := '1';
			data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			wren		: IN STD_LOGIC ;
			q			: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
		);
	end component;

begin

end architecture behavioral;