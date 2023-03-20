----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/15/2020 07:35:45 PM
-- Design Name: 
-- Module Name: line_buf - Behavioral
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

entity line_buf is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           grey : in STD_LOGIC_VECTOR (7 downto 0);
           valid_in  : in  STD_LOGIC;
           valid_out : out STD_LOGIC;
           
           new_frame        :  in STD_LOGIC; --user bit
           eol              :  in STD_LOGIC; -- last bit
           new_frame_out    : out STD_LOGIC; --user bit
           eol_out          : out STD_LOGIC; -- last bit
            window : out t_window := (others=>(others=>'0')));
end line_buf;

architecture Behavioral of line_buf is

signal window_reg :t_window := (others=>(others=>'0'));
constant line_size : positive := 1920-1;
type t_line is array(0 to line_size) of std_logic_vector(7 downto 0);
type t_line_buffers is array (0 to kernel_size-1) of t_line;

signal line_buffers : t_line_buffers;

signal x_count : unsigned (31 downto 0):= (others=>'0');
signal y_count : unsigned (31 downto 0);

type t_suby is array(0 to kernel_size-1) of unsigned(31 downto 0);
type t_line_out is array (0 to kernel_size-1) of std_logic_vector(7 downto 0);

signal sub_y_count : t_suby;
signal sub_y_count_reg : t_suby;

signal grey_reg : std_logic_vector(7 downto 0);
signal valid_reg: std_logic;

signal we_vector : std_logic_vector (kernel_size-1 downto 0):= ('1',others=>'0');
signal line_out : t_line_out;

begin

-- n number of line buffers
-- write to one
-- read from others
-- incoming data (written) placed in bottom left of window
-- the other n-1 line buffer read values are placed on the left side of the window

process (clk)
begin
    if rising_edge(clk) then
    if (rst = '1') then
        x_count <= (others => '0');
        for I in 0 to kernel_size-1 loop
            sub_y_count(I) <= to_unsigned(I,32);
        end loop;
    else
        x_count <= x_count + 1;
        if (eol = '1') then
            x_count <= (others=>'0');
            for I in 0 to kernel_size-1 loop
                sub_y_count(I) <=  sub_y_count(I) + 1;
                if (sub_y_count(I) = kernel_size-1) then
                    sub_y_count(I) <= (others=>'0');
                end if; 
            end loop;
        end if;
        
        sub_y_count_reg <= sub_y_count;
        grey_reg <= grey;
        
        valid_reg <= valid_in;
        valid_out <= valid_reg;
        
        window_reg((kernel_size*kernel_size)-1) <= grey_reg;
        for I in 1 to kernel_size-1 loop                
            window_reg((kernel_size*(kernel_size-I))-1) <= line_out(to_integer(sub_y_count_reg(kernel_size-I)));
        end loop;   
        --- 1 -> 0, 24 -> 23, 5 !-> 4, 20 !->19
        for I in 0 to kernel_size-1 loop   
            for J in 1 to kernel_size-1 loop
                window_reg((I*kernel_size+J)-1) <=  window_reg((I*kernel_size+J));
            end loop;
        end loop;            
    end if;
    end if;
end process;

LINE_GEN:
for I in 0 to kernel_size-1 generate
    process (clk)
    begin
        if rising_edge(clk) then
            line_out(I) <= line_buffers(I)(to_integer(x_count));
            if (sub_y_count(0) = I and valid_in = '1') then
                line_buffers(I)(to_integer(x_count)) <= grey;
            end if;
        end if;
    end process;
end generate LINE_GEN;

window <= window_reg;



end Behavioral;
