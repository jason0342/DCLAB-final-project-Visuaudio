module top(
	input i_select, //KEY[3], after debounce
	input i_back,
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
	// inout [15:0] SRAM_DQ,

	output I2C_SCLK,
	output [19:0] SRAM_ADDR,
	// output SRAM_CE_N,
	// output SRAM_OE_N,
	// output SRAM_WE_N,
	// output SRAM_UB_N,
	// output SRAM_LB_N,
	output DACDAT,
	output [4:0] o_timer,
	output [2:0] o_state,
	output [1:0] o_ini_state,
	output [1:0] o_rec_state,
	output [2:0] o_play_state,
);

	parameter nBand = 6;

	enum { S_INIT, S_IDLE, S_BAND_SEL, S_SET_GAIN } state_r, state_w;

	logic startI_r, startI_w;
	logic doneI, doneP, doneR, doneDSP;
	logic r_data, p_data;
	logic[31:0] data_r, data_w;
	logic[2:0] band_r, band_w;
	logic[2:0] set_band;
	logic[nBand:0][15:0] gain_r, gain_w;
	logic[15:0] set_gain;

	assign o_state = state_r;
	assign set_band = band_r;
	assign set_gain = gain_r[band_r];
	// assign SRAM_CE_N = 0;
	// assign SRAM_UB_N = 0;
	// assign SRAM_LB_N = 0;

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
		.o_DATA(r_data),
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

	DSP dsp0(
		i_clk(i_clk),
		i_rst(i_rst),
		i_doneR(doneR),
		i_data(r_data),
		o_data(p_data),
		o_done(doneDSP)
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
			if(i_select) begin
				state_w = S_BAND_SEL;
				band_w = 1;
			end
		end

		S_BAND_SEL: begin
			if(i_back) begin
				state_w = S_IDLE;
				band_w = 0;
			end else if(i_select) begin
				state_w = S_SET_GAIN;
			end else if(i_up && band_r != nBand) begin
				band_w = band_r + 1;
			end else if(i_down && band_r != 0) begin
				band_w = band_R - 1;
			end

		end

		S_SET_GAIN: begin
			if(i_back) begin
				state_w = S_BAND_SEL;
			end else if (i_up) begin
				if(int'(gain_r[band_r]) <= 12) begin
					gain_w[band_r] = int'(gain_r[band_r]) + 1;
				end
			end else if (i_down) begin
				if(int'(gain_r[band_r]) >= -12) begin
					gain_w[band_r] = int'(gain_r[band_r]) - 1;
				end
			end
		end

	endcase

end

always_ff @(posedge i_clk or posedge i_rst) begin
	if(i_rst) begin
		state_r <= S_INIT;
		startI_r <= 1;
		startP_r <= 0;
		startR_r <= 0;
		band_r <= 0;
		foreach(gain_r[i]) begin
			gain_r[i] <= 0;
		end
	end else begin
		state_r <= state_w;
		startI_r <= startI_w;
		startP_r <= startP_w;
		startR_r <= startR_w;
		band_r <= band_w;
		foreach(gain_r[i]) begin
			gain_r[i] <= gain_w[i];
		end
	end
end

endmodule
