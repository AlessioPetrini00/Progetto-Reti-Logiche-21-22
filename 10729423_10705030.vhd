library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
port (
i_clk : in std_logic;
i_rst : in std_logic;
i_start : in std_logic;
i_data : in std_logic_vector(7 downto 0);
o_address : out std_logic_vector(15 downto 0);
o_done : out std_logic;
o_en : out std_logic;
o_we : out std_logic;
o_data : out std_logic_vector (7 downto 0)
);
end project_reti_logiche;
    
architecture Behavioral of project_reti_logiche is

--Serializer signals
signal load : std_logic;
signal init_1 : std_logic;
signal serial_temp : std_logic_vector (7 downto 0);

--Convolver signals
signal u : std_logic;
signal init_2 : std_logic;
type convolver_state is (S0,
                         S1,
                         S2,
                         S3);
signal convolver_current_state : convolver_state;

--Parallelizer signals
signal p1k : std_logic;
signal p2k : std_logic;
signal paral_temp : std_logic_vector (7 downto 0);

--Number of words left counter signals
signal sel_1 : std_logic;
signal load_1 : std_logic;
signal done : std_logic;
signal reg1_in : std_logic_vector (7 downto 0);
signal reg1_out : std_logic_vector (7 downto 0);

--Input/output address signals
signal sel_2 : std_logic;
signal load_2 : std_logic;
signal sel_3 : std_logic;
signal load_3 : std_logic;
signal sel_4 : std_logic;
signal reg2_in : std_logic_vector (15 downto 0);
signal reg2_out : std_logic_vector (15 downto 0);
signal reg3_in : std_logic_vector (15 downto 0);
signal reg3_out : std_logic_vector (15 downto 0);

--FSM signals
type state is (     START,
                    INITIALIZATION,
                    IDLE_1,
                    NUMBER_OF_WORDS,
                    IDLE_2,
                    IDLE_3,
                    FIRST_BIT,
                    SECOND_BIT,
                    THIRD_BIT,
                    FOURTH_BIT,
                    FIFTH_BIT,
                    SIXTH_BIT,
                    SEVENTH_BIT,
                    EIGHTH_BIT,
                    ENDING);
signal current_state : state;
signal next_state : state;

begin
    --Serializer
    process(i_rst, i_clk, init_1)
    begin
        if i_rst = '1' or init_1 = '1' then
            serial_temp <= "00000000";
        elsif rising_edge(i_clk) then
            if load = '1'then
                u <= i_data(7);
                serial_temp <= i_data(6 downto 0) & '0';
            else
                u <= serial_temp(7);
                serial_temp <= serial_temp(6 downto 0) & '0';
            end if;
        end if;
    end process;
    
    --Convolver    
    process(i_clk, i_rst, init_2)
    begin
        if i_rst = '1' or init_2 = '1' then
            convolver_current_state <= S0;
        elsif rising_edge(i_clk)then
            convolver_current_state <= S0;
            case convolver_current_state is 
                when S0 =>
                    if u = '0' then
                        convolver_current_state <= S0;
                        p1k <= '0';
                        p2k <= '0';
                    elsif u = '1' then 
                        convolver_current_state <= S2;
                        p1k <= '1';
                        p2k <= '1';
                    end if;
                when S1 =>
                    if u = '0' then
                        convolver_current_state <= S0;
                        p1k <= '1';
                        p2k <= '1';                    
                    elsif u = '1' then 
                        convolver_current_state <= S2;
                        p1k <= '0';
                        p2k <= '0';                    
                    end if;
                when S2 =>
                    if u= '0' then
                        convolver_current_state <= S1;
                        p1k <= '0';
                        p2k <= '1';                    
                    elsif u = '1' then
                        convolver_current_state <= S3;
                        p1k <= '1';
                        p2k <= '0';                    
                    end if;
                when S3 =>
                    if u = '0' then
                        convolver_current_state <= S1;
                        p1k <= '1';
                        p2k <= '0';                    
                    elsif u = '1' then 
                        convolver_current_state <= S3;
                        p1k <= '0';
                        p2k <= '1';                    
                    end if;
                end case;
            end if;
    end process;
    
    --Parallelizer
    o_data <= paral_temp;
    
    process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            paral_temp <= "00000000";
        elsif rising_edge(i_clk) then
            paral_temp <= paral_temp(5 downto 0) & p1k & p2k; 
        end if;           
    end process;
    
    --Number of words counter
    process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            reg1_out <= "00000000";
        elsif rising_edge(i_clk) then
            if(load_1 = '1') then
                reg1_out <= reg1_in;
            end if;
        end if;
    end process;
    
    process(reg1_out)
    begin
        if reg1_out = "00000000" then
            done <= '1';
        else 
            done <= '0';
        end if;
    end process;
    
    with sel_1 select
        reg1_in <= i_data when '0',
                    reg1_out - "00000001" when '1',
                    "XXXXXXXX" when others;
                
    --Input/output address
    process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            reg2_out <= "0000000000000000";
        elsif rising_edge(i_clk) then
            if(load_2 = '1') then
                reg2_out <= reg2_in;
            end if;
        end if;
    end process;
    
    process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            reg3_out <= "0000000000000000";
        elsif rising_edge(i_clk) then
            if(load_3 = '1') then
                reg3_out <= reg3_in;
            end if;
        end if;
    end process;   
    
    with sel_2 select
        reg2_in <= "0000001111101000" when '0',
                    reg2_out + "0000000000000001" when '1',
                    "XXXXXXXXXXXXXXXX" when others; 
                    
    with sel_3 select
        reg3_in <= "0000000000000000" when '0',
                   reg3_out + "0000000000000001" when '1',
                   "XXXXXXXXXXXXXXXX" when others;
                   
    with sel_4 select
        o_address <= reg3_out when '0',
                     reg2_out when '1',
                     "XXXXXXXXXXXXXXXX" when others;       
                     
    --FSM
    process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            current_state <= START;
        elsif rising_edge(i_clk) then
            current_state <= next_state;
        end if;
    end process;   
    
    process(current_state, i_start, done)
    begin
        next_state <= current_state;
        case current_state is
            when START =>
                if i_start = '0' then
                    next_state <= START;
                else
                    next_state <= INITIALIZATION;
                end if;
            when INITIALIZATION =>
                next_state <= IDLE_1;
            when IDLE_1 =>
                next_state <= NUMBER_OF_WORDS;
            when NUMBER_OF_WORDS =>
                if done = '0' then
                    next_state <= IDLE_2;
                else
                    next_state <= ENDING;
                end if;
            when IDLE_2 =>
                next_state <= IDLE_3;
            when IDLE_3 =>
                next_state <= FIRST_BIT;
            when FIRST_BIT =>
                next_state <= SECOND_BIT;
            when SECOND_BIT =>
                next_state <= THIRD_BIT;
            when THIRD_BIT =>
                next_state <= FOURTH_BIT;
            when FOURTH_BIT =>
                next_state <= FIFTH_BIT;
            when FIFTH_BIT =>
                next_state <= SIXTH_BIT;
            when SIXTH_BIT =>
                next_state <= SEVENTH_BIT;
            when SEVENTH_BIT =>
                next_state <= EIGHTH_BIT;
            when EIGHTH_BIT =>
                if done = '0' then  
                    next_state <= FIRST_BIT;
                elsif done = '1' then
                    next_state <= ENDING;
                end if;
            when ENDING =>
                if i_start = '1' then
                    next_state <= ENDING;
                elsif i_start = '0' then
                    next_state <= START;
                end if;
       end case;                   
    end process; 
    
    process(current_state)
    begin
        o_done <= '0';
        o_en <= '0';
        o_we <= '0';
        load <= '0';
        sel_1 <= '0';
        load_1 <= '0';
        sel_2 <= '0';
        load_2 <= '0';
        sel_3 <= '0';
        load_3 <= '0';
        load <= '0';
        init_1 <= '0';
        init_2 <= '0';
        sel_4 <= '0';
                
        case current_state is 
            when START =>
                load_2 <= '1';
                load_3 <= '1';
            when INITIALIZATION =>
                o_en <= '1';
                init_1 <= '1';
                init_2 <= '1';
                sel_3 <= '1';
                load_3 <= '1';
            when IDLE_1 =>
                load_1 <= '1';
                o_en <= '1';
            when NUMBER_OF_WORDS =>
                load <= '1';
            when IDLE_2 =>
            when IDLE_3 =>
            when FIRST_BIT =>                
            when SECOND_BIT =>
                sel_3 <= '1';
                load_3 <= '1';
            when THIRD_BIT =>
            when FOURTH_BIT =>
                o_en <= '1';
                o_we <= '1';
                sel_4 <= '1';
                sel_2 <= '1';
                load_2 <= '1';
            when FIFTH_BIT =>
                o_en <= '1';
            when SIXTH_BIT =>
                load <= '1';
            when SEVENTH_BIT =>
                sel_1 <= '1';
                load_1 <= '1';
            when EIGHTH_BIT =>
                o_en <= '1';
                o_we <= '1';
                sel_4 <= '1';
                sel_2 <= '1';
                load_2 <= '1';
            when ENDING =>
                o_done <= '1';
        end case;
    end process;                                            
end Behavioral;