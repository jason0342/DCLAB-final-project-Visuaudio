module I2cSender (
    input i_start,
    input [23:0] i_data,
    input i_clk,
    input i_rst,
    output o_finished,
    output o_sclk,
    inout o_sdat
);

    localparam resetBits = 24'b0011_0100_000_1111_0_0000_0000;

    typedef enum { 
        S_INITIAL,
        S_TRANSIT,
        S_DATAPAS, 
        S_FINAL
    } MainState;

    MainState state_r, state_w;

    logic o_finished_r, o_finished_w, o_sclk_r, o_sclk_w, o_sdat_r, o_sdat_w;
    logic oe_r, oe_w;
    logic [23:0] data_r, data_w;
    logic [1:0] clk_count_r, clk_count_w;
    logic [3:0] total_count_r, total_count_w;
    logic [1:0] bytes_count_r, bytes_count_w;


    assign o_finished = o_finished_r;
    assign o_sclk = o_sclk_r;
    assign o_sdat = oe_r ? o_sdat_r : 1'bz;

    always_comb begin
        state_w         = state_r;
        o_finished_w    = o_finished_r;
        o_sclk_w        = o_sclk_r;
        o_sdat_w        = o_sdat_r;
        oe_w            = oe_r;

        clk_count_w     = clk_count_r;
        total_count_w   = total_count_r;
        bytes_count_w   = bytes_count_r;

        data_w          = data_r;

        case (state_r)
            S_INITIAL: begin
                if (i_start == 1) begin
                    state_w = S_TRANSIT;
                    o_finished_w = 0;
                    o_sdat_w = 0;

                    clk_count_w = 0;
                    total_count_w = 0;
                    bytes_count_w = 0;

                    data_w = i_data;
                end
            end

            S_TRANSIT: begin
                o_sclk_w = 0;
                if (o_sclk_r == 0) begin
                    state_w = S_DATAPAS;
                    data_w = (data_r << 1);
                    o_sdat_w = data_r[23];
                end
            end

            S_DATAPAS: begin
                if (clk_count_r == 0) begin
                    clk_count_w = clk_count_r + 1;
                    o_sclk_w    = 1;
                end else if (clk_count_r == 1) begin
                    clk_count_w = clk_count_r + 1;
                    o_sclk_w    = 0;
                end else if (clk_count_r == 2) begin
                    clk_count_w = 0;
                    total_count_w = total_count_r + 1;

                    if (total_count_r < 7) begin
                        o_sdat_w = data_r[23];
                        data_w = (data_r << 1);
                    end else if (total_count_r == 7) begin
                        oe_w = 0;
                    end else if (total_count_r == 8 && bytes_count_r != 2) begin
                        oe_w = 1;
                        o_sdat_w = data_r[23];
                        data_w = (data_r << 1);
                        total_count_w = 0;
                        bytes_count_w = bytes_count_r + 1;
                    end else if (total_count_r == 8 && bytes_count_r == 2) begin
                        oe_w = 1;
                        o_sdat_w = 0;
                        state_w = S_FINAL;
                    end
                end
            end

            S_FINAL: begin
                o_sclk_w = 1;
                if (o_sclk_r == 1) begin
                    o_sdat_w = 1;
                    state_w = S_INITIAL;
                    o_finished_w = 1;
                end
            end

        endcase
    end

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state_r         <= S_INITIAL;
            o_finished_r    <= 1;
            o_sclk_r        <= 1;
            o_sdat_r        <= 1;
            oe_r            <= 1;

            clk_count_r     <= 0;
            total_count_r   <= 0;
            bytes_count_r   <= 0;

            data_r          <= resetBits;
        end else begin
            state_r <= state_w;
            o_finished_r    <= o_finished_w;
            o_sclk_r        <= o_sclk_w;
            o_sdat_r        <= o_sdat_w;
            oe_r            <= oe_w;

            clk_count_r     <= clk_count_w;
            total_count_r   <= total_count_w;
            bytes_count_r   <= bytes_count_w;

            data_r          <= data_w;
        end
    end


endmodule
