library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity TB_UART is
end entity TB_UART;

architecture behavioral of TB_UART is
	component Decode
      port(
         --INPUT
         clk					: in std_logic;
         rst_l					: in std_logic;
         pc_in					: in std_logic_vector(9  downto 0);
         inst_in				: in std_logic_vector(31 downto 0);
         wb_inst				: in std_logic_vector(31 downto 0);			--Write instruction
         wb_data				: in std_logic_vector(31 downto 0);			--Write data
         br_taken				: in std_logic;
         --OUTPUT
         Imm					: out std_logic_vector(31 downto 0);		--Immediate value
         pc_out				: out std_logic_vector(9  downto 0);		--Program counter, delayed by 1 cycle
         inst_out				: out std_logic_vector(31 downto 0);		--The instruction, delayed by 1 cycle
         RS1					: out std_logic_vector(31 downto 0);		--The data from RS1
         RS2					: out std_logic_vector(31 downto 0);			--The data from RS2

         --UART
         rx_data_empty		: in std_logic;
         rx_data				: in std_logic_vector(31 downto 0);
         rx_ack				: out std_logic := '0'
      );
	end component;

	constant CLK_PERIOD  : time := 10 ns;
	constant WAIT_TIME   : integer := 10000;

	signal clk           : std_logic := '0';
	signal rst_l         : std_logic := '1';
	SIGNAL pc_in			: std_logic_vector(9  downto 0) := (others => '0');
   SIGNAL inst_in			: std_logic_vector(31 downto 0) := (others => '0');
   SIGNAL wb_inst			: std_logic_vector(31 downto 0) := (others => '0');
   SIGNAL wb_data			: std_logic_vector(31 downto 0) := (others => '0');	
   SIGNAL br_taken		: std_logic := '0';
   SIGNAL Imm				: std_logic_vector(31 downto 0);	
   SIGNAL pc_out			: std_logic_vector(9  downto 0);
   SIGNAL inst_out		: std_logic_vector(31 downto 0);
   SIGNAL RS1				: std_logic_vector(31 downto 0);	
   SIGNAL RS2				: std_logic_vector(31 downto 0);
   SIGNAL rx_data			: std_logic_vector(31 downto 0) := (others => '0');
   SIGNAL rx_data_empty	: std_logic := '1';
   SIGNAL rx_ack			: std_logic;
begin

   -- Our unit under test
	dut : Decode
		port map (
			-- INPUT
         clk => clk,
         rst_l	=> rst_l,
         pc_in	=> pc_in,
         inst_in => inst_in,
         wb_inst => wb_inst,
         wb_data => wb_data,
         br_taken => br_taken,
         -- OUTPUT
         Imm => Imm,
         pc_out => pc_out,
         inst_out => inst_out,
         RS1 => RS1,
         RS2 => RS2,
         --UART
         rx_data_empty => rx_data_empty,
         rx_data => rx_data,
         rx_ack => rx_ack
		);

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
      wait for CLK_PERIOD * 5;
      wb_inst <= X"CA010000";
      rx_data <= X"0000FFFA";
      rx_data_empty <= '0';
      wait for CLK_PERIOD;
      wb_inst <= X"00000000";
      rx_data <= X"00000000";
      rx_data_empty <= '1';
      wait for CLK_PERIOD;
		wait;
	end process;

end architecture behavioral;
