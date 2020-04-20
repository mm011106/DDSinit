-- DDS initialize module (SPI function)
--
--		Sited from SPITEST:
-- 		Develop 2.0 2015/02/04 Miyamoto
--
--		Combine with ER50_WALZER
--			REV 1.0	2015/02/06 Miyamoto
--
-- 		Revised : エンティティを使ってカウンターを外部ユニットとして一般化


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity DDS_INIT is
		generic ( N	:	integer	:= 4); -- word length 2**N e.g. 16bit incase of N=4
		port	(
					-- inputs
					nRES	: in std_logic;	-- This input MUST be Shumitt mode
					MCLK	: in std_logic;

					--	DDS control
					PSEL, FSEL, RESET, SDATA, SCLK, FSYNC	: out std_logic
													-- Please refer the manual of AD9834(analog devices)

			);
end DDS_INIT;


architecture Behavioral of DDS_INIT is

--  internal signal
signal 	Q_DIV:		std_logic_vector(9	downto 0);		-- prescaler for MCLK

signal	Q_SEQ:		std_logic_vector(N+1 downto 0);		-- Sequience counter
signal 	ADD_COUNT:	std_logic_vector(1 downto 0);			-- Address counter for COMMAND words
signal	S_REG:		std_logic_vector(2**N-1 downto 0);	-- Output Register

signal	SYNC:			std_logic;	-- Sync signal (internal)
signal	INT_CLK:		std_logic;	-- Scaled CLK
signal	CLK_EN:		std_logic;



subtype WORD is std_logic_vector(2**N-1 downto 0);
type MEMORY is array (0 to 3) of WORD;
--constant COMMAND : MEMORY := (
--	"0010000000100000", "0100000000101100", "0100000000000000", "0000000000000000");  -- 11Hz

constant COMMAND : MEMORY := (
	"0010000000100000", "0100000101000000", "0100000000000000", "0000000000000000");  -- 80HZ

begin

	--	ADD_COUNT behavior:
	--		Be set 00 on RES
	-- 	Increase at the falling edge of the SYNC
	ADDRESS_COUNTER: entity work.COUNTER_INC
		generic map (WIDTH => 2, COUNT => 2)
		port map    (EN => nRES, CLK => SYNC, Q => ADD_COUNT);


	PRESCALER: entity work.COUNTER_INC
			generic map (WIDTH => 10, COUNT => 2**10-1)
			port map    (EN => nRES, CLK => MCLK, Q => Q_DIV);
-- Internal CLK <= 1/2^6 MCLK (1MHz <- 67MHz)
	INT_CLK	<= Q_DIV(6) and CLK_EN;	-- CLK input for the sequencer

	SEQUENCE_COUNTER: entity work.COUNTER_DEC
		generic map (WIDTH => 6, COUNT => 33)
		port map (EN=> nRES, CLK=> INT_CLK, Q => Q_SEQ);


	-- Q_SEQ is the counter for all over sequience, 34th counter.

   -- MSB of Q_SEQ is used for setup the SYNC signal 		Q_SEQ(5)
   -- LSB is used for the SCLK 									Q_SEQ(0)
   -- Middle of 4 bits are used as the index for a bit
	--		to be send out in S_REG	 								Q_SEQ(4 downto 1)

	-- Process (INT_CLK,nRES) begin
	-- 	if (nRES='0') then
	-- 		Q_SEQ	<=	"100001";
	-- 	elsif (INT_CLK'event and INT_CLK='1') then
	-- 		if (Q_SEQ="000000") then						-- 34th counter : 2x(word length+SYNC pulse)
	-- 			Q_SEQ	<= "100001";
	-- 		else
	-- 			Q_SEQ	<=	Q_SEQ-'1';
	-- 		end if;
	-- 	end if;
	-- end process;

	SYNC	<=	Q_SEQ(5);
	SCLK	<=	Q_SEQ(0);

	--	S_REG behavior:
	--		Async load on RES
	--		Sync load on the rising edge of the SYNC
	--    Always S_REG(INDEX) is appeared on the SDATA

	SDATA	<=	S_REG(conv_integer(Q_SEQ(4 downto 1)));

	process (SYNC, nRES) begin
		if (nRES='0') then
			S_REG	<=	COMMAND(conv_integer(ADD_COUNT));
				-- set the first command at the time of RESET mode.

		elsif (SYNC'event and SYNC='1') then
			S_REG	<=	COMMAND(conv_integer(ADD_COUNT));
				-- load the command at the rising edge of the SYNC

		end if;
	end process;


	--	SYNC comparator for CKL_EN
	--		CLK_EN is set to '1' when RES state
	--		CLK_EN is changed based on the value of ADD_COUNT at the rising edge of the SYNC

	process (SYNC, nRES) begin
		if (nRES='0') then
			CLK_EN	<=	'1';
				-- enable CLK of the sequencer

		elsif (SYNC'event and SYNC='1') then
			if (ADD_COUNT=3) then
				CLK_EN	<=	'0';
			else
				CLK_EN	<=	'1';
			end if;
				-- disable CLK of the sequencer when all the command (3words) were sent.

		end if;
	end process;


	--	ADD_COUNT behavior:
	--		Be set 00 on RES
	-- 	Increase at the falling edge of the SYNC

	-- process(SYNC, nRES) begin
	-- 	if (nRES='0') then
	-- 		ADD_COUNT	<=	(others=>'0');
	-- 	elsif (SYNC'event and SYNC='0') then
	-- 		ADD_COUNT	<= ADD_COUNT+1;
	-- 	end if;
	-- end process;


--	Output signals
--
	FSYNC	<=	SYNC or not(CLK_EN);

	PSEL	<= '0';
	FSEL	<=	'0';

	RESET	<=	not(nRES);



end Behavioral;
