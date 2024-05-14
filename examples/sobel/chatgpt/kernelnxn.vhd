library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity KernelNxN is
    generic (
        DATA_WIDTH : integer := 8;  -- Width of the grayscale data
        KERNEL_SIZE : integer := 3  -- Size of the NxN kernel
    );
    Port (
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        pixel_in : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        pixel_out : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        kernel : in STD_LOGIC_VECTOR(KERNEL_SIZE*KERNEL_SIZE*DATA_WIDTH-1 downto 0)  -- NxN kernel values
    );
end KernelNxN;

architecture Behavioral of KernelNxN is
    -- Internal signals for line buffers
    type line_buffer_type is array(0 to KERNEL_SIZE-1) of STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    signal line_buffer : line_buffer_type := (others => (others => '0'));

    -- Internal signals for pipelined windows
    type window_type is array(0 to KERNEL_SIZE-1, 0 to KERNEL_SIZE-1) of STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    signal window : window_type;

    -- Pipeline registers for intermediate products and sums
    type product_array_type is array(0 to KERNEL_SIZE-1, 0 to KERNEL_SIZE-1) of integer;
    signal products : product_array_type := (others => 0);

    -- Maximum depth of sum tree
    constant MAX_STAGE : integer := integer(ceil(log2(real(KERNEL_SIZE*KERNEL_SIZE))));

    -- Intermediate sums for pipelined sum tree
    signal sum_stage : array(0 to MAX_STAGE, 0 to (KERNEL_SIZE*KERNEL_SIZE)-1) of integer := (others => (others => 0));

    -- Output register for final result
    signal final_result : integer;

    function to_integer_unsigned (input : STD_LOGIC_VECTOR) return integer is
    begin
        return to_integer(unsigned(input));
    end function;

begin
    process(clk, reset)
    begin
        if reset = '1' then
            line_buffer <= (others => (others => '0'));
            window <= (others => (others => '0'));
            products <= (others => 0);
            sum_stage <= (others => (others => 0));
            final_result <= 0;
            pixel_out <= (others => '0');
        elsif rising_edge(clk) then
            -- Shift the line buffer
            for i in KERNEL_SIZE-1 downto 1 loop
                line_buffer(i) <= line_buffer(i-1);
            end loop;
            line_buffer(0) <= pixel_in;

            -- Form the NxN window
            for i in 0 to KERNEL_SIZE-1 loop
                for j in 0 to KERNEL_SIZE-1 loop
                    if j = 0 then
                        window(i, j) <= line_buffer(i);
                    else
                        window(i, j) <= window(i, j-1);
                    end if;
                end loop;
            end loop;

            -- Pipeline stage 1: Calculate products using shifts
            for i in 0 to KERNEL_SIZE-1 loop
                for j in 0 to KERNEL_SIZE-1 loop
                    products(i, j) <= 0;
                    for k in 0 to DATA_WIDTH-1 loop
                        if kernel((i*KERNEL_SIZE+j+1)*DATA_WIDTH-1 downto (i*KERNEL_SIZE+j)*DATA_WIDTH)(k) = '1' then
                            products(i, j) <= products(i, j) + (to_integer_unsigned(window(i, j)) sll k);
                        end if;
                    end loop;
                end loop;
            end loop;

            -- Sum tree: Pipeline stages
            for stage in 0 to MAX_STAGE loop
                if stage = 0 then
                    for i in 0 to KERNEL_SIZE*KERNEL_SIZE-1 loop
                        sum_stage(stage, i) <= products(i / KERNEL_SIZE, i mod KERNEL_SIZE);
                    end loop;
                else
                    for i in 0 to (KERNEL_SIZE*KERNEL_SIZE)/(2**stage)-1 loop
                        sum_stage(stage, i) <= sum_stage(stage-1, 2*i) + sum_stage(stage-1, 2*i+1);
                    end loop;
                end if;
            end loop;

            -- Final summation
            final_result <= sum_stage(MAX_STAGE, 0);

            -- Normalize the sum and assign to output
            pixel_out <= std_logic_vector(to_unsigned(final_result / (KERNEL_SIZE * KERNEL_SIZE), DATA_WIDTH));
        end if;
    end process;
end Behavioral;
