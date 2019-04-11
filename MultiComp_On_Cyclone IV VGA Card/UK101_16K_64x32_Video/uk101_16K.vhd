-- Implements Grant Searle's modifications for 64x32 screens as described here:
-- http://searle.hostei.com/grant/uk101FPGA/index.html#Modification3

library ieee;
use ieee.std_logic_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

entity uk101_16K is
	port(
		n_reset		: in std_logic;
		clk			: in std_logic;
		rxd			: in std_logic;
		txd			: out std_logic;
		rts			: out std_logic;
		videoR0		: out std_logic;
		videoR1		: out std_logic;
		videoR2		: out std_logic;
		videoR3		: out std_logic;
		videoR4		: out std_logic;
		videoG0		: out std_logic;
		videoG1		: out std_logic;
		videoG2		: out std_logic;
		videoG3		: out std_logic;
		videoG4		: out std_logic;
		videoG5		: out std_logic;
		videoB0		: out std_logic;
		videoB1		: out std_logic;
		videoB2		: out std_logic;
		videoB3		: out std_logic;
		videoB4		: out std_logic;
		hSync		: out std_logic;
		vSync		: out std_logic;
		ps2Clk		: in std_logic;
		ps2Data		: in std_logic
	);
end uk101_16K;

architecture struct of uk101_16K is

	signal n_WR				: std_logic;
	signal cpuAddress		: std_logic_vector(15 downto 0);
	signal cpuDataOut		: std_logic_vector(7 downto 0);
	signal cpuDataIn		: std_logic_vector(7 downto 0);

	signal basRomData		: std_logic_vector(7 downto 0);
	signal ramDataOut		: std_logic_vector(7 downto 0);
	signal ramDataOut2	: std_logic_vector(7 downto 0);
	signal monitorRomData : std_logic_vector(7 downto 0);
	signal aciaData		: std_logic_vector(7 downto 0);

	signal n_memWR			: std_logic;
	
	signal n_dispRamCS	: std_logic;
	signal n_ramCS			: std_logic;
	signal n_basRomCS		: std_logic;
	signal n_monitorRomCS : std_logic;
	signal n_aciaCS		: std_logic;
	signal n_kbCS			: std_logic;
	
	signal dispAddrB 		: std_logic_vector(10 downto 0);
	signal dispRamDataOutA : std_logic_vector(7 downto 0);
	signal dispRamDataOutB : std_logic_vector(7 downto 0);
	signal charAddr 		: std_logic_vector(10 downto 0);
	signal charData 		: std_logic_vector(7 downto 0);

	signal serialClkCount: std_logic_vector(14 downto 0); 
	signal cpuClkCount	: std_logic_vector(5 downto 0); 
	signal cpuClock		: std_logic;
	signal serialClock	: std_logic;
	signal videoOut		: std_logic;

	signal kbReadData 	: std_logic_vector(7 downto 0);
	signal kbRowSel 		: std_logic_vector(7 downto 0);

begin
	-- ____________________________________________________________________________________
	-- Card has 16 bits of RGB digital data
	-- Drive the least significant bits with 0's since Multi-Comp only has 6 bits of RGB digital data
	-- Drive a blue background with white text
	videoR0 <= '0';
	videoR1 <= '0';
	videoR2 <= '0';
	videoG0 <= '0';
	videoG1 <= '0';
	videoG2 <= '0';
	videoG3 <= '0'; 
	videoB0 <= '1';
	videoB1 <= '1';
	videoB2 <= '1';
	videoB3 <= '1';
	videoB4 <= '1';
	videoR3 <= videoOut;
	videoR4 <= videoOut;
	videoG4 <= videoOut;
	videoG5 <= videoOut;

	n_memWR <= not(cpuClock) nand (not n_WR);

	n_dispRamCS <= '0' when cpuAddress(15 downto 11) = "11010" else '1';
	n_basRomCS <= '0' when cpuAddress(15 downto 13) = "101" else '1'; --8k
	n_monitorRomCS <= '0' when cpuAddress(15 downto 11) = "11111" else '1'; --2K
	n_ramCS <= '0' when cpuAddress(15 downto 14)="00" else '1';
	n_aciaCS <= '0' when cpuAddress(15 downto 1) = "111100000000000" else '1';
	n_kbCS <= '0' when cpuAddress(15 downto 10) = "110111" else '1';
 
	cpuDataIn <=
   -- CEGMON PATCH FOR 64x32 SCREEN
--     x"3F" when cpuAddress = x"FBBC" else -- CEGMON SWIDTH (was $47)
--    x"00" when cpuAddress = x"FBBD" else -- CEGMON TOP L (was $0C (1st line) or $8C (3rd line))
--    x"BF" when cpuAddress = x"FBBF" else -- CEGMON BASE L (was $CC)
--    x"D7" when cpuAddress = x"FBC0" else -- CEGMON BASE H (was $D3)
--    x"00" when cpuAddress = x"FBC2" else -- CEGMON STARTUP TOP L (was $0C (1st line) or $8C (3rd line))
--    x"00" when cpuAddress = x"FBC5" else -- CEGMON STARTUP TOP L (was $0C (1st line) or $8C (3rd line))
--    x"00" when cpuAddress = x"FBCB" else -- CEGMON STARTUP TOP L (was $0C (1st line) or $8C (3rd line))
--    x"10" when cpuAddress = x"FE62" else -- CEGMON CLR SCREEN SIZE (was $08)
--    x"D8" when cpuAddress = x"FB8B" else -- CEGMON SCREEN BOTTOM H (was $D4) - Part of CTRL-F code
--    x"D7" when cpuAddress = x"FE3B" else -- CEGMON SCREEN BOTTOM H - 1 (was $D3) - Part of CTRL-A code
   x"3F" when cpuAddress = x"FBBC" else -- CEGMON SWIDTH (was $47)
    x"00" when cpuAddress = x"FBBD" else -- CEGMON TOP L (was $0C (1st line) or $8C (3rd line))
    x"BF" when cpuAddress = x"FBBF" else -- CEGMON BASE L (was $CC)
    x"D7" when cpuAddress = x"FBC0" else -- CEGMON BASE H (was $D3)
    x"00" when cpuAddress = x"FBC2" else -- CEGMON STARTUP TOP L (was $0C (1st line) or $8C (3rd line))
    x"00" when cpuAddress = x"FBC5" else -- CEGMON STARTUP TOP L (was $0C (1st line) or $8C (3rd line))
    x"00" when cpuAddress = x"FBCB" else -- CEGMON STARTUP TOP L (was $0C (1st line) or $8C (3rd line))
    x"10" when cpuAddress = x"FE62" else -- CEGMON CLR SCREEN SIZE (was $08)
    x"D8" when cpuAddress = x"FB8B" else -- CEGMON SCREEN BOTTOM H (was $D4) - Part of CTRL-F code
    x"D7" when cpuAddress = x"FE3B" else -- CEGMON SCREEN BOTTOM H - 1 (was $D3) - Part of CTRL-A code
		basRomData when n_basRomCS = '0' else
		monitorRomData when n_monitorRomCS = '0' else
		aciaData when n_aciaCS = '0' else
		ramDataOut when n_ramCS = '0' else
		-- ramDataOut2 when n_ramCS2 = '0' else
		dispRamDataOutA when n_dispRamCS = '0' else
		kbReadData when n_kbCS='0'
		else x"FF";
		
	u1 : entity work.T65
	port map(
		Enable => '1',
		Mode => "00",
		Res_n => n_reset,
		Clk => cpuClock,
		Rdy => '1',
		Abort_n => '1',
		IRQ_n => '1',
		NMI_n => '1',
		SO_n => '1',
		R_W_n => n_WR,
		A(15 downto 0) => cpuAddress,
		DI => cpuDataIn,
		DO => cpuDataOut);
			

	u2 : entity work.BasicRom -- 8KB
	port map(
		address => cpuAddress(12 downto 0),
		clock => clk,
		q => basRomData
	);

	u3: entity work.ProgRam 
	port map
	(
		address => cpuAddress(13 downto 0),
		clock => clk,
		data => cpuDataOut,
		wren => not(n_memWR or n_ramCS),
		q => ramDataOut
	);
	
	u4: entity work.CegmonRom
	port map
	(
		address => cpuAddress(10 downto 0),
		q => monitorRomData
	);

	u5: entity work.bufferedUART
	port map(
		n_wr => n_aciaCS or cpuClock or n_WR,
		n_rd => n_aciaCS or cpuClock or (not n_WR),
		regSel => cpuAddress(0),
		dataIn => cpuDataOut,
		dataOut => aciaData,
		rxClock => serialClock,
		txClock => serialClock,
		rxd => rxd,
		txd => txd,
		n_cts => '0',
		n_dcd => '0',
		n_rts => rts
	);

	process (clk)
	begin
		if rising_edge(clk) then
			if cpuClkCount < 50 then
				cpuClkCount <= cpuClkCount + 1;
			else
				cpuClkCount <= (others=>'0');
			end if;
			if cpuClkCount < 25 then
				cpuClock <= '0';
			else
				cpuClock <= '1';
			end if;	
			
			if serialClkCount < 325 then -- 9600 baud
				serialClkCount <= serialClkCount + 1;
			else
				serialClkCount <= (others => '0');
			end if;
			if serialClkCount < 162 then -- 9600 baud
				serialClock <= '0';
			else
				serialClock <= '1';
			end if;	
		end if;
	end process;

	u6 : entity work.UK101TextDisplay
	port map (
		charAddr => charAddr,
		charData => charData,
		dispAddr => dispAddrB,
		dispData => dispRamDataOutB,
		clk => clk,
		vSync => vSync,
		hSync => hSync,
		video => videoOut
	);

	u7: entity work.CharRom
	port map
	(
		address => charAddr,
		q => charData
	);

	u8: entity work.DisplayRam 
	port map
	(
		address_a => cpuAddress(10 downto 0),
		address_b => dispAddrB,
		clock	=> clk,
		data_a => cpuDataOut,
		data_b => (others => '0'),
		wren_a => not(n_memWR or n_dispRamCS),
		wren_b => '0',
		q_a => dispRamDataOutA,
		q_b => dispRamDataOutB
	);
	
	u9 : entity work.UK101keyboard
	port map(
		CLK => clk,
		nRESET => n_reset,
		PS2_CLK	=> ps2Clk,
		PS2_DATA	=> ps2Data,
		A	=> kbRowSel,
		KEYB	=> kbReadData
	);
	
	process (n_kbCS,n_memWR)
	begin
		if	n_kbCS='0' and n_memWR = '0' then
			kbRowSel <= cpuDataOut;
		end if;
	end process;
	
end;
