library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.ssegPackage.all;

entity PWMWave is port 
(
	button,frequencyButton,dutyCycleButton,switch, reset,clk : in std_logic;
	sseg0,sseg1,sseg3,sseg4,sseg5				  : out std_logic_vector(7 downto 0);
	led1,led2,led3 : buffer std_logic:='0'
);
end PWMWave;

architecture behavioural of PWMWave is

type state_type is (initialState,offState,onState);
signal state : state_type := initialState;
signal led2_btn_state:std_logic := '1';
signal dutyCycle : unsigned(11 downto 0) := x"000";
signal bcd : std_logic_vector (15 downto 0);
signal bcd1 : std_logic_vector (15 downto 0);
signal clk_50 : std_logic;
signal frequency : unsigned(11 downto 0) := x"001";

component doubleDabble
	port
	(
		clk		 : in std_logic;
		binaryIn	 : in unsigned(11 downto 0);
		bcd		 : out std_logic_vector(15 downto 0)
	);
end component;

--procedure setFrequencyAndDutyCycle(frequencyParameter,dutyCycleParameter:integer) is
--	begin
--		onTime <= dutyCycleParameter * clk_frequency * frequencyParameter;
--		offTime <= integer((100 - dutyCycleParameter) * (frequencyParameter) * (clk_frequency));
--	end procedure setFrequencyAndDutyCycle;	 
begin 

clk_50 <= clk;
threeDigit: doubleDabble port map (clk => clk_50, binaryIn => dutyCycle, bcd => bcd);
frequencySseg : doubleDabble port map (clk => clk_50, binaryIn => frequency, bcd => bcd1);
sseg0 <= ssegCode(bcd(3 downto 0));
sseg1 <= ssegCode(bcd(7 downto 4));
	
sseg3 <= ssegCode(bcd1(3 downto 0));
sseg4 <= ssegCode(bcd1(7 downto 4));
sseg5 <= ssegCode(bcd1(11 downto 8));

set_frequency_and_dutyCycle_process : process(clk,button)

variable timer :integer:= 0;
variable timer1 :integer:= 0;
variable sth :integer:= 0;
variable dutyCycleValue : integer :=0;
variable frequencyValue : integer :=1;
variable onTime, offTime : integer := 0;
variable clk_frequency : integer := 500000;
begin
	  if rising_edge(clk) then
	  
			-- Frequency
			if frequencyButton = '0' AND switch = '1' then
				
				if(timer < 12500000) then
					timer := timer + 1;
				else
				
				if frequencyValue = 1000 then
					  frequencyValue := frequencyValue;
					  frequency <= to_unsigned(frequencyValue,12);
					  timer := 0;
				 elsif (frequencyValue >= 100) then
						frequencyValue := frequencyValue + 50;
					  frequency <= to_unsigned(frequencyValue,12);
					  timer := 0;
				elsif (frequencyValue = 1) then
					  frequencyValue := frequencyValue + 4;
					  frequency <= to_unsigned(frequencyValue,12);
					  timer := 0;
				else
					  frequencyValue := frequencyValue + 5;
					  frequency <= to_unsigned(frequencyValue,12);
					  timer := 0;
				 end if;
				end if;
			elsif frequencyButton = '0' AND switch = '0' then
		
				if(timer < 12500000) then
					timer := timer + 1;
				else
				
				if frequencyValue = 0 then
					  frequencyValue := frequencyValue;
					  frequency <= to_unsigned(frequencyValue,12);
					  timer := 0;
				 elsif (frequencyValue >= 100) then
					  frequencyValue := frequencyValue - 50;
					  frequency <= to_unsigned(frequencyValue,12);
					  timer := 0;
				
				else
					  frequencyValue := frequencyValue - 4;
					  frequency <= to_unsigned(frequencyValue,12);
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
					  dutyCycle <= to_unsigned(dutyCycleValue,12);
					  timer := 0;
				 else
					  dutyCycleValue := dutyCycleValue + 5;
					  dutyCycle <= to_unsigned(dutyCycleValue,12);
					  timer := 0;
				 end if;
				end if;
			elsif dutyCycleButton = '0' AND switch = '0' then
				if(timer < 12500000) then
					timer := timer + 1;
				else
				
				if dutyCycleValue = 0 then
					  dutyCycleValue := dutyCycleValue;
					  dutyCycle <= to_unsigned(dutyCycleValue,12);
					  timer := 0;
				 else
					  dutyCycleValue := dutyCycleValue - 5;
					  dutyCycle <= to_unsigned(dutyCycleValue,12);
					  timer := 0;
				 end if;
				end if;	
			end if;
				
		  -- Reset button functionality
--        if button = '1' then
--            timer1 := 0;  -- Reset the 3-seconds timer when the button is released
--        else
--            if timer1 < 150000000 then  
--                timer1 := timer1 + 1;
--            else
--                -- Reset the system when the button is held for 3 seconds
--                dutyCycleValue := 0;
--					 dutyCycle <= to_unsigned(dutyCycleValue,12);
--                frequencyValue := 1;
--					 frequency <= to_unsigned(frequencyValue,12);
--                onTime := 0;
--                offTime := 0;
--                state <= initialState;
--            end if;
--        end if;
								onTime := dutyCycleValue * clk_frequency * frequencyValue;
						offTime := (100-dutyCycleValue) * clk_frequency * frequencyValue;
						
		case state is 
			when initialState =>		
			
				led2 <= not led2_btn_state;
				led2_btn_state <= not led2_btn_state;
				
				if(button = '0') then

						
						state <=onState;		

						--setFrequencyAndDutyCycle(frequency,dutyCycleValue);
					
						led2 <= not led2_btn_state;
						led2_btn_state <= not led2_btn_state;
						

				end if;
				
			when onState =>
				if(sth < onTime) then
					state <=onState;
					sth := sth + 1;
				else 
					state <= offState;
					led2 <= not led2_btn_state;
					led2_btn_state <= not led2_btn_state;
					

               sth := 0;

				end if;
			
			when offState =>
				if(sth < offTime) then
					state <=offState;					
					sth := sth + 1;
				else 		
					state <= onState;	
					led2 <= not led2_btn_state;
					led2_btn_state <= not led2_btn_state;
				   
					sth := 0;	
				end if;	
		end case;
		
			if (dutyCycleButton = '0' or frequencyButton = '0') and (state = offState or state = onState) then
				
				if(timer < 12500000) then
					timer := timer + 1;
				else
					onTime:= 0;
					offTime:= 0;
					state <= initialState;
					
					timer:= 0;
				end if;
				
			end if;
		
	  end if;
	  
end process;	
end behavioural; 


