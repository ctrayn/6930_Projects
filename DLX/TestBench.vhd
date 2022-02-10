library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity TestBench is
end entity TestBench;

architecture behavioral of TestBench is
	component DLX
      port(
         -- INPUT
         ADC_CLK_10 		: in 	std_logic;
         RST_L				: in  std_logic;
         -- OUTPUT
         -- TEMP: for testing
         br_taken	      : in std_logic;
         br_addr	      : in std_logic_vector(9 downto 0);
         wb_inst	      : in std_logic_vector(31 downto 0);
         wb_data	      : in std_logic_vector(31 downto 0);
         pc_DE 	      : out std_logic_vector(9 downto 0);
   		inst_DE 	      : out std_logic_vector(31 downto 0);
   		imm_DE	      : out std_logic_vector(31 downto 0);
   		rs1_DE	      : out std_logic_vector(31 downto 0);
   		rs2_DE	      : out std_logic_vector(31 downto 0)
      );
	end component;

	constant CLK_PERIOD  : time := 10 ns;
	constant WAIT_TIME   : integer := 10000;

	signal clk           : std_logic := '0';
	signal rst_l         : std_logic := '1';
	signal br_taken 	   : std_logic := '0';
	signal br_addr  	   : std_logic_vector(9 downto 0);
   signal wb_inst       : std_logic_vector(31 downto 0);
   signal wb_data       : std_logic_vector(31 downto 0);
   signal pc_DE         : std_logic_vector(9 downto 0);
	signal inst_DE       : std_logic_vector(31 downto 0);
   signal imm_DE        : std_logic_vector(31 downto 0);
   signal rs1_DE	      : std_logic_vector(31 downto 0);
   signal rs2_DE	      : std_logic_vector(31 downto 0);

begin

   -- Our unit under test
	dut : DLX
		port map (
			ADC_CLK_10 => clk,
			RST_L => rst_l,
			br_taken => br_taken,
			br_addr => br_addr,
         wb_inst => wb_inst,
         wb_data => wb_data,
         pc_DE => pc_DE,
			inst_DE => inst_DE,
         imm_DE => imm_DE,
         rs1_DE => rs1_DE,
         rs2_DE => rs2_DE
		);

   -- Some signals
   wb_inst <= inst_DE;

   -- Clock process
	clk_process : process begin
		clk <= '0';
		wait for CLK_PERIOD/2;
		clk <= '1';
		wait for CLK_PERIOD/2;
	end process;

   -- Test process
	stm_process: process begin
		rst_l <= '1';
		br_taken <= '0';
      br_addr <= B"0000000000";
      wb_data <= X"00000000";
		wait for CLK_PERIOD/2;

		wait for CLK_PERIOD * 2;

		wait for CLK_PERIOD / 2;			-- LW set wb_data
      wb_data <= X"00000002";
      wait for CLK_PERIOD;
      wb_data <= X"00000000";
		wait for CLK_PERIOD / 2;

      wait for CLK_PERIOD;

		br_addr <= B"0000000111";			-- JAL 007: multiply
		br_taken <= '1';
		wait for CLK_PERIOD;
		br_taken <= '0';

		wait for CLK_PERIOD / 2;			-- 004: set wb_data
      wb_data <= X"00000005";
      wait for CLK_PERIOD;
      wb_data <= X"00000001";
		wait for CLK_PERIOD;
      wb_data <= X"00000005";
      wait for CLK_PERIOD;
      wb_data <= X"00000002";
		wait for CLK_PERIOD;
		wb_data <= X"00000001";
		wait for CLK_PERIOD;
		wb_data <= X"00000000";
		wait for CLK_PERIOD / 2;

		br_addr <= B"0000010000";			-- JAL 010: add
		br_taken <= '1';
		wait for CLK_PERIOD;
		br_taken <= '0';

		wait for CLK_PERIOD / 2;			-- 00C: set wb_data
      wb_data <= X"0000000D";
      wait for CLK_PERIOD;
      wb_data <= X"00000000";
		wait for CLK_PERIOD * 2;
		wb_data <= X"00000001";
		wait for CLK_PERIOD;
		wb_data <= X"00000000";
		wait for CLK_PERIOD / 2;

		br_addr <= B"0000001101";			-- JR 00D: R31
		br_taken <= '1';
		wait for CLK_PERIOD / 2;
		wb_data <= X"00000002";
		wait for CLK_PERIOD / 2;
		br_taken <= '0';

		wait for CLK_PERIOD / 2;
		wb_data <= X"00000000";
		wait for CLK_PERIOD / 2;

		wait for CLK_PERIOD;

		wait for CLK_PERIOD / 2;			-- 00D: set wb_data
		wb_data <= X"00000002";
		wait for CLK_PERIOD / 2;

		br_addr <= B"0000001010";			-- JAL 00A: loop
		br_taken <= '1';
		wait for CLK_PERIOD;
		br_taken <= '0';

		wait for CLK_PERIOD / 2;
		wb_data <= X"00000000";
		wait for CLK_PERIOD / 2;

		wait for CLK_PERIOD;

		br_addr <= B"0000010101";			-- BNEZ 015: break
		br_taken <= '1';
		wait for CLK_PERIOD;
		br_taken <= '0';

		wait for CLK_PERIOD;

		br_addr <= B"0000000101";			-- JR 005: R30
		br_taken <= '1';
		wait for CLK_PERIOD;
		br_taken <= '0';

		wait for CLK_PERIOD;

		br_addr <= B"0000000010";			-- J 002: main
		br_taken <= '1';
		wait for CLK_PERIOD;
		br_taken <= '0';

		wait for CLK_PERIOD * 2;

		br_addr <= B"0000010110";			-- BNEZ 016: exit
		br_taken <= '1';

		wait for CLK_PERIOD / 2;			-- 002: set wb_data
      wb_data <= X"00000001";
		wait for CLK_PERIOD / 2;
		br_taken <= '0';
		wait for CLK_PERIOD / 2;
      wb_data <= X"00000000";

		br_addr <= B"0000010111";			-- J 017: done
		br_taken <= '1';

		wait;
	end process;

end architecture behavioral;
