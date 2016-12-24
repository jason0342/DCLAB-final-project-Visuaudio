module I2CManager (
    input i_start,
    input i_clk,
    input i_rst,
    output o_finished,
    output o_sclk,
    output[1:0] o_ini_state,
    inout o_sdat
);

    localparam resetBits = 24'b0011_0100_000_1111_0_0000_0000;

    // localparam LeftLineIn    = 16'b000_0000_0_1001_0111;
    // localparam RightLineIn   = 16'b000_0001_0_1001_0111;
    // localparam LeftHeadOut   = 16'b000_0010_0_0111_1001;
    // localparam RightHeadOut  = 16'b000_0011_0_0111_1001;
    localparam AnaAudPCtrl  = 16'b000_0100_0_0001_0101;
    localparam DigAudPCtrl  = 16'b000_0101_0_0000_0000;
    localparam PowerDnCtrl  = 16'b000_0110_0_0000_0000;
    localparam DigAudIntFmt = 16'b000_0111_0_0100_0010;
    localparam SamplingCtrl = 16'b000_1000_0_0001_1001;
    localparam ActiveCtrl   = 16'b000_1001_0_0000_0001;

    typedef enum {
        S_IDLE,
        S_BUFF,
        S_WAIT,
        S_END
    } State;

    State state_r, state_w;

    logic [23:0] data_r, data_w;
    logic [3:0] counter_r, counter_w;
    logic startS_r, startS_w;
    logic [2:0] buff_count_r, buff_count_w;
    logic s_finished;
    logic o_finished_r, o_finished_w;

    I2cSender i2cS (
        .i_start(startS_r),
        .i_data(data_r),
        .i_clk(i_clk),
        .i_rst(i_rst),
        .o_finished(s_finished),
        .o_sclk(o_sclk),
        .o_sdat(o_sdat)
    );

    assign o_finished = o_finished_r;
    assign o_ini_state = state_r;

    always_comb begin
        state_w = state_r;
        data_w = data_r;
        counter_w = counter_r;
        startS_w = startS_r;
        buff_count_w = buff_count_r;

        o_finished_w = o_finished_r;

        if (i_start) begin
            case (state_r)
                S_IDLE: begin
                    state_w = S_BUFF;
                    o_finished_w = 0;
                    counter_w = 0;
                end

                S_BUFF: begin
                    buff_count_w = buff_count_r + 1;
                    startS_w = 1;
                    if (buff_count_r == 7) begin
                        state_w = S_WAIT;
                        buff_count_w = 0;
                        startS_w = 0;
                    end
                end

                S_WAIT: begin
                    if (s_finished) begin
                        counter_w = counter_r + 1;
                        state_w = S_BUFF;
                        case (counter_r)
                            0: data_w[15:0] = AnaAudPCtrl;
                            1: data_w[15:0] = DigAudPCtrl;
                            2: data_w[15:0] = PowerDnCtrl;
                            3: data_w[15:0] = DigAudIntFmt;
                            4: data_w[15:0] = SamplingCtrl;
                            5: data_w[15:0] = ActiveCtrl;
                            default: begin
                                state_w = S_END;
                                data_w = resetBits;
                                startS_w = 0;
                                o_finished_w = 1;
                            end
                        endcase
                    end else begin
                        startS_w = 0;
                    end
                end

                S_END: begin
                    o_finished_w = 1;
                end

            endcase
        end
    end

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state_r         <= S_IDLE;
            data_r          <= resetBits;
            counter_r       <= 0;
            startS_r        <= 0;
            buff_count_r    <= 0;

            o_finished_r    <= 1;
        end else begin
            state_r         <= state_w;
            data_r          <= data_w;
            counter_r       <= counter_w;
            startS_r        <= startS_w;
            buff_count_r    <= buff_count_w;

            o_finished_r    <= o_finished_w;
        end
    end

endmodule
