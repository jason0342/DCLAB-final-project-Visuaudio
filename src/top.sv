module top(
	input i_start, //KEY[3], after debounce
	input i_stop,
	input i_up,
	input i_down, //KEY[0]
	// input SW02, // 0:normal, 1:change speed ?
	input ADCLRCK,
	input ADCDAT,
	input DACLRCK,
	input i_clk, //BCLK
	input i_clk2, //100kHz for i2c
	input i_rst, //SW00?
	input i_switch, // enable signal

	inout I2C_SDAT,
	inout [15:0] SRAM_DQ,

	output I2C_SCLK,
	output [19:0] SRAM_ADDR,
	output SRAM_CE_N,
	output SRAM_OE_N,
	output SRAM_WE_N,
	output SRAM_UB_N,
	output SRAM_LB_N,
	output DACDAT,
	output [4:0] o_timer,
	output [2:0] o_state,
	output [1:0] o_ini_state,
	output [1:0] o_rec_state,
	output [2:0] o_play_state,
);

	enum { S_INIT, S_IDLE, S_SETTING } state_r, state_w;
	enum { FREQ1, FREQ2, FREQ3, FREQ4, FREQ5, FREQ6 } eq_freq_r, eq_freq_w;

	logic startI_r, startI_w;
	logic doneI, doneP, doneR;
	logic[31:0] data_r, data_w;

	assign o_state = state_r;
	assign SRAM_CE_N = 0;
	assign SRAM_UB_N = 0;
	assign SRAM_LB_N = 0;

	I2CManager i2cM(
		.i_start(startI_r),
		.i_clk(i_clk2),
		.i_rst(i_rst),
		.o_finished(doneI),
		.o_sclk(I2C_SCLK),
		.o_sdat(I2C_SDAT),
		.o_ini_state(o_ini_state)
	);

	ADCcontroller adc(
		.i_record(startR_r),
		.i_ADCLRCK(ADCLRCK),
		.i_ADCDAT(ADCDAT),
		.i_BCLK(i_clk),
		.o_SRAM_DATA(r_data),
		.o_done(doneR),
		.o_REC_STATE(o_rec_state)
	);

	DACcontroller dac(
		.i_play(startP_r),
		.i_start_pos(pos_r),
		.i_end_pos(maxPos_r),
		.i_speed(speedtoDac),
		.i_DACLRCK(DACLRCK),
		.i_BCLK(i_clk),
		.i_SRAM_DATA(p_data),
		.o_SRAM_OE(SRAM_OE_N),
		.o_SRAM_ADDR(p_addr),
		.o_DACDAT(DACDAT),
		.o_done(doneP),
		.o_state(o_play_state)
	);

always_comb begin
	state_w = state_r;
	startI_w = startI_r;

	case(state_r)
		S_INIT: begin
			startI_w = 1;
			//call I2CManager
			if(doneI) begin
				state_w = S_IDLE;
				startI_w = 0;
			end
		end

		S_IDLE: begin
			startI_w = 0;
			pos_w = 0;
			
		end

		S_SETTING: begin
			case(eq_freq_r)
			endcase
		end

	endcase

end

always_ff @(posedge i_clk or posedge i_rst) begin
	if(i_rst) begin
		state_r <= S_INIT;
		startI_r <= 1;
		startP_r <= 0;
		startR_r <= 0;
	end else begin
		state_r <= state_w;
		startI_r <= startI_w;
		startP_r <= startP_w;
		startR_r <= startR_w;
	end
end

endmodule
