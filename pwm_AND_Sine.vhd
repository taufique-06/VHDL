Library ieee;
Use ieee.std_logic_1164.All;
Use ieee.std_logic_unsigned.All;
Use ieee.numeric_std.All;
Use ieee.math_real.All;
Use work.ssegPackage.All;
Entity PWMWave Is
	Generic
	(
		TOTAL_POINTS : Integer := 360;
		MAX_AMPLITUDE : Integer := 255
	);
	Port
	(
		button, frequencyButton, dutyCycleButton, switch, waveSwitch, reset, clk : In std_logic;
		sine_out : Out Integer Range 0 To MAX_AMPLITUDE;
		sseg0, sseg1, sseg3, sseg4, sseg5 : Out std_logic_vector(7 Downto 0);
		led1, led2, led3 : Buffer std_logic := '0'
	);
End PWMWave;
Architecture behavioural Of PWMWave Is
	Type state_type Is (initialState, offState, onState);
	Signal state : state_type := initialState;
	Type sineState_type Is (sineInitialState, sineWaveState);
	Signal sineState : sineState_type := sineInitialState;
	Signal led2_btn_state : std_logic := '0';
	Signal dutyCycle : unsigned(11 Downto 0) := x"000";
	Signal bcd : std_logic_vector (15 Downto 0);
	Signal bcd1 : std_logic_vector (15 Downto 0);
	Signal clk_50 : std_logic;
	Signal frequency : unsigned(11 Downto 0) := x"001";
	Signal led1_btn_state : std_logic := '0';
	Signal i : Integer Range 0 To TOTAL_POINTS := 0;
	Type sine_table_type Is Array (0 To TOTAL_POINTS - 1) Of Integer Range 0 To MAX_AMPLITUDE;
	Signal sine_table : sine_table_type := (
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
	Component doubleDabble
		Port
		(
			clk : In std_logic;
			binaryIn : In unsigned(11 Downto 0);
			bcd : Out std_logic_vector(15 Downto 0)
		);
	End Component;
	--procedure setFrequencyAndDutyCycle(frequencyParameter,dutyCycleParameter:integer) is
	-- begin
	-- onTime <= dutyCycleParameter * clk_frequency * frequencyParameter;
	-- offTime <= integer((100 - dutyCycleParameter) * (frequencyParameter) * (clk_frequency));
	-- end procedure setFrequencyAndDutyCycle;
Begin
	clk_50 <= clk;
	threeDigit : doubleDabble
	Port Map(clk => clk_50, binaryIn => dutyCycle, bcd => bcd);
	frequencySseg : doubleDabble
	Port Map(clk => clk_50, binaryIn => frequency, bcd => bcd1);
	sseg0 <= ssegCode(bcd(3 Downto 0));
	sseg1 <= ssegCode(bcd(7 Downto 4));
	sseg3 <= ssegCode(bcd1(3 Downto 0));
	sseg4 <= ssegCode(bcd1(7 Downto 4));
	sseg5 <= ssegCode(bcd1(11 Downto 8));
	set_frequency_and_dutyCycle_process : Process (clk, button)
		Variable timer : Integer := 0;
		Variable timer1 : Integer := 0;
		Variable sth : Integer := 0;
		Variable dutyCycleValue : Integer := 0;
		Variable frequencyValue : Integer := 1;
		Variable onTime, offTime : Integer := 0;
		Variable clk_frequency : Integer := 500000;
		--
		Variable clk_50 : Integer := 50000000; -- set this to 10
		Variable timer2 : Integer := 0;
		Variable timeAtEachPoint : Integer := Integer((clk_50) / (360 * frequencyValue));
	Begin
		If rising_edge(clk) Then
			-- Frequency
			If frequencyButton = '0' And switch = '1' Then
				If (timer < 12500000) Then
					timer := timer + 1;
				Else
					If frequencyValue = 1000 Then
						frequencyValue := frequencyValue;
						frequency <= to_unsigned(frequencyValue, 12);
						timer := 0;
					Elsif (frequencyValue >= 100) Then
						frequencyValue := frequencyValue + 50;
						frequency <= to_unsigned(frequencyValue, 12);
						timer := 0;
					Elsif (frequencyValue = 1) Then
						frequencyValue := frequencyValue + 4;
						frequency <= to_unsigned(frequencyValue, 12);
						timer := 0;
					Else
						frequencyValue := frequencyValue + 5;
						frequency <= to_unsigned(frequencyValue, 12);
						timer := 0;
					End If;
				End If;
			Elsif frequencyButton = '0' And switch = '0' Then
				If (timer < 12500000) Then
					timer := timer + 1;
				Else
					If frequencyValue = 0 Then
						frequencyValue := frequencyValue;
						frequency <= to_unsigned(frequencyValue, 12);
						timer := 0;
					Elsif (frequencyValue >= 100) Then
						frequencyValue := frequencyValue - 50;
						frequency <= to_unsigned(frequencyValue, 12);
						timer := 0;
					Else
						frequencyValue := frequencyValue - 4;
						frequency <= to_unsigned(frequencyValue, 12);
						timer := 0;
					End If;
				End If;
			End If;
			--DutyCycle
			If dutyCycleButton = '0' And switch = '1' Then
				If (timer < 12500000) Then
					timer := timer + 1;
				Else
					If dutyCycleValue = 100 Then
						dutyCycleValue := dutyCycleValue;
						dutyCycle <= to_unsigned(dutyCycleValue, 12);
						timer := 0;
					Else
						dutyCycleValue := dutyCycleValue + 5;
						dutyCycle <= to_unsigned(dutyCycleValue, 12);
						timer := 0;
					End If;
				End If;
			Elsif dutyCycleButton = '0' And switch = '0' Then
				If (timer < 12500000) Then
					timer := timer + 1;
				Else
					If dutyCycleValue = 0 Then
						dutyCycleValue := dutyCycleValue;
						dutyCycle <= to_unsigned(dutyCycleValue, 12);
						timer := 0;
					Else
						dutyCycleValue := dutyCycleValue - 5;
						dutyCycle <= to_unsigned(dutyCycleValue, 12);
						timer := 0;
					End If;
				End If;
			End If;
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
			If (waveSwitch = '1') Then
				Case state Is
					When initialState =>

						-- led2 <= not led2_btn_state;
						-- led2_btn_state <= not led2_btn_state;
						If (button = '0') Then
							If (timer < 12500000) Then
								timer := timer + 1;
							Else
								onTime := dutyCycleValue * clk_frequency * frequencyValue;
								offTime := (100 - dutyCycleValue) * clk_frequency * frequencyValue;
								state <= onState;

								--setFrequencyAndDutyCycle(frequency,dutyCycleValue);
								led2 <= Not led2_btn_state;
								led2_btn_state <= Not led2_btn_state;
							End If;

						End If;
					When onState =>
						If (sth < onTime) Then
							state <= onState;
							sth := sth + 1;
						Else
							-- onTime:= dutyCycleValue * clk_frequency * frequencyValue;
							-- offTime:= (100-dutyCycleValue) * clk_frequency * frequencyValue;
							state <= offState;
							led2 <= Not led2_btn_state;
							led2_btn_state <= Not led2_btn_state;

							sth := 0;
						End If;
					When offState =>
						If (sth < offTime) Then
							state <= offState;
							sth := sth + 1;
						Else
							-- onTime:= dutyCycleValue * clk_frequency * frequencyValue;
							-- offTime:= (100-dutyCycleValue) * clk_frequency * frequencyValue;
							state <= onState;
							led2 <= Not led2_btn_state;
							led2_btn_state <= Not led2_btn_state;
							sth := 0;
						End If;
				End Case;
				If (dutyCycleButton = '0' Or frequencyButton = '0') And (state = offState Or state = onState) Then
					If (timer < 12500000) Then
						timer := timer + 1;
					Else
						onTime := 0;
						offTime := 0;
						state <= initialState;
						led2 <= '0';
						led2_btn_state <= '0';
						timer := 0;
					End If;
				End If;
			Else
				Case sineState Is
					When sineInitialState =>

						If (button = '0') Then
							sineState <= sineWaveState;
						End If;
					When sineWaveState =>
						If (timer2 < timeAtEachPoint) Then
							sineState <= sineWaveState;
							timer2 := timer2 + 1;
						Else
							i <= i + 1;
							sineState <= sineWaveState;
							If (i = TOTAL_POINTS - 1) Then
								i <= 0;
							End If;
							timer2 := 0;
						End If;
						led1 <= Not led1_btn_state;
						led1_btn_state <= Not led1_btn_state;
						sine_out <= sine_table(i);
				End Case;
				If (frequencyButton = '0') And (sineState = sineWaveState) Then
					If (timer < 12500000) Then
						timer := timer + 1;
					Else
						timer2 := 0;
						i <= 0;
						sineState <= sineInitialState;
						led1 <= '0';
						led1_btn_state <= '0';
						timer := 0;
					End If;
				End If;
			End If;
		End If;
	End Process;
End behavioural;
