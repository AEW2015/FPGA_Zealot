----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/29/2020 07:45:40 PM
-- Design Name: 
-- Module Name: operator - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.bus_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity operator is
    Port ( clk : in STD_LOGIC;
           valid_in  : in  STD_LOGIC;
           valid_out : out STD_LOGIC;           
           new_frame        :  in STD_LOGIC; --user bit
           eol              :  in STD_LOGIC; -- last bit
           new_frame_out    : out STD_LOGIC; --user bit
           eol_out          : out STD_LOGIC; -- last bit
           shift_value : in STD_LOGIC_VECTOR(3 downto 0);
           upper_limit : in STD_LOGIC_VECTOR(7 downto 0);
           lower_limit : in STD_LOGIC_VECTOR(7 downto 0);
           window : in t_window := (others=>(others=>'0'));
           coef : in t_coef  := (others=>(others=>'0'));
           output : out STD_LOGIC_VECTOR(7 downto 0)
    );
end operator;

architecture Behavioral of operator is

-----------------------------------------------
function log2c (n: integer) return integer is 
variable m, p: integer; 
begin 
m := 0; 
p := 1; 
while p < n loop 
m := m + 1; 
p := p * 2; 
end loop; 
return m; 
end log2c;
---------------------------------------------------

constant SUM_DEPTH : Natural := log2c(kernel_size*kernel_size);

type t_sum is array(0 to (2**SUM_DEPTH)-1) of signed(15 downto 0);
type t_sum_array is array (0 to SUM_DEPTH) of t_sum;
        

signal window_reg  : t_window_array := (others=>(others=>(others=>'0')));
signal window_com  : t_window_array := (others=>(others=>(others=>'0')));
signal coef_sign   : t_sign_array   := (others=>(others=>'0'));
signal coef_value  : t_value_array  := (others=>(others=>(others=>'0')));
signal sum_tree    : t_sum_array    := (others=>(others=>(others=>'0')));


signal summation   : std_logic_vector (15 downto 0);
signal shift_8     : signed (15 downto 0);
signal shift_4     : signed (15 downto 0);
signal shift_2     : signed (15 downto 0);
signal shift_1     : signed (15 downto 0);
signal ulimited     : signed (7 downto 0);
signal llimited     : signed (7 downto 0);

signal valid_sr   : std_logic_vector ((16 + SUM_DEPTH) downto 0);
signal frs_sr   : std_logic_vector ((16 + SUM_DEPTH) downto 0);
signal eol_sr   : std_logic_vector ((16 + SUM_DEPTH) downto 0);

begin

---------------------------------------------------------------------------------------------
--   STAGE 1 
---------------------------------------------------------------------------------------------

process (clk)
begin
    if rising_edge(clk) then
        for I in 0 to kernel_array_size loop
            --stage 1
            window_reg(0)(I)(7 downto 0) <= window(I);
            coef_sign(0)(I) <= coef(I)(7);
            coef_value(0)(I) <= std_logic_vector(abs(signed(coef(I))));        
        
            --stage 2
            window_reg(1)(I) <= window_reg(0)(I);
            coef_sign(1)(I) <= coef_sign(0)(I);
            coef_value(1)(I) <= coef_value(0)(I);                       
            if (coef_value(0)(I)(0) = '1') then
                window_com(0)(I) <= window_reg(0)(I); 
                else
                window_com(0)(I) <= (others=>'0');
            end if;
        
             --stage 3 to N
             for J in 0 to 6 loop
            window_reg(J+2)(I) <= window_reg(J+1)(I);
            coef_sign(J+2)(I) <= coef_sign(J+1)(I);
            coef_value(J+2)(I) <= coef_value(J+1)(I);                       
            if (coef_value(J+1)(I)(J+1) = '1') then
                window_com(J+1)(I) <=  std_logic_vector(unsigned(window_com(J)(I)) + (unsigned(window_reg(J+1)(I)((14-J) downto 0))&to_unsigned(0,J+1)));
                else
                window_com(J+1)(I) <= window_com(J)(I);
            end if;
            end loop;

            
            
             --stage N+1
            
            window_reg(9)(I) <= window_reg(8)(I);            
            coef_sign(9)(I) <= coef_sign(8)(I);
            coef_value(9)(I) <= coef_value(8)(I);                      
            if (coef_sign(8)(I) = '1') then
                window_com(8)(I) <=  std_logic_vector( - signed(window_com(7)(I)));
                else
                window_com(8)(I) <= window_com(7)(I);
            end if;
            
            
        
        end loop;
        
        -- Sum tree 3x3 9  16->8->4->2->1 5x5 25 32->16->8->4->2->1 10x10 128->64->32->16->8->4->2->1
        sum_tree(0) <= (others=>(others=>'0'));
        for I in 0 to kernel_array_size loop
            sum_tree(0)(I) <= signed(window_com(8)(I));
        end loop;
        
        for J in 1 to SUM_DEPTH loop
            sum_tree(J) <= (others=>(others=>'0'));
            for I in 0 to ((2**SUM_DEPTH)/(2**J))-1 loop
                sum_tree(J)(I) <= sum_tree(J-1)(I*2) + sum_tree(J-1)((I*2)+1);
            end loop;
        end loop;
        
        
        --Barrel Shifter 8,4,2,1
        if (shift_value(3) = '1') then
            shift_8 <= shift_right(sum_tree(SUM_DEPTH)(0),8);
        else 
            shift_8 <= sum_tree(SUM_DEPTH)(0);
        end if;
               
        
        if (shift_value(2) = '1') then
            shift_4 <= shift_right(shift_8,4);
        else 
            shift_4 <= shift_8;
        end if; 
        
        if (shift_value(1) = '1') then
            shift_2 <= shift_right(shift_4,2);
        else 
            shift_2 <= shift_4;
        end if; 
        
        if (shift_value(0) = '1') then
            shift_1 <= shift_right(shift_2,1);
        else 
            shift_1 <= shift_2;
        end if; 
               
        --Upper Limit
        if (shift_1 > signed('0' & upper_limit)) then
            ulimited <= signed(upper_limit);
        else
            ulimited <= shift_1(7 downto 0);
        end if;        
        
        --Lower Limit
        if (ulimited < signed( '0' & lower_limit)) then
            llimited <= signed(lower_limit);
        else
            llimited <= ulimited;
        end if;  
        
        output <= std_logic_vector(llimited);
        
        valid_sr(0) <= valid_in;
        valid_sr(valid_sr'length-1 downto 1) <= valid_sr(valid_sr'length-2 downto 0);
        valid_out <= valid_sr(valid_sr'length-1);
        
        eol_sr(0) <= eol;
        eol_sr(eol_sr'length-1 downto 1) <= eol_sr(eol_sr'length-2 downto 0);
        eol_out <= eol_sr(eol_sr'length-1);
        
        frs_sr(0) <= new_frame;
        frs_sr(frs_sr'length-1 downto 1) <= frs_sr(frs_sr'length-2 downto 0);
        new_frame_out <= frs_sr(frs_sr'length-1);
    end if;
end process;



end Behavioral;
