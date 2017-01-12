module I2cInitializer (
    input   i_start,
    input   i_clk,
    input   i_rst,
    output  o_finished,
    output  o_sclk,
    inout   o_sdat
);
    parameter bit [23:0] data [0:9] = '{
        24'b00110100000_0000_0_1001_0111,
        24'b00110100000_0001_0_1001_0111,
        24'b00110100000_0010_0_0111_1001,
        24'b00110100000_0011_0_0111_1001,
        24'b00110100000_0100_0_0001_0101, //
        24'b00110100000_0101_0_0000_0000,
        24'b00110100000_0110_0_0000_0000,
        24'b00110100000_0111_0_0100_0010,
        24'b00110100000_1000_0_0001_1001,
        24'b00110100000_1001_0_0000_0001
    };
    parameter IDLE      = 3'd0;
    parameter START     = 3'd1;
    parameter SETDATA   = 3'd2;
    parameter TRANS     = 3'd3;
    parameter SETACK    = 3'd4;
    parameter ACK       = 3'd5;
    parameter SHIFT     = 3'd6;
    parameter FINISH    = 3'd7;

    logic [2:0]  state_w,    state_r;
    logic        sda_w,      sda_r;
    logic        scl_w,      scl_r;
    logic        fin_w,      fin_r;
    logic [23:0] data_w,     data_r;

    logic [3:0] DataCounter_w,  DataCounter_r;
    logic [4:0] BitCounter_w,   BitCounter_r;


    assign o_sclk = scl_r;
    assign o_sdat = sda_r;
    assign o_finished = fin_r;

    always_comb begin
        state_w = state_r;
        sda_w   = sda_r;
        scl_w   = scl_r;
        fin_w   = fin_r;
        data_w  = data_r;

        DataCounter_w   = DataCounter_r;
        BitCounter_w    = BitCounter_r;

        case(state_r)
            IDLE: begin
                sda_w  = 1;
                scl_w  = 1;
                fin_w  = fin_r;//0;
                data_w = 0;
                BitCounter_w = 0;
                if ( DataCounter_r == 10 )
                    fin_w = 1;
                else
                    state_w = START;
            end
            START: begin
                sda_w   = 0;
                data_w  = data[ DataCounter_r ];
                state_w = SETDATA;
            end
            SETDATA: begin
                scl_w   = 0;
                sda_w   = data_w[ 23-BitCounter_r ];
                state_w = TRANS;
                BitCounter_w = BitCounter_r + 1;
            end
            TRANS: begin
                scl_w   = 1;
                if ( BitCounter_r % 8 == 0 )
                    state_w = SETACK;
                else
                    state_w = SETDATA;
            end
            SETACK: begin
                scl_w   = 0;
                sda_w   = 1'bz;
                state_w = ACK;
            end
            ACK: begin
                scl_w   = 1;
                if ( BitCounter_r == 24 ) begin
                    DataCounter_w   = DataCounter_r + 1;
                    BitCounter_w    = 0;
                    state_w = SHIFT;
                end
                else
                    state_w = SETDATA;
            end
            SHIFT: begin
                scl_w   = 0;
                sda_w   = 0;
                state_w = FINISH;
            end
            FINISH: begin
                scl_w   = 1;
                state_w = IDLE;
            end
        endcase
    end

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state_r <= IDLE;
            sda_r   <= 1;
            scl_r   <= 1;
            fin_r   <= 0;
            data_r  <= 0;
            DataCounter_r <= 0;
            BitCounter_r  <= 0;
        end
        else begin
            state_r <= state_w;
            sda_r   <= sda_w;
            scl_r   <= scl_w;
            fin_r   <= fin_w;
            data_r  <= data_w;
            DataCounter_r <= DataCounter_w;
            BitCounter_r  <= BitCounter_w;
        end
    end
endmodule
