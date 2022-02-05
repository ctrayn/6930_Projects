library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Decode is
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
end entity Decode;

architecture behavioral of Decode is
	
	-- Build a 2-D array type for the RAM
	subtype reg_t is std_logic_vector(31 downto 0);
	type memory_t is array(31 downto 0) of reg_t;
	
	-- Declare the RAM signal.
	signal ram : memory_t;
	signal opcode 	: std_logic_vector(5  downto 0);
	signal rd		: natural;
	signal r1		: natural;
	signal r2		: natural;
	signal im_val	: std_logic_vector(15 downto 0);
	
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
	constant OP_JALR	: std_logic_vector(5 downto 0) := B"11000";
	
begin

	--rename some parts of the input instruction
	opcode 	<= IR_in(31 downto 26);
	rd	   	<= to_integer(unsigned(IR_in(25 downto 21)));
	r1			<= to_integer(unsigned(IR_in(20 downto 16)));
	r2 		<= to_integer(unsigned(IR_in(15 downto 11)));
	im_val 	<= IR_in(15 downto 0);
	
	--Signals that just get delayed and passed on
	process(clk) begin
		pc_out <= pc_in;
		IR_out <= IR_in;
	end process;
	
	--Write
	process(clk) begin
		if (w_addr = B"0000000000") then
			ram(to_integer(unsigned(w_addr))) <= w_data;
		end if;
	end process;
	
	--Read
	process(clk) begin
		case opcode is
			when OP_NOP | OP_J | OP_JAL =>
				RS1 <= (others => '0');
				RS2 <= (others => '0');
				Imm <= (others => '0');
				
			when OP_LW | OP_SW =>
				RS1 <= ram(r1);
				RS2 <= (others => '0');
				Imm <= (others => '0');
				
			when OP_JR | OP_JALR | OP_BEQZ | OP_BNEZ =>
				RS1 <= ram(rd);
				RS2 <= (others => '0');
				Imm <= (others => '0');
				
			when OP_ADD | OP_ADDU | OP_SUB | OP_SUBU =>
				RS1 <= ram(r1);
				RS2 <= ram(r2);
				Imm <= (others => '0');
				
			when OP_ADDI | OP_SUBI =>
				RS1 <= ram((r1));
				RS2 <= (others => '0');
				Imm(15 downto 0) <= im_val;
				Imm(31 downto 16) <= (others => im_val(15));		--sign extend
				
			when OP_ADDUI | OP_SUBUI =>
				RS1 <= ram(r1);
				RS2 <= (others => '0');
				Imm(15 downto 0) <= im_val;
				Imm(16 downto 0) <= (others => '0');
				
			when OP_AND | OP_OR | OP_XOR =>
				RS1 <= ram(r1);
				RS2 <= ram(r2);
				Imm <= (others => '0');
				
			when OP_ANDI | OP_ORI | OP_XORI =>
				RS1 <= ram(r1);
				RS2 <= (others => '0');
				Imm(15 downto 0) <= im_val;
				Imm(16 downto 0) <= (others => '0');
				
			when OP_SLL | OP_SRL | OP_SRA =>
				RS1 <= ram(r1);
				RS2 <= ram(r2);
				Imm <= (others => '0');
				
			when OP_SLT | OP_SLTU | OP_SGT | OP_SGTU =>
				RS1 <= ram(r1);
				RS2 <= ram(r2);
				Imm <= (others => '0');
				
			when OP_SLTI | OP_SGTI  =>
				RS1 <= ram(r1);
				RS2 <= (others => '0');
				Imm(15 downto 0) <= im_val;
				Imm(31 downto 16) <= (others => im_val(15));		--sign extend
				
			when OP_SLTUI | OP_SGTUI =>
				RS1 <= ram(r1);
				RS2 <= (others => '0');
				Imm(15 downto 0) <= im_val;
				Imm(16 downto 0) <= (others => '0');
				
			when OP_SLE | OP_SLEU | OP_SGE | OP_SGEU | OP_SEQ | OP_SNE =>
				RS1 <= ram(r1);
				RS2 <= ram(r2);
				Imm <= (others => '0');
				
			when OP_SLEI | OP_SGEI | OP_SEQI | OP_SNEI =>
				RS1 <= ram(r1);
				RS2 <= (others => '0');
				Imm(15 downto 0) <= im_val;
				Imm(31 downto 16) <= (others => im_val(15));		--sign extend
				
			when OP_SLEUI | OP_SGEUI =>
				RS1 <= ram(r1);
				RS2 <= (others => '0');
				Imm(15 downto 0) <= im_val;
				Imm(16 downto 0) <= (others => '0');				
		
		end case;
	end process;

end architecture behavioral;