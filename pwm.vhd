library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity PWM is port 
(
	button,frequencyButton,dutyCycleButton,switch, reset,clk : in std_logic;
	sseg0,sseg1,sseg3,sseg4				  : out std_logic_vector(7 downto 0);
	led1,led2,led3 : buffer std_logic:='0'
);
end PWM;

architecture behavioural of PWM is

type state_type is (initialState,offState,onState);
signal state : state_type;
signal led1_btn_state,led3_btn_state: std_logic:='0';
signal led2_btn_state:std_logic := '1';
signal dutyCycle : integer := 0;
signal clk_frequency : integer := 500000;
signal frequency: integer := 1;

--procedure setFrequencyAndDutyCycle(frequencyParameter,dutyCycleParameter:integer) is
--	begin
--		onTime <= dutyCycleParameter * clk_frequency * frequencyParameter;
--		offTime <= integer((100 - dutyCycleParameter) * (frequencyParameter) * (clk_frequency));
--	end procedure setFrequencyAndDutyCycle;	 
begin 

set_frequency_and_dutyCycle_process : process(clk,dutyCycleButton,button,frequencyButton)

variable timer :integer:= 0;
variable timer1 :integer:= 0;
variable dutyCycleValue,onTime,offTime : integer :=0;
variable frequencyValue : integer :=1;
begin
	  if rising_edge(clk) then
			-- Frequency
			
			if frequencyButton = '0' AND switch = '1' then
				
				if(timer < 12500000) then
					timer := timer + 1;
				else
				
				if frequencyValue = 1000 then
					  frequencyValue := frequencyValue;
					  frequency <= frequencyValue;
					  timer := 0;
				 elsif (frequencyValue >= 100) then
					  frequencyValue := frequencyValue + 50;
					  frequency <= frequencyValue;
					  timer := 0;
				elsif (frequencyValue = 1) then
					  frequencyValue := frequencyValue + 4;
					  frequency <= frequencyValue;
					  timer := 0;
				else
					  frequencyValue := frequencyValue + 5;
					  frequency <= frequencyValue;
					  timer := 0;
				 end if;
				end if;
			elsif frequencyButton = '0' AND switch = '0' then
		
				if(timer < 12500000) then
					timer := timer + 1;
				else
				
				if frequencyValue = 0 then
					  frequencyValue := frequencyValue;
					  frequency <= frequencyValue;
					  timer := 0;
				 elsif (frequencyValue >= 100) then
					  frequencyValue := frequencyValue - 50;
					  frequency <= frequencyValue;
					  timer := 0;
				
				else
					  frequencyValue := frequencyValue - 5;
					  frequency <= frequencyValue;
					  timer := 0;
				 end if;
				end if;	
			end if;


			--DutyCycle
			if dutyCycleButton = '0' AND switch = '1' then
				if(timer < 12500000) then
					timer := timer + 1;
				else
				
				if dutyCycleValue = 100 then
					  dutyCycleValue := dutyCycleValue;
					  dutyCycle <= dutyCycleValue;
					  timer := 0;
				 else
					  dutyCycleValue := dutyCycleValue + 5;
					  dutyCycle <= dutyCycleValue;
					  timer := 0;
				 end if;
				end if;
			elsif dutyCycleButton = '0' AND switch = '0' then
				if(timer < 12500000) then
					timer := timer + 1;
				else
				
				if dutyCycleValue = 0 then
					  dutyCycleValue := dutyCycleValue;
					  dutyCycle <= dutyCycleValue;
					  timer := 0;
				 else
					  dutyCycleValue := dutyCycleValue - 5;
					  dutyCycle <= dutyCycleValue;
					  timer := 0;
				 end if;
				end if;
			
			end if;
			
		        -- Reset button functionality
        if button = '1' then
            timer1 := 0;  -- Reset the 3-seconds timer when the button is released
        else
            if timer1 < 150000000 then  
                timer1 := timer1 + 1;
            else
                -- Reset the system when the button is held for 3 seconds
                dutyCycleValue := 0;
					 dutyCycle <= dutyCycleValue;
                frequencyValue := 1;
					 frequency <= frequencyValue;
                onTime := 0;
                offTime := 0;
                state <= initialState;
            end if;
        end if;
		  
		case state is 
			when initialState =>
				led1 <= not led1_btn_state;
				led1_btn_state <= not led1_btn_state;
				
				led2 <= not led2_btn_state;
				led2_btn_state <= not led2_btn_state;
						
				if(button = '0') then
				
				onTime := dutyCycleValue * clk_frequency * frequency;
				offTime := (100 - dutyCycleValue) * frequency * clk_frequency;
				
					state <=onState;

					--setFrequencyAndDutyCycle(frequency,dutyCycleValue);

	  
					led2 <= not led2_btn_state;
					led2_btn_state <= not led2_btn_state;
				end if;
				
			when onState =>
		
				if(timer < onTime) then
					state <=onState;
					timer := timer + 1;
				else 
					state <=offState;
					
					led2 <= not led2_btn_state;
					led2_btn_state <= not led2_btn_state;
					
					timer := 0;
				end if;
			
			when offState =>
		
				if(timer < offTime) then
					state <=offState;
					timer := timer + 1;
				else 
					state <=onState;
					
					led2 <= not led2_btn_state;
					led2_btn_state <= not led2_btn_state;
					
					timer := 0;
				end if;
				
		end case;
		   if (dutyCycleButton = '0' or frequencyButton = '0') and (state = offState or state = onState) then
            state <= initialState;
        end if;
	  end if;
	  
end process;

	display:process(dutyCycle)
	begin
	case dutyCycle is
		when 0 =>
			sseg0 <= "11000000";
			sseg1 <= "11000000";
		when 5 =>
			sseg1 <= "11000000";
			sseg0 <= "10010010";
		when 10 =>
			sseg1 <= "11111001";
			sseg0 <= "11000000";
		when 15 =>
			sseg1 <= "11111001";
			sseg0 <= "10010010";
		when 20 =>
			sseg1 <= "10100100";
			sseg0 <= "11000000";
		when 25 =>
			sseg1 <= "10100100";
			sseg0 <= "10010010";
		when 30 =>
			sseg1 <= "10110000";
			sseg0 <= "11000000";
		when 35 =>
			sseg1 <= "10110000";
			sseg0 <= "10010010";
		when 40 =>
			sseg1 <= "10011001";
			sseg0 <= "11000000";
		when 45 =>
			sseg1 <= "10011001";
			sseg0 <= "10010010";
		when 50 =>
			sseg1 <= "10010010";
			sseg0 <= "11000000";
		when 55 =>
			sseg1 <= "10010010";
			sseg0 <= "10010010";
		when 60 =>
			sseg1 <= "10000010";
			sseg0 <= "11000000";
		when 65 =>
			sseg1 <= "10000010";
			sseg0 <= "10010010";
		when 70 =>
			sseg1 <= "11111000";
			sseg0 <= "11000000";
		when 75 =>
			sseg1 <= "11111000";
			sseg0 <= "10010010";
		when 80 =>
			sseg1 <= "10000000";
			sseg0 <= "11000000";
		when 85 =>
			sseg1 <= "10000000";
			sseg0 <= "10010010";
		when 90 =>
			sseg1 <= "10010000";
			sseg0 <= "11000000";
		when 95 =>
			sseg1 <= "10010000";
			sseg0 <= "10010010";
		when 100 =>
			sseg1 <= "11000000";
			sseg0 <= "11000000";
		when others =>
			sseg0 <= "11111111";
			sseg1 <= "11111111";
	end case;
	end process;

displayFrequency:process(frequency)
	begin
	case frequency is
		when 1 =>
			sseg3 <= "11000000";
			sseg4 <= "11000000";
		when 5 =>
			sseg3 <= "11000000";
			sseg4 <= "10010010";
		when 10 =>
			sseg3 <= "11111001";
			sseg4 <= "11000000";
		when 15 =>
			sseg3 <= "11111001";
			sseg4 <= "10010010";
		when 20 =>
			sseg3 <= "10100100";
			sseg4 <= "11000000";
		when 25 =>
			sseg3 <= "10100100";
			sseg4 <= "10010010";
		when 30 =>
			sseg3 <= "10110000";
			sseg4 <= "11000000";
		when 35 =>
			sseg3 <= "10110000";
			sseg4 <= "10010010";
		when 40 =>
			sseg3 <= "10011001";
			sseg4 <= "11000000";
		when 45 =>
			sseg3 <= "10011001";
			sseg4 <= "10010010";
		when 50 =>
			sseg3 <= "10010010";
			sseg4 <= "11000000";
		when 55 =>
			sseg3 <= "10010010";
			sseg4 <= "10010010";
		when 60 =>
			sseg3 <= "10000010";
			sseg4 <= "11000000";
		when 65 =>
			sseg3 <= "10000010";
			sseg4 <= "10010010";
		when 70 =>
			sseg3 <= "11111000";
			sseg4 <= "11000000";
		when 75 =>
			sseg3 <= "11111000";
			sseg4 <= "10010010";
		when 80 =>
			sseg3 <= "10000000";
			sseg4 <= "11000000";
		when 85 =>
			sseg3 <= "10000000";
			sseg4 <= "10010010";
		when 90 =>
			sseg3 <= "10010000";
			sseg4 <= "11000000";
		when 95 =>
			sseg3 <= "10010000";
			sseg4 <= "10010010";
		when 100 =>
			sseg3 <= "11000000";
			sseg4 <= "11000000";
		when others =>
			sseg3 <= "11111111";
			sseg4 <= "11111111";
	end case;
	end process;
	
end behavioural; 
