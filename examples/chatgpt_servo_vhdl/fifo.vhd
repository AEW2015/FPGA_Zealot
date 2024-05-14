library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity FIFO is
    Generic (
        DATA_WIDTH : integer := 16;
        ADDR_WIDTH : integer := 4
    );
    Port (
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        write_en : in STD_LOGIC;
        read_en : in STD_LOGIC;
        data_in : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        data_out : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        empty : out STD_LOGIC;
        full : out STD_LOGIC
    );
end FIFO;

architecture Behavioral of FIFO is
    type fifo_array is array (2**ADDR_WIDTH-1 downto 0) of STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    signal fifo_mem : fifo_array;
    signal write_ptr : integer range 0 to 2**ADDR_WIDTH-1 := 0;
    signal read_ptr : integer range 0 to 2**ADDR_WIDTH-1 := 0;
    signal fifo_count : integer range 0 to 2**ADDR_WIDTH := 0;
begin
    process(clk, reset)
    begin
        if reset = '1' then
            write_ptr <= 0;
            read_ptr <= 0;
            fifo_count <= 0;
        elsif rising_edge(clk) then
            if write_en = '1' and fifo_count < 2**ADDR_WIDTH then
                fifo_mem(write_ptr) <= data_in;
                write_ptr <= (write_ptr + 1) mod 2**ADDR_WIDTH;
                fifo_count <= fifo_count + 1;
            end if;

            if read_en = '1' and fifo_count > 0 then
                data_out <= fifo_mem(read_ptr);
                read_ptr <= (read_ptr + 1) mod 2**ADDR_WIDTH;
                fifo_count <= fifo_count - 1;
            end if;
        end if;
    end process;

    empty <= '1' when fifo_count = 0 else '0';
    full <= '1' when fifo_count = 2**ADDR_WIDTH else '0';
end Behavioral;
