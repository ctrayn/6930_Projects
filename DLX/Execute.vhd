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
		MemWb_inst	: in std_logic_vector(31 downto 0);
		MemWb_data	: in std_logic_vector(31 downto 0);
		--OUTPUT
		ALU_out 		: out std_logic_vector(31 downto 0);
		br_taken 	: out std_logic;
		br_addr  	: out std_logic_vector(9 downto 0);
		RS2_out 		: out std_logic_vector(31 downto 0);
		inst_out 	: out std_logic_vector(31 downto 0);
		data_tx		: out std_logic_vector(35 downto 0);
		tx_write		: out std_logic
	);
end entity Execute;

architecture behavioral of Execute is
	signal opcode 		: std_logic_vector(5 downto 0);
	signal InOne		: std_logic_vector(31 downto 0);
	signal InTwo		: std_logic_vector(31 downto 0);
	signal branch		: std_logic := '0';
	signal ALU_result	: std_logic_vector(31 downto 0);

	-- Signals for fast forwarding
	-- This stage
	signal IdEx_Rs1		: std_logic_vector(4 downto 0);
	signal IdEx_Rs2		: std_logic_vector(4 downto 0);
	signal IdEx_rd 		: std_logic_vector(4 downto 0); 
	-- Memory stage
	signal ExMem_inst 	: std_logic_vector(31 downto 0);
	signal ExMem_opcode	: std_logic_vector(5 downto 0); 
	signal ExMem_rd 		: std_logic_vector(4 downto 0); 
	-- Writeback stage
	signal MemWb_opcode	: std_logic_vector(5 downto 0); 
	signal MemWb_rd 		: std_logic_vector(4 downto 0);
	signal true				: std_logic;

begin
	-- Open signals
	br_taken <= branch;
	ALU_out <= ALU_result;
	-- This stage
	IdEx_Rs1 <= inst_in(20 downto 16);
	IdEx_Rs2 <= inst_in(15 downto 11);
	IdEx_rd <= inst_in(25 downto 21);
	-- Memory stage
	inst_out <= ExMem_inst;
	ExMem_opcode <= ExMem_inst(31 downto 26);
	ExMem_rd <= ExMem_inst(25 downto 21);
	-- Writeback stage
	MemWb_opcode <= MemWb_inst(31 downto 26);
	MemWb_rd <= MemWb_inst(25 downto 21);

	-- We want to clear the input instruction in case of branches
	process(inst_in, branch) begin	
		if branch = '0' then
			opcode <= inst_in(31 downto 26);
		else
			opcode <= (others => '0');
		end if;
	end process;

	--signals that just get delayed and passed on
	process (clk) begin
		if rising_edge(clk) then
			if branch = '0' then
				ExMem_inst <= inst_in;
			else
				ExMem_inst <= (others => '0');
			end if;
			RS2_out <= (others => '0');
		end if;
	end process;

	--MUX 1
	process(ExMem_opcode, opcode, ExMem_rd, IdEx_Rs1, ALU_result, MemWb_opcode, MemWb_rd, MemWb_data, RS1) begin
		-- Regular ALU type stuff
		if OpIsALU(ExMem_opcode) = '1' and OpIsTypeA(opcode) = '1' and ExMem_rd = IdEx_Rs1 then
			InOne <= ALU_result;
			true <= '0';
		elsif OpIsALU(MemWb_opcode) = '1' and OpIsTypeA(opcode) = '1' and MemWb_rd = IdEx_Rs1 then
			InOne <= MemWb_data;
			true <= '0';
		-- Branches need a special case
		elsif OpIsALU(ExMem_opcode) = '1' and OpIsBranch(opcode) = '1' and ExMem_rd = IdEx_rd then
			InOne <= ALU_result;
			true <= '0';
		elsif OpIsALU(MemWb_opcode) = '1' and OpIsBranch(opcode) = '1' and MemWb_rd = IdEx_rd then
			InOne <= MemWb_data;
			true <= '0';
		-- Load word needs a special case
		elsif MemWb_opcode = OP_LW and OpIsTypeA(opcode) = '1' and MemWb_rd = IdEx_Rs1 then
			InOne <= MemWb_data;
			true <= '0';
		else
			InOne <= RS1;
			true <= '1';
		end if;
	end process;

	--MUX 2
	process(ExMem_opcode, opcode, ExMem_rd, IdEx_Rs2, ALU_result, MemWb_opcode, MemWb_rd, MemWb_data, Imm, RS2) begin
		if OpIsALU(ExMem_opcode) = '1' and OpIsTypeB(opcode) = '1' and ExMem_rd = IdEx_Rs2 then
			InTwo <= ALU_result;
		elsif OpIsALU(MemWb_opcode) = '1' and OpIsTypeB(opcode) = '1' and MemWb_rd = IdEx_Rs2 then
			InTwo <= MemWb_data;
		elsif MemWb_opcode = OP_LW and OpIsTypeB(opcode) = '1' and MemWb_rd = IdEx_Rs2 then
			InTwo <= MemWb_data;
		elsif OpIsImmediate(opcode) = '1' or opcode = OP_SW then
			InTwo <= Imm;
		else
			InTwo <= RS2;
		end if;
	end process;

	--ALU process
	process (clk) begin
		if rising_edge(clk) then
			case opcode is
				when OP_NOP | OP_LW =>
					branch <= '0';
					ALU_result <= ZEROS;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_SW =>
					branch <= '0';
					ALU_result <= std_logic_vector(unsigned(InOne) + unsigned(InTwo));
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_J =>
					branch <= '1';
					br_addr <= inst_in(9 downto 0);
					ALU_result <= ZEROS;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_JAL =>
					branch <= '1';
					br_addr <= inst_in(9 downto 0);
					ALU_result(31 downto 10) <= (others => '0');
					ALU_result(9 downto 0) <= pc_in;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_JR =>
					branch <= '1';
					br_addr <= InOne(9 downto 0);
					ALU_result <= ZEROS;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_JALR =>
					branch <= '1';
					br_addr <= InOne(9 downto 0);
					ALU_result(31 downto 10) <= (others => '0');
					ALU_result(9 downto 0) <= pc_in;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_BEQZ =>
					if InOne = ZEROS then
						branch <= '1';
					else
						branch <= '0';
					end if;
					br_addr <= inst_in(9 downto 0);
					ALU_result <= ZEROS;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_BNEZ =>
					if InOne = ZEROS then
						branch <= '0';
					else
						branch <= '1';
					end if;
					br_addr <= inst_in(9 downto 0);
					ALU_result <= ZEROS;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_ADD | OP_ADDI =>
					branch <= '0';
					ALU_result <= std_logic_vector(signed(InOne) + signed(InTwo));
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_ADDU | OP_ADDUI =>
					branch <= '0';
					ALU_result <= std_logic_vector(unsigned(InOne) + unsigned(InTwo));
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_SUB | OP_SUBI =>
					branch <= '0';
					ALU_result <= std_logic_vector(signed(InOne) - signed(InTwo));
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_SUBU | OP_SUBUI =>
					branch <= '0';
					ALU_result <= std_logic_vector(unsigned(InOne) - unsigned(InTwo));
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_AND | OP_ANDI =>
					branch <= '0';
					ALU_result <= InOne and InTwo;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_OR | OP_ORI =>
					branch <= '0';
					ALU_result <= InOne or InTwo;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_XOR | OP_XORI =>
					branch <= '0';
					ALU_result <= InOne xor InTwo;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_SLL | OP_SLLI =>
					branch <= '0';
					ALU_result <= std_logic_vector(shift_left(unsigned(InOne), to_integer(unsigned(InTwo))));
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_SRL | OP_SRLI =>
					ALU_result <= std_logic_vector(shift_right(unsigned(InOne), to_integer(unsigned(InTwo))));
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_SRA | OP_SRAI =>
					ALU_result <= std_logic_vector(shift_right(signed(InOne), to_integer(unsigned(InTwo))));
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_SLT | OP_SLTI =>
					branch <= '0';
					if (signed(InOne) < signed(InTwo)) then
						ALU_result <= X"00000001";
					else
						ALU_result <= X"00000000";
					end if;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_SLTU | OP_SLTUI =>
					branch <= '0';
					if (unsigned(InOne) < unsigned(InTwo)) then
						ALU_result <= X"00000001";
					else
						ALU_result <= X"00000000";
					end if;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_SGT | OP_SGTI =>
					branch <= '0';
					if (signed(InOne) > signed(InTwo)) then
						ALU_result <= X"00000001";
					else
						ALU_result <= X"00000000";
					end if;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_SGTU | OP_SGTUI =>
					branch <= '0';
					if (unsigned(InOne) > unsigned(InTwo)) then
						ALU_result <= X"00000001";
					else
						ALU_result <= X"00000000";
					end if;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_SLE | OP_SLEI =>
					branch <= '0';
					if (signed(InOne) <= signed(InTwo)) then
						ALU_result <= X"00000001";
					else
						ALU_result <= X"00000000";
					end if;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_SLEU | OP_SLEUI =>
					branch <= '0';
					if (unsigned(InOne) <= unsigned(InTwo)) then
						ALU_result <= X"00000001";
					else
						ALU_result <= X"00000000";
					end if;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_SGE | OP_SGEI =>
					branch <= '0';
					if (signed(InOne) >= signed(InTwo)) then
						ALU_result <= X"00000001";
					else
						ALU_result <= X"00000000";
					end if;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_SGEU | OP_SGEUI =>
					branch <= '0';
					if (unsigned(InOne) >= unsigned(InTwo)) then
						ALU_result <= X"00000001";
					else
						ALU_result <= X"00000000";
					end if;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_SEQ | OP_SEQI =>
					branch <= '0';
					if (unsigned(InOne) = unsigned(InTwo)) then
						ALU_result <= X"00000001";
					else
						ALU_result <= X"00000000";
					end if;
					tx_write <= '0';
					data_tx <= (others => '0');

				when OP_SNE | OP_SNEI =>
					branch <= '0';
					if (unsigned(InOne) = unsigned(InTwo)) then
						ALU_result <= X"00000000";
					else
						ALU_result <= X"00000001";
					end if;
					tx_write <= '0';
					data_tx <= (others => '0');
					
				when OP_PCH =>
					branch <= '0';
					ALU_result <= ZEROS;
					data_tx(31 downto 0)  <= InOne;
					data_tx(35 downto 32) <= X"0";
					tx_write <= '1';
					
				when OP_PD =>
					branch <= '0';
					ALU_result <= ZEROS;
					data_tx(31 downto 0)  <= InOne;
					data_tx(35 downto 32) <= X"1";
					tx_write <= '1';
					
				when OP_PDU =>
					branch <= '0';
					ALU_result <= ZEROS;
					ALU_result <= ZEROS;
					data_tx(31 downto 0)  <= InOne;
					data_tx(35 downto 32) <= X"2";
					tx_write <= '1';
					
				when others =>
					branch <= '0';
					ALU_result <= ZEROS;
					tx_write <= '0';
					data_tx <= (others => '0');
			end case;
		end if;
	end process;
end architecture behavioral;
