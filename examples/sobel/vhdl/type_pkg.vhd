----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/29/2020 07:47:11 PM
-- Design Name: 
-- Module Name: type_pkg - Behavioral
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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package bus_pkg is
        constant kernel_size : positive := 10;
        constant kernel_array_size : positive := (kernel_size*kernel_size) -1;
        type t_window is array(0 to kernel_array_size) of std_logic_vector(7 downto 0);
        type t_coef is array(0 to kernel_array_size) of std_logic_vector(7 downto 0);
        type t_window_16 is array(0 to kernel_array_size) of std_logic_vector(15 downto 0);
        type t_window_8 is array(0 to kernel_array_size) of std_logic_vector(8 downto 0);
        type t_sign is array(0 to kernel_array_size) of std_logic;
        type t_value is array(0 to kernel_array_size) of std_logic_vector(7 downto 0);
    
        type t_window_array is array (0 to 9) of t_window_16;
        type t_sign_array is array (0 to 9) of t_sign;
        type t_value_array is array (0 to 9) of t_value;
        

end package;

