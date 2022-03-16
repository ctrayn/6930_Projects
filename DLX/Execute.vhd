
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
--		OP_EM			: in std_logic_vector(31 downto 0);
--		OP_MW			: in std_logic_vector(31 downto 0);
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
	signal Curr_OP : std_logic_vector(5 downto 0);
	signal InTwo, InOne : std_logic_vector(31 downto 0);
	
	signal MemWr_Rd						: std_logic_vector(4 downto 0);
	signal ExMem_Rd, ExMem_RS1, ExMem_RS2: std_logic_vector(4 downto 0);
	signal Curr_RS1, Curr_RS2			: std_logic_vector(4 downto 0);
	signal ExMem_Op, MemWr_Op			: std_logic_vector(5 downto 0);
	signal stall1, stall2, stall_out : std_logic := '0';
	signal inst_output					: std_logic_vector(31 downto 0);
	signal true								: std_logic;
	signal OP_EM, OP_MW					: std_logic_vector(31 downto 0);
	signal Curr_Rd							: std_logic_vector(4 downto 0);

begin
	stall_out <= stall1 or stall2;
	stall <= stall_out;
	inst_out <= inst_output;
	
	Curr_OP   <= inst_in(31 downto 26);		--This cycle
	Curr_Rd	 <= inst_in(25 downto 21);
	Curr_RS1	 <= inst_in(20 downto 16);
	Curr_RS2	 <= inst_in(15 downto 11);
	ExMem_OP	 <= OP_EM(31 downto 26);		--Last cycles Curr_OP
	ExMem_Rd  <= OP_EM(25 downto 21);
	ExMem_RS1 <= OP_EM(20 downto 16);
	ExMem_RS2 <= OP_EM(15 downto 11);
	MemWr_OP	 <= OP_MW(31 downto 26);		--2 cycles ago Curr_OP
	MemWr_Rd  <= OP_MW(25 downto 21);
	
	--signals that just get delayed and passed on
	process (clk, stall_out, rst_l) begin
		if rising_edge(clk) then
			if rst_l = '0' then
				RS2_out  <= (others => '0');
				inst_output <= (others => '0');
			else
				RS2_out  <= RS2;
				inst_output <= inst_in;
			end if;
			OP_EM <= inst_in;
			OP_MW <= OP_EM;
		end if;
	end process;
	
	--MUX Top ALU Input
	process(clk, ALU_out, RS1, MemWr_data, ExMem_RS1) begin
		if rising_edge(clk) then
			if (MemWr_OP = OP_LW) and (unsigned(MemWr_Rd) = unsigned(ExMem_RS1)) then
				true <= '0';
				stall1 <= '0';
				InOne <= MemWr_data;
			elsif (ExMem_OP = OP_LW) and (ExMem_Rd = Curr_RS1) then
				true <= '0';
				stall1 <= '1';
				InOne <= (others => '0');
--			elsif OpIsRegister(Curr_OP) = '1' and (ExMem_Rd = Curr_RS1) then
			elsif (ExMem_Rd = Curr_RS1) and (unsigned(Curr_OP) >= unsigned(OP_ADD)) and (unsigned(Curr_OP) <= unsigned(OP_SNEI)) then
				true <= '1';
				stall1 <= '0';
				InOne <= ALU_out;
--			elsif(MemWr_Rd = Curr_RS1) then
--				stall1 <= '1';
--				InOne <= MemWr_data;				--two cycles ago alu output
			else
				true <= '0';
				stall1 <= '0';
				InOne <= RS1;
			end if;
		end if;
	end process;
	
	--MUX Bottom ALU Input
	process(clk, Imm, RS2, Curr_OP, ALU_out) begin
		if rising_edge(clk) then
			if OpIsRegister(Curr_OP) = '1' and (ExMem_Rd = Curr_RS2) then
				stall2 <= '0';
				InTwo <= ALU_out;
			elsif (MemWr_OP = OP_LW) and (MemWr_Rd = ExMem_RS2) then
				stall2 <= '1';
				InTwo <= MemWr_data;
			elsif OpIsImmediate(Curr_OP) = '1' then
				stall2 <= '0';
				InTwo <= Imm;
			else
				stall2 <= '0';
				InTwo <= RS2;
			end if;
		end if;
	end process;

	--ALU process
	process (clk, stall_out, rst_l, Curr_OP, InOne, InTwo, Imm, inst_in,pc_in) begin
--		if rising_edge(clk) then
			if (stall_out = '1') or (rst_l = '0') then
				br_taken <= '0';
				br_addr <= (others => '0');
				ALU_out <= (others => '0');
			else
				case Curr_OP is
					when OP_NOP | OP_LW =>
						br_taken <= '0';
						br_addr <= (others => '0');
						ALU_out <= ZEROS;

					when OP_SW =>
						br_taken <= '0';
						br_addr <= (others => '0');
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
						br_addr <= (others => '0');
						ALU_out <= std_logic_vector(signed(InOne) + signed(InTwo));

					when OP_ADDU | OP_ADDUI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						ALU_out <= std_logic_vector(unsigned(InOne) + unsigned(InTwo));

					when OP_SUB | OP_SUBI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						ALU_out <= std_logic_vector(signed(InOne) - signed(InTwo));

					when OP_SUBU | OP_SUBUI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						ALU_out <= std_logic_vector(unsigned(InOne) - unsigned(InTwo));

					when OP_AND | OP_ANDI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						ALU_out <= InOne and InTwo;

					when OP_OR | OP_ORI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						ALU_out <= InOne or InTwo;

					when OP_XOR | OP_XORI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						ALU_out <= InOne xor InTwo;

					when OP_SLL | OP_SLLI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						ALU_out <= std_logic_vector(shift_left(unsigned(InOne), to_integer(unsigned(InTwo))));

					when OP_SRL | OP_SRLI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						ALU_out <= std_logic_vector(shift_right(unsigned(InOne), to_integer(unsigned(InTwo))));

					when OP_SRA | OP_SRAI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						ALU_out <= std_logic_vector(shift_right(signed(InOne), to_integer(unsigned(InTwo))));

					when OP_SLT | OP_SLTI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						if (signed(InOne) < signed(InTwo)) then
							ALU_out <= X"00000001";
						else
							ALU_out <= X"00000000";
						end if;

					when OP_SLTU | OP_SLTUI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						if (unsigned(InOne) < unsigned(InTwo)) then
							ALU_out <= X"00000001";
						else
							ALU_out <= X"00000000";
						end if;

					when OP_SGT | OP_SGTI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						if (signed(InOne) > signed(InTwo)) then
							ALU_out <= X"00000001";
						else
							ALU_out <= X"00000000";
						end if;

					when OP_SGTU | OP_SGTUI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						if (unsigned(InOne) > unsigned(InTwo)) then
							ALU_out <= X"00000001";
						else
							ALU_out <= X"00000000";
						end if;

					when OP_SLE | OP_SLEI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						if (signed(InOne) <= signed(InTwo)) then
							ALU_out <= X"00000001";
						else
							ALU_out <= X"00000000";
						end if;

					when OP_SLEU | OP_SLEUI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						if (unsigned(InOne) <= unsigned(InTwo)) then
							ALU_out <= X"00000001";
						else
							ALU_out <= X"00000000";
						end if;

					when OP_SGE | OP_SGEI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						if (signed(InOne) >= signed(InTwo)) then
							ALU_out <= X"00000001";
						else
							ALU_out <= X"00000000";
						end if;

					when OP_SGEU | OP_SGEUI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						if (unsigned(InOne) >= unsigned(InTwo)) then
							ALU_out <= X"00000001";
						else
							ALU_out <= X"00000000";
						end if;

					when OP_SEQ | OP_SEQI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						if (unsigned(InOne) = unsigned(InTwo)) then
							ALU_out <= X"00000001";
						else
							ALU_out <= X"00000000";
						end if;

					when OP_SNE | OP_SNEI =>
						br_taken <= '0';
						br_addr <= (others => '0');
						if (unsigned(InOne) = unsigned(InTwo)) then
							ALU_out <= X"00000000";
						else
							ALU_out <= X"00000001";
						end if;

					when others =>
						br_taken <= '0';
						br_addr <= (others => '0');
						ALU_out <= ZEROS;

				end case;
			end if;
--		end if;
	end process;
end architecture behavioral;
