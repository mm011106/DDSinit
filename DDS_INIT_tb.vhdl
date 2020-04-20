library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity sim is
end sim;

architecture main of sim is
component main
	port(
		-- inputs
		nRES	: in std_logic;	-- This input MUST be Shumitt mode
		MCLK	: in std_logic;

		--	DDS control
		PSEL, FSEL, RESET, SDATA, SCLK, FSYNC	: out std_logic
										-- Please refer the manual of AD9834(analog devices)
	);
end component;

signal tb_CLK   	: std_logic:='0';
signal tb_nRES  	: std_logic:='0';

signal tb_PSEL, tb_FSEL, tb_RESET, tb_SDATA, tb_SCLK, tb_FSYNC	: std_logic:='0';


-- signal for initiating end of simulation.
signal SIM_END 		: boolean := false;

-- CLK
constant PERIOD_A : time := 50 ns;

-- total period of this simulation
constant PERIOD_B : time := 10 us;

begin
	DUT:main
 		port map(

			MCLK => tb_CLK,
			nRES => tb_nRES,
			PSEL => tb_PSEL,
			FSEL => tb_FSEL,
			RESET => tb_RESET,
			SDATA => tb_SDATA,
			SCLK => tb_SCLK,
			FSYNC => tb_FSYNC
		);

	process
	begin
		wait for PERIOD_A;
		-- Enable counters
		nRES <= '1';

		loop
			wait for PERIOD_A;

			tb_CLK <= not(tb_CLK);

			if (SIM_END) then
				wait;
			end if;
		end loop;

	end process;

-- Controlling the total simulation period of time
	process
	begin
			wait for PERIOD_B;
			SIM_END <= true;
			wait;
	end process;

end main;
