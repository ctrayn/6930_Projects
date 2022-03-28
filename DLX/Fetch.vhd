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
use work.common.all;

entity Fetch is
	port (
		--INPUT
		clk 			: in std_logic;
		rst_l			: in std_logic;
		br_taken 	: in std_logic;
		br_addr		: in std_logic_vector(9 downto 0);
		--OUTPUT
		inst_out		: out std_logic_vector(31 downto 0);								-- Instruction Register
		pc_out		: out std_logic_vector(9  downto 0) := (others => '0')	-- Address of the output PC, but didn't want to call it pc
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

	signal pc 				: std_logic_vector(9 downto 0):= B"0000000000";
	signal inst_mem		: std_logic_vector(31 downto 0);
	signal was_branch1	: std_logic := '0';
	signal was_branch2	: std_logic := '0';

	-- For creating a bubble
	signal this_opcode	: std_logic_vector(5 downto 0) := (others => '0');
	signal this_Rs1		: std_logic_vector(4 downto 0) := (others => '0');
	signal this_Rs2		: std_logic_vector(4 downto 0) := (others => '0');
	signal inst_last		: std_logic_vector(31 downto 0) := (others => '0');
	signal last_opcode	: std_logic_vector(5 downto 0) := (others => '0');
	signal last_rd 		: std_logic_vector(4 downto 0) := (others => '0');
	signal stall			: std_logic	:= '0';
	signal mem_clk			: std_logic := '0';
	signal mem_pc			: std_logic_vector(9 downto 0):= B"0000000000";

begin
	
	-- Instance of our instruction memory
	im : InstructionMemory port map (
		address => mem_pc,
		clock => mem_clk,
		q => inst_mem
	);
	process(clk) begin
		if stall = '1' then
			mem_clk <= '1';
		else
			mem_clk <= clk;
		end if;
		mem_pc <= pc;
	end process;

	-- Open assignments
	this_opcode <= inst_mem(31 downto 26);
	this_Rs1 <= inst_mem(20 downto 16);
	this_Rs2 <= inst_mem(15 downto 11);
	last_opcode <= inst_last(31 downto 26);
	last_rd <= inst_last(25 downto 21);

	-- Create a bubble
	process(last_opcode, this_opcode, last_rd, this_Rs1, this_Rs2) begin
		if last_opcode = OP_LW and OpIsTypeA(this_opcode) = '1' and last_rd = this_Rs1 then
			stall <= '1';
		elsif last_opcode = OP_LW and OpIsTypeB(this_opcode) = '1' and last_rd = this_Rs2 then
			stall <= '1';
		elsif last_opcode = OP_LW and OpIsUARTtx(this_opcode) = '1' and last_rd = this_Rs1 then
			stall <= '1';
		else
			stall <= '0';
		end if;
	end process;

	-- Make sure to block any outputs when branch is taken
	process(inst_mem, br_taken, was_branch1, was_branch2, stall) begin
		if br_taken = '0' and was_branch1 = '0' and was_branch2 = '0' and stall = '0' then
			inst_out <= inst_mem;
		else
			inst_out <= (others => '0');
		end if;
	end process;

	-- Register for storing the past about branches
	process(clk) begin
		if rising_edge(clk) then
			was_branch2 <= was_branch1;
			was_branch1 <= br_taken;
			inst_last <= inst_mem;
		end if;
	end process;

	-- Main process
	process(clk, rst_l) begin
		if rising_edge(clk) then
			-- PC logic
			if rst_l = '0' then
				pc <= B"0000000000";
				pc_out <= pc;
			elsif stall = '1' then
				if	br_taken = '1' then
					pc <= br_addr;
				else
					pc <= pc;
				end if;
			elsif br_taken = '1' then
				pc <= br_addr;
			else
				pc <= std_logic_vector(unsigned(pc) + 1);
				pc_out <= pc;
			end if;
		end if;
	end process;
end architecture behavioral;
