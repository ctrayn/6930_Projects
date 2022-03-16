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

entity Execute is
	port (
		--INPUT
		clk 			: in std_logic;
		rst_l 		: in std_logic;
		pc_in 		: in std_logic_vector(9  downto 0);
		inst_in 		: in std_logic_vector(31 downto 0);
		RS1 			: in std_logic_vector(31 downto 0);
		RS2 			: in std_logic_vector(31 downto 0);
		Imm 			: in std_logic_vector(31 downto 0);
		MemWr_data	: in std_logic_vector(31 downto 0);		--Memory/WriteBack Loaded Word
		OP_EM			: in std_logic_vector(31 downto 0);
		OP_MW			: in std_logic_vector(31 downto 0);
		--OUTPUT
		stall			: out std_logic;
		ALU_out 		: inout std_logic_vector(31 downto 0);
		br_taken 	: out std_logic;
		br_addr  	: out std_logic_vector(9 downto 0);
		RS2_out 		: out std_logic_vector(31 downto 0);
		inst_out 	: out std_logic_vector(31 downto 0)
	);
end entity Execute;

architecture behavioral of Execute is
	signal opcode : std_logic_vector(5 downto 0);
	signal InTwo, InOne : std_logic_vector(31 downto 0);
	
	signal MemWr_Rd, ExMem_Rd, RS1_curr, ExMem_RS1	: std_logic_vector(4 downto 0);
	signal ExMem_Inst, MemWr_Inst : std_logic_vector(31 downto 0);
	signal ExMem_Op, MemWr_Op		: std_logic_vector(5 downto 0);
	signal stall1, stall2, stall_out : std_logic := '0';
--	signal true	: std_logic;

begin
	stall_out <= stall1 or stall2;
	stall <= stall_out;
	
	
	opcode <= inst_in(31 downto 26);
	--signals that just get delayed and passed on
	process (clk) begin
		if rising_edge(clk) then
			if (stall_out = '1') or (rst_l = '0') then
				RS2_out <= (others => '0');
				inst_out <= (others => '0');
				ExMem_Inst <= (others => '0');
			else
				RS2_out <= RS2;
				inst_out <= inst_in;
				ExMem_Inst <= inst_in;
			end if;
			MemWr_Inst <= ExMem_Inst;
			ExMem_RS1 <= RS1_curr;
		end if;
	end process;

	ExMem_Rd <= OP_EM(25 downto 21);		--Last cycles OPCODE
	MemWr_Rd <= OP_MW(25 downto 21);		--2 cycles ago OPCODE
	RS1_curr  <= inst_in(20 downto 16);
	ExMem_OP	<= ExMem_Inst(31 downto 26);
	MemWr_OP	<= MemWr_Inst(31 downto 26);
	
	--Data hazard Read After Write: Mux RS1
	process(clk) begin
		if rising_edge(clk) then
			if OpIsRegister(opcode) = '1' and (ExMem_Rd = RS1_curr) then		--Data Hazards
				stall1 <= '0';
				InOne <= ALU_out;
			elsif (ExMem_OP = OP_LW) and (ExMem_Rd = RS1_curr) then
				stall1 <= '1';
				InOne <= (others => '0');
			elsif (MemWr_OP = OP_LW) and (unsigned(MemWr_Rd) = unsigned(ExMem_RS1)) then
				stall1 <= '0';
				InOne <= MemWr_data;
--			elsif(MemWr_Rd = RS1_curr) then
--				stall1 <= '1';
--				InOne <= MemWr_data;				--two cycles ago alu output
			else
				stall1 <= '0';
				InOne <= RS1;
			end if;
		end if;
	end process;
	
	--MUX RS2 and Imm
	process(clk, Imm, RS2, opcode) begin
		if rising_edge(clk) then
			if OpIsRegister(opcode) = '1' and (ExMem_Rd = RS1_curr) then
				stall2 <= '0';
				InTwo <= ALU_out;
--			elsif (MemWr_OP = OP_LW) and (MemWr_Rd = ExMem_RS1) then
--				stall2 <= '1';
--				InTwo <= MemWr_data;
			elsif OpIsImmediate(opcode) = '1' then
				stall2 <= '0';
				InTwo <= Imm;
			else
				stall2 <= '0';
				InTwo <= RS2;
			end if;
		end if;
	end process;

	--ALU process
	process (clk, stall_out, rst_l) begin
		if rising_edge(clk) then
			if (stall_out = '1') or (rst_l = '0') then
				br_taken <= '0';
				ALU_out <= (others => '0');
			else
				case opcode is
					when OP_NOP | OP_LW =>
						br_taken <= '0';
						ALU_out <= ZEROS;

					when OP_SW =>
						br_taken <= '0';
						ALU_out <= std_logic_vector(unsigned(InOne) + unsigned(Imm));

					when OP_J =>
						br_taken <= '1';
						br_addr <= inst_in(9 downto 0);
						ALU_out <= ZEROS;

					when OP_JAL =>
						br_taken <= '1';
						br_addr <= inst_in(9 downto 0);
						ALU_out(31 downto 10) <= (others => '0');
						ALU_out(9 downto 0) <= pc_in;

					when OP_JR =>
						br_taken <= '1';
						br_addr <= InOne(9 downto 0);
						ALU_out <= ZEROS;

					when OP_JALR =>
						br_taken <= '1';
						br_addr <= InOne(9 downto 0);
						ALU_out(31 downto 10) <= (others => '0');
						ALU_out(9 downto 0) <= pc_in;

					when OP_BEQZ =>
						if (InOne = ZEROS) then
							br_taken <= '1';
						else
							br_taken <= '0';
						end if;
						br_addr <= inst_in(9 downto 0);
						ALU_out <= ZEROS;

					when OP_BNEZ =>
						if (InOne = ZEROS) then
							br_taken <= '0';
						else
							br_taken <= '1';
						end if;
						br_addr <= inst_in(9 downto 0);
						ALU_out <= ZEROS;

					when OP_ADD | OP_ADDI =>
						br_taken <= '0';
						ALU_out <= std_logic_vector(signed(InOne) + signed(InTwo));

					when OP_ADDU | OP_ADDUI =>
						br_taken <= '0';
						ALU_out <= std_logic_vector(unsigned(InOne) + unsigned(InTwo));

					when OP_SUB | OP_SUBI =>
						br_taken <= '0';
						ALU_out <= std_logic_vector(signed(InOne) - signed(InTwo));

					when OP_SUBU | OP_SUBUI =>
						br_taken <= '0';
						ALU_out <= std_logic_vector(unsigned(InOne) - unsigned(InTwo));

					when OP_AND | OP_ANDI =>
						br_taken <= '0';
						ALU_out <= InOne and InTwo;

					when OP_OR | OP_ORI =>
						br_taken <= '0';
						ALU_out <= InOne or InTwo;

					when OP_XOR | OP_XORI =>
						br_taken <= '0';
						ALU_out <= InOne xor InTwo;

					when OP_SLL | OP_SLLI =>
						br_taken <= '0';
						ALU_out <= std_logic_vector(shift_left(unsigned(InOne), to_integer(unsigned(InTwo))));

					when OP_SRL | OP_SRLI =>
						br_taken <= '0';
						ALU_out <= std_logic_vector(shift_right(unsigned(InOne), to_integer(unsigned(InTwo))));

					when OP_SRA | OP_SRAI =>
						br_taken <= '0';
						ALU_out <= std_logic_vector(shift_right(signed(InOne), to_integer(unsigned(InTwo))));

					when OP_SLT | OP_SLTI =>
						br_taken <= '0';
						if (signed(InOne) < signed(InTwo)) then
							ALU_out <= X"00000001";
						else
							ALU_out <= X"00000000";
						end if;

					when OP_SLTU | OP_SLTUI =>
						br_taken <= '0';
						if (unsigned(InOne) < unsigned(InTwo)) then
							ALU_out <= X"00000001";
						else
							ALU_out <= X"00000000";
						end if;

					when OP_SGT | OP_SGTI =>
						br_taken <= '0';
						if (signed(InOne) > signed(InTwo)) then
							ALU_out <= X"00000001";
						else
							ALU_out <= X"00000000";
						end if;

					when OP_SGTU | OP_SGTUI =>
						br_taken <= '0';
						if (unsigned(InOne) > unsigned(InTwo)) then
							ALU_out <= X"00000001";
						else
							ALU_out <= X"00000000";
						end if;

					when OP_SLE | OP_SLEI =>
						br_taken <= '0';
						if (signed(InOne) <= signed(InTwo)) then
							ALU_out <= X"00000001";
						else
							ALU_out <= X"00000000";
						end if;

					when OP_SLEU | OP_SLEUI =>
						br_taken <= '0';
						if (unsigned(InOne) <= unsigned(InTwo)) then
							ALU_out <= X"00000001";
						else
							ALU_out <= X"00000000";
						end if;

					when OP_SGE | OP_SGEI =>
						br_taken <= '0';
						if (signed(InOne) >= signed(InTwo)) then
							ALU_out <= X"00000001";
						else
							ALU_out <= X"00000000";
						end if;

					when OP_SGEU | OP_SGEUI =>
						br_taken <= '0';
						if (unsigned(InOne) >= unsigned(InTwo)) then
							ALU_out <= X"00000001";
						else
							ALU_out <= X"00000000";
						end if;

					when OP_SEQ | OP_SEQI =>
						br_taken <= '0';
						if (unsigned(InOne) = unsigned(InTwo)) then
							ALU_out <= X"00000001";
						else
							ALU_out <= X"00000000";
						end if;

					when OP_SNE | OP_SNEI =>
						br_taken <= '0';
						if (unsigned(InOne) = unsigned(InTwo)) then
							ALU_out <= X"00000000";
						else
							ALU_out <= X"00000001";
						end if;

					when others =>
						br_taken <= '0';
						ALU_out <= ZEROS;

				end case;
			end if;
		end if;
	end process;
end architecture behavioral;
