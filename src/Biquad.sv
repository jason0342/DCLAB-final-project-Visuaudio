module Biquad(
	input i_clk,
	input i_rst,
	input i_set,
	input[15:0] i_gain, // 16bit signed int
	input[31:0] i_data, // fixed point
	output[31:0] o_data
);

	parameter q_fp = 15; // Q15 fixed point

	parameter f0 = 100; //central freq, to be set
	parameter fs = 32000; // sample freq
	parameter q = 2; // Q factor
	parameter pi = 3.1415926;

	parameter int a1_r = -2 * $cos(2*pi*f0/fs) * (1<<q_fp); // 2^Q covert to fixpoint
	parameter b1_r = a1_r;
	parameter int alpha = $sin(2*pi*f0/fs) * (1<<q_fp) / (2*q);

	//coeff. for 10^(gain/40) approx. , c0 + c1x + c2x^2, c3 + c4x + c5x^2
	parameter c0 = int'(1.0120 * (1<<q_fp));
	parameter c1 = int'(0.0464 * (1<<q_fp));
	parameter c2 = int'(0.0030 * (1<<q_fp));
	parameter c3 = int'(0.9950 * (1<<q_fp));
	parameter c4 = int'(0.0529 * (1<<q_fp));
	parameter c5 = int'(0.00096* (1<<q_fp));

	enum{ S_WAIT, S_SET } state_r, state_w;

	logic[3:0] count_r, count_w;
	logic[31:0] g_r, g_w; // gain
	logic[31:0] A_r, A_w; // 10^(gain/40)

	logic[31:0] a0_r, a2_r, b0_r, b2_r;
	logic[31:0] a0_w, a2_w, b0_w, b2_w;

	logic[8:0][31:0] tmp;

	// calculate A
	qmul mul0(g_r, g_r, tmp[0]);
	qmul mul1(c2, tmp[0], tmp[1]);
	qmul mul2(c1, g_r, tmp[2]);
	qadd add0(c0, tmp[2], tmp[3]);
	qadd add1(tmp[1], tmp[3], tmp[4]);
	qmul mul3(c5, tmp[0], tmp[5]);
	qmul mul4(c4, g_r, tmp[6]);
	qadd add2(c3, tmp[6], tmp[7]);
	qadd add3(tmp[5], tmp[7], tmp[8]);

	always_comb begin
		case(state_r)
			S_WAIT: begin
				if(i_set) begin
					state_w = S_SET;
					count_w = 0;
					g_w[31:16+q_fp] = (i_gain[15] == 1)? '1 : '0;
					g_w[15+q_fp:q_fp] = i_gain;
					g_w[q_fp-1:0] = '0;
				end
			end

			S_SET: begin
				case(count_r)
					0: begin //calculate A
						if(g_r == 0) begin
							A_w = 1<<q_fp;
						end else if(g_r[31] == 0) begin
							A_w = tmp[4];
						end else begin
							A_w = tmp[8];
						end
					end
					1: begin
					end
				endcase
				count_w = count_r + 1;
			end
		endcase
	end

	always_ff @(posedge i_clk or posedge i_rst) begin
		if(i_rst) begin
			state_r <= S_WAIT;
			count_r <= 0;
			A_r <= 1;
			g_r <= 0;
		end else begin
			state_r <= state_w;
			count_r <= count_w;
			A_r <= A_w;
			g_r <= g_w;
		end
	end

endmodule
