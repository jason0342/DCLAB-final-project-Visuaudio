module DSP(
	input i_clk,
	input i_rst,
	input i_doneR,
	input [15:0] i_data,
	input [15:0] i_gain,
	input [2:0] i_set_gain, // choose biquad to set gain, 0: choose none
	output[15:0] o_data,
	output o_done
);

	parameter q_fp = 15; // Q15 fixed point
	parameter fix1 = 1<<q_fp;

	enum{ S_IDLE, S_RUN, S_DONE } state_r, state_w;

	logic[31:0] idat_r, idat_w, odat_r, odat_w;
	logic[4:0] count_r, count_w;
	logic done_r, done_w;
	logic[4:0][31:0] tmp;
	logic[15:0] odat_tmp;

	assign o_done = done_r;
	assign o_data = odat_tmp;

	Biquad #(f0 = 100)  (i_clk, i_rst, (i_set_gain == 1), i_gain, idat_r, tmp[0]);
	Biquad #(f0 = 200)  (i_clk, i_rst, (i_set_gain == 2), i_gain, tmp[0], tmp[1]);
	Biquad #(f0 = 400)  (i_clk, i_rst, (i_set_gain == 3), i_gain, tmp[1], tmp[2]);
	Biquad #(f0 = 800)  (i_clk, i_rst, (i_set_gain == 4), i_gain, tmp[2], tmp[3]);
	Biquad #(f0 = 1600) (i_clk, i_rst, (i_set_gain == 5), i_gain, tmp[3], tmp[4]);
	Biquad #(f0 = 3200) (i_clk, i_rst, (i_set_gain == 6), i_gain, tmp[4], odat_w);

always_comb begin
	state_w = state_r;
	idat_w = idat_r;
	odat_w = odat_r;
	done_w = done_r;
	count_w = count_r;

	// output overflow detection
	if(odat_r[31] && odat_r[31:q_fp] < {(17-q_fp){1'b1}, 15'b0}) begin
		odat_tmp[15] = 1;
		odat_tmp[14:0] = '0;
	end else if(!odat_r[31] && odat_r[31:q_fp] > {(17-q_fp){1'b0}, 15'b1}) begin
		odat_tmp[15] = 0;
		odat_tmp[14:0] = '1;
	end else begin
		odat_tmp = odat_r;
	end

	case(state_r)
		S_IDLE: begin
			done_w = 0;
			count_w = 0;
			if(i_doneR) begin
				idat_w[31:16+q_fp] = (i_data[15] == 1)? '1 : '0;
				idat_w[15+q_fp:q_fp] = i_data;
				idat_w[q_fp-1:0] = '0;
				state_w = S_RUN;
			end
		end

		S_RUN: begin
			if(count_r == 31) begin	// wait biquad calculate	
				done_w = 1;
				state_w = S_DONE;
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
