module DSP(
	input i_clk,
	input i_rst,
	input i_doneR,
	input [15:0] i_data,
	input [15:0] i_gain,
	input [2:0] i_set_gain, // choose biquad to set gain, 0: choose none
	input i_set_enable,
	input [2:0] i_offset,
	output[15:0] o_data,
	output o_done
);

	parameter q_fp = 15; // Q15 fixed point
	parameter fix1 = 1<<q_fp;
	parameter pre_offset = 2; // -6dB offset to avoid saturation

	enum{ S_IDLE, S_RUN, S_DONE } state_r, state_w;

	logic[31:0] idat_r, idat_w, odat_r, odat_w;
	logic[4:0] count_r, count_w;
	logic done_r, done_w;
	logic[5:0][31:0] tmp;
	logic[15:0] odat_tmp;
	logic signed [31:0] idat_tmp, idat_tmp2;

	assign o_done = done_r;
	assign o_data = odat_tmp;
	// assign o_data = i_data;

	Biquad #(.f0(100))  biquad1(i_clk, i_rst, (i_set_gain == 1), i_doneR, i_gain, idat_r, tmp[5]);
	// Biquad #(.f0(200))  biquad2(i_clk, i_rst, (i_set_gain == 2), i_doneR, i_gain, tmp[0], tmp[1]);
	// Biquad #(.f0(400))  biquad3(i_clk, i_rst, (i_set_gain == 3), i_doneR, i_gain, tmp[1], tmp[2]);
	// Biquad #(.f0(800))  biquad4(i_clk, i_rst, (i_set_gain == 4), i_doneR, i_gain, tmp[2], tmp[3]);
	// Biquad #(.f0(1600)) biquad5(i_clk, i_rst, (i_set_gain == 5), i_doneR, i_gain, tmp[3], tmp[4]);
	// Biquad #(.f0(3200)) biquad6(i_clk, i_rst, (i_set_gain == 6), i_doneR, i_gain, tmp[4], tmp[5]);
	// Biquad #(.f0(400)) biquad0(i_clk, i_rst, (i_set_gain == 3 && i_set_enable), i_doneR, i_gain, idat_r, tmp[5]);

always_comb begin
	state_w = state_r;
	idat_w = idat_r;
	odat_w = odat_r;
	done_w = done_r;
	count_w = count_r;

	idat_tmp = '0;
	idat_tmp[31:16] = i_data;

	case(i_offset) 
		0: begin
			idat_tmp2 = idat_tmp >>> (16 - q_fp + pre_offset);
		end
		1: begin
			// idat_tmp = i_data >> 1;
			// idat_tmp[15] = i_data[15];
			idat_tmp2 = idat_tmp >>> (16 - q_fp + pre_offset + 1);
		end
		2: begin
			// idat_tmp = i_data >> 2;
			// idat_tmp[15:14] = {2{i_data[15]}};
			idat_tmp2 = idat_tmp >>> (16 - q_fp + pre_offset + 2);
		end
		3: begin
			// idat_tmp = i_data >> 3;
			// idat_tmp[15:13] = {3{i_data[15]}};
			idat_tmp2 = idat_tmp >>> (16 - q_fp + pre_offset + 3);
		end
		4: begin
			// idat_tmp = i_data >> 4;
			// idat_tmp[15:12] = {4{i_data[15]}};
			idat_tmp2 = idat_tmp >>> (16 - q_fp + pre_offset + 4);
		end
		default: begin
			idat_tmp2 = idat_tmp >>> (16 - q_fp + pre_offset);
		end
	endcase

	// output overflow detection
	// if(odat_r[31] && odat_r[31:q_fp] < {{(17-q_fp){1'b1}}, {15{1'b0}}}) begin
	// 	odat_tmp[15] = 1;
	// 	odat_tmp[14:0] = '0;
	// end else if(!odat_r[31] && odat_r[31:q_fp] > {{(17-q_fp){1'b0}}, {15{1'b1}}}) begin
	// 	odat_tmp[15] = 0;
	// 	odat_tmp[14:0] = '1;
	// end else begin
	// 	odat_tmp = odat_r[q_fp+15:q_fp];
	// end
	odat_tmp = odat_r[q_fp+15:q_fp] << pre_offset;

	case(state_r)
		S_IDLE: begin
			done_w = 0;
			count_w = 0;
			if(i_doneR) begin
				idat_w = idat_tmp2;
				// idat_w[31:16+q_fp] = (idat_tmp[15] == 1)? '1 : '0;
				// idat_w[15+q_fp:q_fp] = idat_tmp;
				// idat_w[q_fp-1:0] = '0;
				state_w = S_RUN;
			end
		end

		S_RUN: begin
			if(count_r == 31) begin	// wait biquad calculate	
				done_w = 1;
				state_w = S_DONE;
				odat_w = tmp[5];
			end
			count_w = count_r + 1;
		end

		S_DONE: begin
			state_w = S_IDLE;
		end

	endcase

end

always_ff @(posedge i_clk or posedge i_rst) begin
	if(i_rst) begin
		idat_r <= 0;
		odat_r <= 0;
		count_r <= 0;
		state_r <= S_IDLE;
		done_r <= 0;
	end else begin
		idat_r <= idat_w;
		odat_r <= odat_w;
		count_r <= count_w;
		state_r <= state_w;
		done_r <= done_w;
	end
end

endmodule // DSP