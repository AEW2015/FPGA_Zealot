----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/02/2020 07:35:57 PM
-- Design Name: 
-- Module Name: vpp - Behavioral
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

entity vpp is
    Port (  clk : in STD_LOGIC;            
            rst : in STD_LOGIC;
            valid_in : in STD_LOGIC;
            rgb : in STD_LOGIC_VECTOR (23 downto 0);  --blue,green,red
            shift_value : in STD_LOGIC_VECTOR(3 downto 0);
            upper_limit : in STD_LOGIC_VECTOR(7 downto 0);
            lower_limit : in STD_LOGIC_VECTOR(7 downto 0);
            coef : in t_coef  := (others=>(others=>'0'));
            
            valid_out : out STD_LOGIC;           
            new_frame        :  in STD_LOGIC; --user bit
            eol              :  in STD_LOGIC; -- last bit
            new_frame_out    : out STD_LOGIC; --user bit
            eol_out          : out STD_LOGIC; -- last 
            output : out STD_LOGIC_VECTOR(7 downto 0)
           );
end vpp;

architecture Behavioral of vpp is
signal grey : STD_LOGIC_VECTOR (7 downto 0);

signal g_valid : std_logic;
signal g_nf : std_logic;
signal g_eol : std_logic;
signal l_valid : std_logic;
signal l_nf : std_logic;
signal l_eol : std_logic;

signal window : t_window;
begin

grey_0 : entity work.greyscale 
port map (
    clk => clk,
    valid_in => valid_in,
    rgb => rgb,
    valid_out => g_valid,
    new_frame => new_frame,
    eol => eol,
    new_frame_out => g_nf,
    eol_out => g_eol,
    grey_v => grey
);

line_0 : entity work.line_buf
port map (
    clk => clk,
    rst => rst,
    new_frame => g_nf,
    eol => g_eol,
    new_frame_out => l_nf,
    eol_out => l_eol,
    grey => grey,
    valid_in  => g_valid,
    valid_out => l_valid,
    window => window
);

oper_0 : entity work.operator
port map (
    clk => clk,
    valid_in  => l_valid,
    valid_out => valid_out,
    new_frame => l_nf,
    eol => l_eol,
    new_frame_out => new_frame_out,
    eol_out => eol_out,
    shift_value => shift_value,
    upper_limit => upper_limit,
    lower_limit => lower_limit,
    window => window,
    coef => coef,
    output => output
);

end Behavioral;
