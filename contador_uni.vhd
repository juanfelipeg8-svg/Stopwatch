LIBRARY IEEE;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
---------------------------------------10011000100101101000000==5M
---------------------------------------
ENTITY contador_uni IS
	GENERIC ( N			:	INTEGER	:= 28);
	PORT    ( clk     :  IN   STD_LOGIC;
				 rst     :  IN   STD_LOGIC;-----RESETEA EN EL CONTADOR A 0
				 ena     :  IN   STD_LOGIC;
				 syn_clr :  IN   STD_LOGIC;-----RESETEA EN EL CONTADOR A 0 SE PODRIA RESETEAR 
				 ini     :  IN   STD_LOGIC_VECTOR(N-1 DOWNTO 0);
				 up      :  IN   STD_LOGIC;----EN SET CUENTA HACIA ARRIVA
				 max     :  IN   STD_LOGIC_VECTOR(N-1 DOWNTO 0);---NUMERO MAYOR
			    max_tick:  OUT  STD_LOGIC;---SENAL EN 1 CUANDO LLEGUE AL MAX
				 counter :  OUT  STD_LOGIC_VECTOR(N-1 DOWNTO 0));--CONTADOR
END ENTITY;
----------------------------------------				 

ARCHITECTURE  rtl OF contador_uni IS	
	SIGNAL   count_s  	: UNSIGNED(N-1 DOWNTO 0);
	SIGNAL   count_next  : UNSIGNED(N-1 DOWNTO 0);
BEGIN 

		count_next <= 	unsigned(ini) WHEN  ((syn_clr='1') OR (unsigned(max) = count_s))   ELSE
							count_s + 1		WHEN	(ena='1' AND up='1') ELSE 
							count_s - 1		WHEN	(ena='1' AND up='0') ELSE 
							count_s;
						
		PROCESS(clk,rst)
			VARIABLE temp : UNSIGNED(N-1 DOWNTO 0);
		BEGIN 
			IF(rst='1') THEN 
				temp := (OTHERS => '0');
			ELSIF (rising_edge(clk)) THEN 
				IF (ena = '1') THEN 
					temp := count_next;
				END IF;
			END IF;
			counter <= STD_LOGIC_VECTOR(temp);
			count_s <= temp;
		END PROCESS;
	
		max_tick <= '1' WHEN count_s= unsigned(max) ELSE '0';
		
END ARCHITECTURE;