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
		inst_in	: in std_logic_vector(31 downto 0);
		--OUTPUT
		data_out	: out std_logic_vector(31 downto 0);
		inst_out : out std_logic_vector(31 downto 0)
	);
end entity Memory;

architecture behavioral of Memory is

	-- Components
	component DataMemory is
		port (
			address	: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
			clock		: IN STD_LOGIC  := '1';
			data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			wren		: IN STD_LOGIC;
			q			: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
		);
	end component;

	-- Signals
	signal wren 	: std_logic := '0';
	signal ALU_out : std_logic_vector(31 downto 0) := (others => '0');
	signal mem_out : std_logic_vector(31 downto 0) := (others => '0');
	signal inst_wb	: std_logic_vector(31 downto 0);
	signal data_wb	: std_logic_vector(31 downto 0);

begin

	-- Instance of our data memory
	dm : DataMemory port map (
		address => ALU_in(9 downto 0),
		clock => clk,
		data => RS2_in,
		wren => wren,
		q => mem_out
	);

	-- Async process. Write enable controol
	process(inst_in) begin
		if inst_in(31 downto 26) = OP_SW then
			wren <= '1';
		else
			wren <= '0';
		end if;
	end process;

	-- Sync process
	process(clk) begin
		if rising_edge(clk) then
				ALU_out <= ALU_in;
				inst_wb <= inst_in;
		end if;
	end process;

	-- Async process. Writeback data select
	process(inst_in) begin
		if inst_wb(31 downto 26) = OP_LW then
			data_wb <= mem_out;
		else
			data_wb <= ALU_out;
		end if;
	end process;

	-- Signals
	process(inst_wb, data_wb) begin
		inst_out <= inst_wb;
		data_out <= data_wb;
	end process;

end architecture behavioral;
