library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--use ieee.NUMERIC_STD.all;

entity projeto is 
	port (entradaSENHA: 	in std_logic_vector(0 to 5);
			chaveE:			in std_logic;
			chaveS: 		in std_logic;
			resetStrikes:	in std_logic;
			ledEstado: 		out std_logic;
			ledErro:		out std_logic;
			numero0:		out std_logic_vector(0 to 6);
			numero1: 	out std_logic_vector(0 to 6);
			senhaOKLED: out std_logic;
			lastA: 	out std_logic_vector(0 to 5);
			keyUpdated: out std_logic);
		   --constant dez: unsigned(3 downto 0) := to_unsigned(1,10);
end projeto;

architecture cofre of projeto is
	signal EnterTrigger, PassOK, IsLoggedIn, SystemLockdown, OnKeyUpdate, SetLogin, ResetLogin, NewKey, WrongPass, NewETrig, NewAttempt, ResetLockdown: std_logic;
	signal senhaAtual: std_logic_vector(0 to 5);
	signal ultimaTent: std_logic_vector(0 to 5);
	--signal teste: integer range 0 to 64; 
	signal bcd0, bcd1: std_logic_vector(3 downto 0);
	signal bcdA: std_logic_vector(0 to 7);
	signal senhaaux: std_logic_vector(0 to 7);
	signal attempts: std_logic_vector(0 to 2);
	signal clearE: std_logic;
	
	
	component bcd
		port (code: in  std_logic_vector(0 to 3);
				leds: out std_logic_vector(0 to 6));
	end component;
	component flipflopd
		port (d, clock, en, r: in std_logic;
				q 		  : out std_logic);
	end component;
	component compare
		port (inp1, inp2: in std_logic_vector(0 to 5);
				res: out std_logic);
	end component;
	component memoryLine
		port (Data: in std_logic_vector(0 to 5);
				Clock, Enable, Reset: in std_logic;
				Qout: out std_logic_vector(0 to 5));
	end component;
begin
	senhaOKLED <= PassOK;
	checkPass: compare port map (entradaSENHA, senhaAtual, PassOK);
	
	NewKey <= not chaveS;
	EnterTrigger <= chaveE and SystemLockdown;
	loggedState: flipflopd port map (SetLogin, OnKeyUpdate, '1', ResetLogin, IsLoggedIn);
	SetLogin <= IsLoggedIn or PassOK;
	ResetLogin <= not EnterTrigger;
	
	guardaSenha: memoryLine port map (entradaSENHA, NewKey, IsLoggedIn, '0', senhaAtual);
	tentaE: flipflopd port map ('1', EnterTrigger, '1', ClearE, NewETrig);
	ClearE <= IsLoggedIn or (not EnterTrigger);
	
	guardaUltimaTentativa: memoryLine port map (entradaSENHA, OnKeyUpdate, '1', '0', ultimaTent);
	checkForNewAttempt: compare port map (entradaSENHA, ultimaTent, NewAttempt);	
		
	OnKeyUpdate <= (not NewAttempt and EnterTrigger) or NewETrig;
	
	WrongPass <= not PassOK;
	strike1: flipflopd port map (  WrongPass, OnKeyUpdate, '1', ResetLockdown, attempts(0));
	strike2: flipflopd port map (attempts(0), OnKeyUpdate, '1', ResetLockdown, attempts(1));
	strike3: flipflopd port map (attempts(1), OnKeyUpdate, '1', ResetLockdown, attempts(2));
	
	SystemLockdown <= not ((attempts(0) and attempts(1)) and attempts(2));
	ResetLockdown <= IsLoggedIn or resetStrikes;
	
	lastA <= ultimaTent;
	keyUpdated <= OnKeyUpdate;
	teste <= while (teste<=entradaSENHA) entradaSENHA - 10;
	--teste <= senha / 10;
	--dezena(0) <= entradaSENHA(4);
	--dezena(1) <= entradaSENHA(5);
	
	process(entradaSENHA, chaveE)
	begin
		bcdA <= ("00" & entradaSENHA);
		senhaaux <= bcdA;
		bcd0 <= "0000";
		bcd1 <= "0000";

	while (bcdA > 9) loop
		bcdA <= senhaaux - 10;
		senhaaux <= bcd1 + 1;
		bcd1 <= senhaaux;
		senhaaux <= bcdA;
		end loop;
		bcd1 <= senhaaux(0 to 3);
		end process;
	--	when "01" => bcd6 <= ("00" & entradaSENHA) + 6;
	--	when "10" => bcd6 <= ("00" & entradaSENHA) + 2;
	--	when "11" => bcd6 <= ("00" & entradaSENHA) + 8;
	--	when "00" => bcd6 <= ("00" & entradaSENHA);
	--	end case;		
	--end process;
	
--	bcd0 <= bcdA(0 to 3);
--	bcd1 <= bcdA(4 to 7);
	
	

		
	num0: bcd port map (bcd0, numero0);
	num1: bcd port map (bcd1, numero1);

	
	
	ledEstado <= IsLoggedIn;
	ledErro <= not SystemLockdown;
end cofre;
