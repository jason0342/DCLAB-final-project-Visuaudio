module top(
	input i_select, //KEY[3], after debounce
	input i_back,
	input i_up,
	input i_down, //KEY[0]
	input ADCLRCK,
	input ADCDAT,
	input DACLRCK,
	input i_clk, //BCLK
	input i_clk2, //100kHz for i2c
	input i_clk3, //25Mhz
	input i_rst, //SW00?
	input i_switch, // enable signal
	input i_switch2,

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
	output [2:0] o_state,
	output [2:0] o_menu_state,
	output [2:0] o_band,
	output [31:0] o_gain,
	output [2:0] o_offset,
	output [1:0] o_fft_error,
	// output [1:0] o_ini_state,
	// output [2:0] o_play_state,
	output o_VGA_HS,
	output o_VGA_VS,
	output o_VGA_SYNC_N,
	output o_VGA_BLANK_N,
	output o_VGA_CLK,
	output[7:0] o_VGA_R,
	output[7:0] o_VGA_G,
	output[7:0] o_VGA_B,

	output[15:0] o_pdata,
	output o_doneDSP

);

	parameter nBand = 6;

	enum { 
		S_INIT,
		S_IDLE,
		S_MENU,
		S_BAND_SEL,
		S_SET_GAIN,
		S_SET_OFFSET,
		S_RESET_DSP
	} state_r, state_w;

	typedef enum { S_EQ, S_OFFSET, S_RESET } Menu_state;
	Menu_state state_menu_r, state_menu_w;
	// logic[2:0] state_menu_r, state_menu_w;

	logic startI_r, startI_w;
	logic doneI, doneP, doneR, doneDSP;
	logic[15:0] r_data, p_data;
	logic[2:0] band_r, band_w;
	logic[2:0] set_band;
	logic[nBand:0][31:0] gain_r, gain_w;
	logic[2:0] offset_r, offset_w;
	logic[15:0] set_gain;
	logic set_enable_r, set_enable_w;
	logic reset_dsp;
	logic[15:0][15:0] fft_data, fft_data2;
	logic fft_done;
	logic[10:0] VGA_X, VGA_Y;
	logic VGA_VS;

	assign o_state = state_r;
	assign o_menu_state = state_menu_r;
	assign o_band = band_r;
	assign o_gain = gain_r[band_r];
	assign o_offset = offset_r;
	assign set_band = band_r;
	assign set_gain = gain_r[band_r];
	assign reset_dsp = (state_r == S_RESET_DSP);
	assign o_VGA_VS = VGA_VS;

	assign o_pdata = p_data;
	assign o_doneDSP = doneDSP;
	// assign SRAM_CE_N = 0;
	// assign SRAM_UB_N = 0;
	// assign SRAM_LB_N = 0;

	// I2CManager i2cM(
	// 	.i_start(startI_r),
	// 	.i_clk(i_clk2),
	// 	.i_rst(i_rst),
	// 	.o_finished(doneI),
	// 	.o_sclk(I2C_SCLK),
	// 	.o_sdat(I2C_SDAT),
	// 	.o_ini_state(o_ini_state)
	// );

	I2cInitializer i2cM(
		.i_start(startI_r),
		.i_clk(i_clk2),
		.i_rst(i_rst),
		.o_finished(doneI),
		.o_sclk(I2C_SCLK),
		.o_sdat(I2C_SDAT)
	);

	ADCcontroller adc(
		.i_record(1),
		.i_ADCLRCK(ADCLRCK),
		.i_ADCDAT(ADCDAT),
		.i_BCLK(i_clk),
		.o_DATA(r_data),
		.o_done(doneR),
		.o_REC_STATE(o_rec_state)
	);

	DACcontroller dac(
		.i_play(i_switch),
		.i_valid(doneDSP),
		.i_DACLRCK(DACLRCK),
		.i_BCLK(i_clk),
		.i_DATA(p_data),
		.o_DACDAT(DACDAT)
	);

	DSP dsp0(
		.i_clk(i_clk),
		.i_rst(i_rst || reset_dsp),
		.i_doneR(doneR),
		.i_data(r_data),
		.i_gain(set_gain),
		.i_set_gain(set_band),
		.i_offset(offset_r),
		.o_data(p_data),
		.o_done(doneDSP)
	);

	FFTcontroller fftc0(
		.i_clk(i_clk),
		.i_rst(i_rst),
		.i_doneDSP(doneDSP),
		.i_data(p_data),
		.o_data(fft_data),
		.o_data_done(fft_done),
		.o_fft_error(o_fft_error)
	);

	FFTDSP fftdsp0(
		.i_clk(i_clk),
		.i_rst(i_rst),
		.i_fft_done(fft_done),
		.i_data(fft_data),
		.o_data(fft_data2)
	);

	Renderer renderer(
		.i_clk(i_clk),
		.i_clk2(i_clk3),
		.i_rst(i_rst),
		.i_switch2(i_switch2),
		.i_fft_data(fft_data2),
		.i_fft_done(fft_done),
		.i_VGA_X(VGA_X),
		.i_VGA_Y(VGA_Y),
		.i_VGA_lock(VGA_VS),
		.o_VGA_R(o_VGA_R),
		.o_VGA_G(o_VGA_G),
		.o_VGA_B(o_VGA_B),
	);

	VGA_Controller vga(
		.i_clk(i_clk3),
		.i_rst(i_rst),
		.o_VGA_X(VGA_X),
		.o_VGA_Y(VGA_Y),
		.o_VGA_HS(o_VGA_HS),
		.o_VGA_VS(VGA_VS),
		.o_VGA_SYNC_N(o_VGA_SYNC_N),
		.o_VGA_BLANK_N(o_VGA_BLANK_N),
		.o_VGA_CLK(o_VGA_CLK)
	);

always_comb begin
	state_w = state_r;
	state_menu_w = state_menu_r;
	startI_w = startI_r;
	band_w = band_r;
	gain_w = gain_r;
	set_enable_w = set_enable_r;
	offset_w = offset_r;

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
			if(i_select) begin
				state_w = S_MENU;
				state_menu_w = S_EQ;
			end
		end

		S_MENU: begin
			if(i_up && state_menu_r < 2) begin
				state_menu_w = Menu_state'(state_menu_r + 1);
			end else if(i_down && state_menu_r > 0) begin
				state_menu_w = Menu_state'(state_menu_r - 1);
			end

			if(i_select) begin
				case(state_menu_r)
					S_EQ: begin
						state_w = S_BAND_SEL;
						band_w = 1;
					end
					S_OFFSET: begin
						state_w = S_SET_OFFSET;
					end
					S_RESET: begin
						state_w = S_RESET_DSP;
					end
				endcase
			end else if(i_back) begin
				state_w = S_IDLE;
			end
		end

		S_BAND_SEL: begin
			set_enable_w = 0;
			if(i_back) begin
				state_w = S_MENU;
				band_w = 0;
			end else if(i_select) begin
				state_w = S_SET_GAIN;
			end else if(i_up && band_r != nBand) begin
				band_w = band_r + 1;
			end else if(i_down && band_r != 0) begin
				band_w = band_r - 1;
			end

		end

		S_SET_GAIN: begin
			if(i_back || i_select) begin
				state_w = S_BAND_SEL;
				set_enable_w = 1;
			end else if (i_up) begin
				if(gain_r[band_r] <= 11 || gain_r[band_r][15] == 1) begin
					gain_w[band_r] = gain_r[band_r] + 1;
				end
			end else if (i_down) begin
				if(~gain_r[band_r] <= 10 || gain_r[band_r][15] == 0) begin
					gain_w[band_r] = gain_r[band_r] - 1;
				end
			end
		end

		S_SET_OFFSET: begin
			if(i_back || i_select) begin
				state_w = S_MENU;
			end
			if(i_down && offset_r < 3) begin
				offset_w = offset_r + 1;
			end else if(i_up && offset_r > 0) begin
				offset_w = offset_r - 1;
			end
		end

		S_RESET_DSP: begin
			state_w = S_MENU;
			gain_w = '0;
			offset_w = 0;
		end

	endcase

end

always_ff @(posedge i_clk or posedge i_rst) begin
	if(i_rst) begin
		state_r <= S_INIT;
		state_menu_r <= S_EQ;
		startI_r <= 1;
		band_r <= 0;
		gain_r <= '0;
		set_enable_r <= 0;
		offset_r <= 0;
	end else begin
		state_r <= state_w;
		state_menu_r <= state_menu_w;
		startI_r <= startI_w;
		band_r <= band_w;
		gain_r <= gain_w;
		set_enable_r <= set_enable_w;
		offset_r <= offset_w;
	end
end

endmodule
