--
--  Decrement Counter of WIDTH bit , counts COUNT to 0
--
-- input CLK, EN
--   counts at the positive edge of CLK input,
--   counter is disable and reset to zero while EN = '0'
-- output Q(WIDTH downto 0)


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity COUNTER_DEC is
  generic (
    WIDTH : integer :=4;
    COUNT : integer :=10
  );
  port (
    EN: in std_logic;
    CLK: in std_logic;
    Q: out unsigned(WIDTH-1 downto 0)
  );
end COUNTER_DEC;

architecture RTL of COUNTER_DEC is
	signal Q_INT : integer range 0 to COUNT;

begin

  Process (CLK,EN) begin
		if (EN='0') then
      Q_INT <= COUNT;
		elsif (CLK'event and CLK='1') then
			if (Q_INT = 0) then
				Q_INT <= COUNT;
			else
				Q_INT	<=	Q_INT - 1;
			end if;
		end if;
	end process;

	Q <= to_unsigned(Q_INT, WIDTH);

end RTL;
