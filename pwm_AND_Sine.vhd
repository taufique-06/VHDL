library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.ssegPackage.all;

entity PWMWave is
	generic
	(
		TOTAL_POINTS : integer := 360;
		MAX_AMPLITUDE : integer := 255
	);
	port
	(
		button, frequencyButton, dutyCycleButton, switch, waveSwitch, reset, clk : in std_logic;
		sine_out : out integer range 0 to MAX_AMPLITUDE;
		sseg0, sseg1, sseg3, sseg4, sseg5 : out std_logic_vector(7 downto 0);
		led1, led2, led3 : buffer std_logic := '0'
	);
end PWMWave;

architecture behavioural of PWMWave is
	type state_type is (initialState, offState, onState);
	signal state : state_type := initialState;
	type sineState_type is (sineInitialState, sineWaveState);
	signal sineState : sineState_type := sineInitialState;
	signal led2_btn_state : std_logic := '0';
	signal dutyCycle : unsigned(11 downto 0) := x"000";
	signal bcd : std_logic_vector (15 downto 0);
	signal bcd1 : std_logic_vector (15 downto 0);
	signal clk_50 : std_logic;
	signal frequency : unsigned(11 downto 0) := x"001";
	signal led1_btn_state : std_logic := '0';
	signal i : integer range 0 to TOTAL_POINTS := 0;
	type sine_table_type is array (0 to TOTAL_POINTS - 1) of integer range 0 to MAX_AMPLITUDE;
	signal sine_table : sine_table_type := (
		128, 130, 132, 134, 136, 139, 141, 143, 145, 147, 150, 152, 154, 156, 158, 160,
		163, 165, 167, 169, 171, 173, 175, 177, 179, 181, 183, 185, 187, 189, 191, 193,
		195, 197, 199, 201, 202, 204, 206, 208, 209, 211, 213, 214, 216, 218, 219, 221,
		222, 224, 225, 227, 228, 229, 231, 232, 233, 234, 236, 237, 238, 239, 240, 241,
		242, 243, 244, 245, 246, 247, 247, 248, 249, 249, 250, 251, 251, 252, 252, 253,
		253, 253, 254, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
		254, 254, 254, 253, 253, 253, 252, 252, 251, 251, 250, 249, 249, 248, 247, 247,
		246, 245, 244, 243, 242, 241, 240, 239, 238, 237, 236, 234, 233, 232, 231, 229,
		228, 227, 225, 224, 222, 221, 219, 218, 216, 214, 213, 211, 209, 208, 206, 204,
		202, 201, 199, 197, 195, 193, 191, 189, 187, 185, 183, 181, 179, 177, 175, 173,
		171, 169, 167, 165, 163, 160, 158, 156, 154, 152, 150, 147, 145, 143, 141, 139,
		136, 134, 132, 130, 128, 125, 123, 121, 119, 116, 114, 112, 110, 108, 105, 103,
		101, 99, 97, 95, 92, 90, 88, 86, 84, 82, 80, 78, 76, 74, 72, 70,
		68, 66, 64, 62, 60, 58, 56, 54, 53, 51, 49, 47, 46, 44, 42, 41,
		39, 37, 36, 34, 33, 31, 30, 28, 27, 26, 24, 23, 22, 21, 19, 18,
		17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 8, 7, 6, 6, 5, 4,
		4, 3, 3, 2, 2, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 4, 4, 5, 6,
		6, 7, 8, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 21,
		22, 23, 24, 26, 27, 28, 30, 31, 33, 34, 36, 37, 39, 41, 42, 44,
		46, 47, 49, 51, 53, 54, 56, 58, 60, 62, 64, 66, 68, 70, 72, 74,
		76, 78, 80, 82, 84, 86, 88, 90, 92, 95, 97, 99, 101, 103, 105, 108,
		110, 112, 114, 116, 119, 121, 123, 125
	);
	
	component doubleDabble
		port
		(
			clk : in std_logic;
			binaryIn : in unsigned(11 downto 0);
			bcd : out std_logic_vector(15 downto 0)
		);
	end component;
	
begin
	clk_50 <= clk;
	threeDigit : doubleDabble
	port map(clk => clk_50, binaryIn => dutyCycle, bcd => bcd);
	frequencySseg : doubleDabble
	port map(clk => clk_50, binaryIn => frequency, bcd => bcd1);
	sseg0 <= ssegCode(bcd(3 downto 0));
	sseg1 <= ssegCode(bcd(7 downto 4));
	sseg3 <= ssegCode(bcd1(3 downto 0));
	sseg4 <= ssegCode(bcd1(7 downto 4));
	sseg5 <= ssegCode(bcd1(11 downto 8));
	
	set_frequency_and_dutyCycle_process : process (clk, button)
		variable timer : integer := 0;
		variable timer1 : integer := 0;
		variable sth : integer := 0;
		variable dutyCycleValue : integer := 0;
		variable frequencyValue : integer := 1;
		variable onTime, offTime : integer := 0;
		variable clk_frequency : integer := 500000;
		--
		variable clk_50 : integer := 50000000; -- set this to 10
		variable timer2 : integer := 0;
		variable timeAtEachPoint : integer := integer((clk_50) / (360 * frequencyValue));
		
	begin
		if rising_edge(clk) then
			-- Frequency
			if frequencyButton = '0' and switch = '1' then
				if (timer < 12500000) then
					timer := timer + 1;
				else
					if frequencyValue = 1000 then
						frequencyValue := frequencyValue;
						frequency <= to_unsigned(frequencyValue, 12);
						timer := 0;
					elsif (frequencyValue >= 100) then
						frequencyValue := frequencyValue + 50;
						frequency <= to_unsigned(frequencyValue, 12);
						timer := 0;
					elsif (frequencyValue = 1) then
						frequencyValue := frequencyValue + 4;
						frequency <= to_unsigned(frequencyValue, 12);
						timer := 0;
					else
						frequencyValue := frequencyValue + 5;
						frequency <= to_unsigned(frequencyValue, 12);
						timer := 0;
					end if;
				end if;
			elsif frequencyButton = '0' and switch = '0' then
				if (timer < 12500000) then
					timer := timer + 1;
				else
					if frequencyValue = 0 then
						frequencyValue := frequencyValue;
						frequency <= to_unsigned(frequencyValue, 12);
						timer := 0;
					elsif (frequencyValue >= 100) then
						frequencyValue := frequencyValue - 50;
						frequency <= to_unsigned(frequencyValue, 12);
						timer := 0;
					else
						frequencyValue := frequencyValue - 4;
						frequency <= to_unsigned(frequencyValue, 12);
						timer := 0;
					end if;
				end if;
			end if;
			
			--DutyCycle
			if dutyCycleButton = '0' and switch = '1' then
				if (timer < 12500000) then
					timer := timer + 1;
				else
					if dutyCycleValue = 100 then
						dutyCycleValue := dutyCycleValue;
						dutyCycle <= to_unsigned(dutyCycleValue, 12);
						timer := 0;
					else
						dutyCycleValue := dutyCycleValue + 5;
						dutyCycle <= to_unsigned(dutyCycleValue, 12);
						timer := 0;
					end if;
				end if;
			elsif dutyCycleButton = '0' and switch = '0' then
				if (timer < 12500000) then
					timer := timer + 1;
				else
					if dutyCycleValue = 0 then
						dutyCycleValue := dutyCycleValue;
						dutyCycle <= to_unsigned(dutyCycleValue, 12);
						timer := 0;
					else
						dutyCycleValue := dutyCycleValue - 5;
						dutyCycle <= to_unsigned(dutyCycleValue, 12);
						timer := 0;
					end if;
				end if;
			end if;
			
			-- Reset button functionality
			-- if button = '1' then
			-- timer1 := 0; -- Reset the 3-seconds timer when the button is released
			-- else
			-- if timer1 < 150000000 then
			-- timer1 := timer1 + 1;
			-- else
			-- -- Reset the system when the button is held for 3 seconds
			-- dutyCycleValue := 0;
			-- dutyCycle <= to_unsigned(dutyCycleValue,12);
			-- frequencyValue := 1;
			-- frequency <= to_unsigned(frequencyValue,12);
			-- onTime := 0;
			-- offTime := 0;
			-- state <= initialState;
			-- end if;
			-- end if;
			
			if (waveSwitch = '1') then
				case state is
					when initialState =>

						-- led2 <= not led2_btn_state;
						-- led2_btn_state <= not led2_btn_state;
						if (button = '0') then
							if (timer < 12500000) then
								timer := timer + 1;
							else
								onTime := dutyCycleValue * clk_frequency * frequencyValue;
								offTime := (100 - dutyCycleValue) * clk_frequency * frequencyValue;
								state <= onState;

								--setFrequencyAndDutyCycle(frequency,dutyCycleValue);
								led2 <= not led2_btn_state;
								led2_btn_state <= not led2_btn_state;
							end if;

						end if;
					when onState =>
						if (sth < onTime) then
							state <= onState;
							sth := sth + 1;
						else
							-- onTime:= dutyCycleValue * clk_frequency * frequencyValue;
							-- offTime:= (100-dutyCycleValue) * clk_frequency * frequencyValue;
							state <= offState;
							led2 <= not led2_btn_state;
							led2_btn_state <= not led2_btn_state;

							sth := 0;
						end if;
					when offState =>
						if (sth < offTime) then
							state <= offState;
							sth := sth + 1;
						else
							-- onTime:= dutyCycleValue * clk_frequency * frequencyValue;
							-- offTime:= (100-dutyCycleValue) * clk_frequency * frequencyValue;
							state <= onState;
							led2 <= not led2_btn_state;
							led2_btn_state <= not led2_btn_state;
							sth := 0;
						end if;
				end case;
				if (dutyCycleButton = '0' or frequencyButton = '0') and (state = offState or state = onState) then
					if (timer < 12500000) then
						timer := timer + 1;
					else
						onTime := 0;
						offTime := 0;
						state <= initialState;
						led2 <= '0';
						led2_btn_state <= '0';
						timer := 0;
					end if;
				end if;
			else
				case sineState is
					when sineInitialState =>

						if (button = '0') then
							sineState <= sineWaveState;
						end if;
					when sineWaveState =>
						if (timer2 < timeAtEachPoint) then
							sineState <= sineWaveState;
							timer2 := timer2 + 1;
						else
							i <= i + 1;
							sineState <= sineWaveState;
							if (i = TOTAL_POINTS - 1) then
								i <= 0;
							end if;
							timer2 := 0;
						end if;
						led1 <= not led1_btn_state;
						led1_btn_state <= not led1_btn_state;
						sine_out <= sine_table(i);
				end case;
				if (frequencyButton = '0') and (sineState = sineWaveState) then
					if (timer < 12500000) then
						timer := timer + 1;
					else
						timer2 := 0;
						i <= 0;
						sineState <= sineInitialState;
						led1 <= '0';
						led1_btn_state <= '0';
						timer := 0;
					end if;
				end if;
			end if;
		end if;
	end process;
end behavioural;
