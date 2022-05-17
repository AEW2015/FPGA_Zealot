----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/10/2020 07:36:43 PM
-- Design Name: 
-- Module Name: greyscale - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity greyscale is
    Port ( clk : in STD_LOGIC;
           valid_in : in STD_LOGIC;
           rgb : in STD_LOGIC_VECTOR (23 downto 0);  --blue,green,red
           valid_out : out STD_LOGIC;           
           new_frame        :  in STD_LOGIC; --user bit
           eol              :  in STD_LOGIC; -- last bit
           new_frame_out    : out STD_LOGIC; --user bit
           eol_out          : out STD_LOGIC; -- last bit
           grey_v : out STD_LOGIC_VECTOR (7 downto 0));
end greyscale;

architecture Behavioral of greyscale is

signal red   : unsigned (7 downto 0);
signal blue  : unsigned (7 downto 0);
signal green : unsigned (7 downto 0);
signal compr : unsigned (15 downto 0);
signal compg : unsigned (15 downto 0);
signal compb : unsigned (15 downto 0);
signal comp0 : unsigned (15 downto 0);
signal comp1 : unsigned (15 downto 0);
signal comp2 : unsigned (15 downto 0);
signal val_reg : std_logic_vector (4 downto 0);
signal frs_reg : std_logic_vector (4 downto 0);
signal eol_reg : std_logic_vector (4 downto 0);
begin

process (clk)
begin
    if rising_edge(clk) then
        red   <= unsigned(rgb(23 downto 16));
        green <= unsigned(rgb(15 downto 8));
        blue  <= unsigned(rgb(7 downto 0));
        val_reg(0) <= valid_in;
        frs_reg(0) <= new_frame;
        eol_reg(0) <= eol;
        
        compr <= 56 * red;    -- R * 0.22
        compg <= 179 * green; -- G * 0.70
        compb <= 18 * blue;   -- B * 0.07
        val_reg(1) <= val_reg(0);
        frs_reg(1) <= frs_reg(0);
        eol_reg(1) <= eol_reg(0);
        
        comp0 <= (compr + compg + compb + 128);        
        val_reg(2) <= val_reg(1);
        frs_reg(2) <= frs_reg(1);
        eol_reg(2) <= eol_reg(1);
        
        comp1 <= x"00" & comp0(15 downto 8);
        val_reg(3) <= val_reg(2);
        frs_reg(3) <= frs_reg(2);
        eol_reg(3) <= eol_reg(2);
        
        comp2 <= comp1;
        val_reg(4) <= val_reg(3);
        frs_reg(4) <= frs_reg(3);
        eol_reg(4) <= eol_reg(3);
    end if;
end process;
    grey_v <= std_logic_vector(comp2(7 downto 0));
    valid_out <= val_reg(4);
    new_frame_out <= frs_reg(4);
    eol_out <= eol_reg(4);

end Behavioral;
