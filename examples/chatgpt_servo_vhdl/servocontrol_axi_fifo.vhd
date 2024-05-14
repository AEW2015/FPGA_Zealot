library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ServoControl_AXI_FIFO is
    Port (
        -- Global Signals
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        
        -- AXI Lite Slave Interface
        s_axi_awaddr : in STD_LOGIC_VECTOR(3 downto 0);
        s_axi_awprot : in STD_LOGIC_VECTOR(2 downto 0);
        s_axi_awvalid : in STD_LOGIC;
        s_axi_awready : out STD_LOGIC;
        s_axi_wdata : in STD_LOGIC_VECTOR(31 downto 0);
        s_axi_wstrb : in STD_LOGIC_VECTOR(3 downto 0);
        s_axi_wvalid : in STD_LOGIC;
        s_axi_wready : out STD_LOGIC;
        s_axi_bresp : out STD_LOGIC_VECTOR(1 downto 0);
        s_axi_bvalid : out STD_LOGIC;
        s_axi_bready : in STD_LOGIC;
        s_axi_araddr : in STD_LOGIC_VECTOR(3 downto 0);
        s_axi_arprot : in STD_LOGIC_VECTOR(2 downto 0);
        s_axi_arvalid : in STD_LOGIC;
        s_axi_arready : out STD_LOGIC;
        s_axi_rdata : out STD_LOGIC_VECTOR(31 downto 0);
        s_axi_rresp : out STD_LOGIC_VECTOR(1 downto 0);
        s_axi_rvalid : out STD_LOGIC;
        s_axi_rready : in STD_LOGIC;
        
        -- Servo Control
        servo_pwm : out STD_LOGIC
    );
end ServoControl_AXI_FIFO;

architecture Behavioral of ServoControl_AXI_FIFO is
    signal pwm_counter : integer range 0 to 1999999 := 0; -- 20 ms period at 100 MHz clock
    signal duty_cycle : integer range 0 to 1999999 := 0;
    signal position : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal wait_time : integer := 0;
    signal wait_counter : integer := 0;
    signal new_command : STD_LOGIC := '0';
    signal executing_command : STD_LOGIC := '0';
    
    -- AXI Lite signals
    signal awready_int : STD_LOGIC := '0';
    signal wready_int : STD_LOGIC := '0';
    signal bresp_int : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal bvalid_int : STD_LOGIC := '0';
    signal arready_int : STD_LOGIC := '0';
    signal rdata_int : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal rresp_int : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal rvalid_int : STD_LOGIC := '0';

    -- FIFO signals
    signal fifo_data_in : STD_LOGIC_VECTOR(15 downto 0);
    signal fifo_data_out : STD_LOGIC_VECTOR(15 downto 0);
    signal fifo_empty : STD_LOGIC;
    signal fifo_full : STD_LOGIC;
    signal fifo_write_en : STD_LOGIC := '0';
    signal fifo_read_en : STD_LOGIC := '0';
    
    component FIFO
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
    end component;

begin
    fifo_inst : FIFO
        port map (
            clk => clk,
            reset => reset,
            write_en => fifo_write_en,
            read_en => fifo_read_en,
            data_in => fifo_data_in,
            data_out => fifo_data_out,
            empty => fifo_empty,
            full => fifo_full
        );

    -- AXI Lite write process
    process(clk, reset)
    begin
        if reset = '1' then
            awready_int <= '0';
            wready_int <= '0';
            bvalid_int <= '0';
            fifo_write_en <= '0';
        elsif rising_edge(clk) then
            if s_axi_awvalid = '1' and awready_int = '0' then
                awready_int <= '1';
            elsif s_axi_wvalid = '1' and wready_int = '0' then
                wready_int <= '1';
            else
                awready_int <= '0';
                wready_int <= '0';
            end if;
            
            if awready_int = '1' and wready_int = '1' and bvalid_int = '0' then
                bvalid_int <= '1';
                fifo_data_in <= s_axi_wdata(15 downto 0); -- Assuming lower 16 bits for position and wait time
                fifo_write_en <= '1';
            elsif s_axi_bready = '1' then
                bvalid_int <= '0';
                fifo_write_en <= '0';
            end if;
        end if;
    end process;

    -- AXI Lite read process
    process(clk, reset)
    begin
        if reset = '1' then
            arready_int <= '0';
            rvalid_int <= '0';
        elsif rising_edge(clk) then
            if s_axi_arvalid = '1' and arready_int = '0' then
                arready_int <= '1';
                rdata_int <= (others => '0');
                rdata_int(7 downto 0) <= position;
                rvalid_int <= '1';
            elsif rvalid_int = '1' and s_axi_rready = '1' then
                rvalid_int <= '0';
            else
                arready_int <= '0';
            end if;
        end if;
    end process;
    
    -- Connect AXI Lite interface signals
    s_axi_awready <= awready_int;
    s_axi_wready <= wready_int;
    s_axi_bresp <= bresp_int;
    s_axi_bvalid <= bvalid_int;
    s_axi_arready <= arready_int;
    s_axi_rdata <= rdata_int;
    s_axi_rresp <= rresp_int;
    s_axi_rvalid <= rvalid_int;

    -- Servo PWM generation process with FIFO commands
    process(clk, reset)
    begin
        if reset = '1' then
            pwm_counter <= 0;
            servo_pwm <= '0';
            executing_command <= '0';
            wait_counter <= 0;
        elsif rising_edge(clk) then
            if pwm_counter < 1999999 then
                pwm_counter <= pwm_counter + 1;
            else
                pwm_counter <= 0;
            end if;

            -- Handle FIFO commands
            if executing_command = '0' and fifo_empty = '0' then
                fifo_read_en <= '1';
                executing_command <= '1';
            else
                fifo_read_en <= '0';
            end if;
            
            if executing_command = '1' then
                if wait_counter < wait_time then
                    wait_counter <= wait_counter + 1;
                else
                    position <= fifo_data_out(7 downto 0); -- Position is lower 8 bits
                    wait_time <= to_integer(unsigned(fifo_data_out(15 downto 8))); -- Wait time is upper 8 bits
                    wait_counter <= 0;
                    executing_command <= '0';
                end if;
            end if;
            
            -- Calculate duty cycle based on position input
            duty_cycle <= (to_integer(unsigned(position)) * 20000) / 255 + 100000; -- Map 0-255 to 1-2 ms pulse width
            
            -- Generate PWM signal
            if pwm_counter < duty_cycle then
                servo_pwm <= '1';
            else
                servo_pwm <= '0';
            end if;
        end if;
    end process;
end Behavioral;
