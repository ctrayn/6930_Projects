---------------------------------------------------------
-- DLX Processor
--
-- Jonah Boe
-- Calvin Passmore
-- Utah State University
-- ECE 6930, Spring 2022
---------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- Our states need to be accesable to everyone
package common is
	--Constants
	constant OP_NOP	: std_logic_vector(5 downto 0) := B"000000";
	constant OP_LW		: std_logic_vector(5 downto 0) := B"000001";
	constant OP_SW		: std_logic_vector(5 downto 0) := B"000010";
	constant OP_ADD	: std_logic_vector(5 downto 0) := B"000011";
	constant OP_ADDI	: std_logic_vector(5 downto 0) := B"000100";
	constant OP_ADDU	: std_logic_vector(5 downto 0) := B"000101";
	constant OP_ADDUI	: std_logic_vector(5 downto 0) := B"000110";
	constant OP_SUB	: std_logic_vector(5 downto 0) := B"000111";
	constant OP_SUBI	: std_logic_vector(5 downto 0) := B"001000";
	constant OP_SUBU	: std_logic_vector(5 downto 0) := B"001001";
	constant OP_SUBUI	: std_logic_vector(5 downto 0) := B"001010";
	constant OP_AND	: std_logic_vector(5 downto 0) := B"001011";
	constant OP_ANDI	: std_logic_vector(5 downto 0) := B"001100";
	constant OP_OR		: std_logic_vector(5 downto 0) := B"001101";
	constant OP_ORI	: std_logic_vector(5 downto 0) := B"001110";
	constant OP_XOR	: std_logic_vector(5 downto 0) := B"001111";
	constant OP_XORI	: std_logic_vector(5 downto 0) := B"010000";
	constant OP_SLL	: std_logic_vector(5 downto 0) := B"010001";
	constant OP_SLLI	: std_logic_vector(5 downto 0) := B"010010";
	constant OP_SRL	: std_logic_vector(5 downto 0) := B"010011";
	constant OP_SRLI	: std_logic_vector(5 downto 0) := B"010100";
	constant OP_SRA	: std_logic_vector(5 downto 0) := B"010101";
	constant OP_SRAI	: std_logic_vector(5 downto 0) := B"010110";
	constant OP_SLT	: std_logic_vector(5 downto 0) := B"010111";
	constant OP_SLTI	: std_logic_vector(5 downto 0) := B"011000";
	constant OP_SLTU	: std_logic_vector(5 downto 0) := B"011001";
	constant OP_SLTUI	: std_logic_vector(5 downto 0) := B"011010";
	constant OP_SGT	: std_logic_vector(5 downto 0) := B"011011";
	constant OP_SGTI	: std_logic_vector(5 downto 0) := B"011100";
	constant OP_SGTU	: std_logic_vector(5 downto 0) := B"011101";
	constant OP_SGTUI	: std_logic_vector(5 downto 0) := B"011110";
	constant OP_SLE	: std_logic_vector(5 downto 0) := B"011111";
	constant OP_SLEI	: std_logic_vector(5 downto 0) := B"100000";
	constant OP_SLEU	: std_logic_vector(5 downto 0) := B"100001";
	constant OP_SLEUI	: std_logic_vector(5 downto 0) := B"100010";
	constant OP_SGE	: std_logic_vector(5 downto 0) := B"100011";
	constant OP_SGEI	: std_logic_vector(5 downto 0) := B"100100";
	constant OP_SGEU	: std_logic_vector(5 downto 0) := B"100101";
	constant OP_SGEUI	: std_logic_vector(5 downto 0) := B"100110";
	constant OP_SEQ	: std_logic_vector(5 downto 0) := B"100111";
	constant OP_SEQI	: std_logic_vector(5 downto 0) := B"101000";
	constant OP_SNE	: std_logic_vector(5 downto 0) := B"101001";
	constant OP_SNEI	: std_logic_vector(5 downto 0) := B"101010";
	constant OP_BEQZ	: std_logic_vector(5 downto 0) := B"101011";
	constant OP_BNEZ	: std_logic_vector(5 downto 0) := B"101100";
	constant OP_J		: std_logic_vector(5 downto 0) := B"101101";
	constant OP_JR		: std_logic_vector(5 downto 0) := B"101110";
	constant OP_JAL	: std_logic_vector(5 downto 0) := B"101111";
	constant OP_JALR	: std_logic_vector(5 downto 0) := B"110000";

	-- Function 1: returns '1' if function is a store function
	function OpIsWriteBack (op : std_logic_vector(5 downto 0)) return std_logic;
end common;

package body common is
	-- Function 1 body: returns '1' if function is a store function
   function OpIsWriteBack (op : std_logic_vector(5 downto 0)) return std_logic is
	begin
		if op = OP_LW or op = OP_ADD or op = OP_ADDI then
			return '1';
		else
			return '0';
		end if;
	end OpIsWriteBack;
end common;
