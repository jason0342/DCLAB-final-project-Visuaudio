`define SIN(x) (x - ((x)**3)/6 + ((x)**5)/120 + ((x)**7)/5040)
`define COS(x) (1 - ((x)**2)/2 + ((x)**4)/24 - ((x)**6)/720)

module Biquad(
	input i_clk,
	input i_rst,
	input i_set,
	input i_next,
	input[15:0] i_gain, // 16bit signed int
	input[31:0] i_data, // fixed point
	output[31:0] o_data
);

	parameter q_fp = 15; // Q15 fixed point
	parameter fix1 = 1<<q_fp;

	parameter f0 = 100; //central freq, to be set
	parameter fs = 32000; // sample freq
	parameter q = 2; // Q factor
	parameter pi = 3.1415926;

	parameter integer alpha = `SIN(2*pi*f0/fs) * fix1 / (2*q);
	parameter integer a1_r = -2 * `COS(2*pi*f0/fs) * fix1; // 2^Q covert to fixpoint
	parameter b1_r = a1_r;

	//coeff. for 10^(gain/40) approx. , c0 + c1x + c2x^2, c3 + c4x + c5x^2
	parameter c0 = int'(1.0120 * fix1);
	parameter c1 = int'(0.0464 * fix1);
	parameter c2 = int'(0.0030 * fix1);
	parameter c3 = int'(0.9950 * fix1);
	parameter c4 = int'(0.0529 * fix1);
	parameter c5 = int'(0.00096* fix1);

	enum{ S_WAIT, S_SET } set_state_r, set_state_w;
	enum{ S_IDLE, S_NEXT } run_state_r, run_state_w;

	logic[3:0] count_r, count_w;
	logic[31:0] g_r, g_w; // gain
	logic[31:0] A_r, A_w; // A = 10^(gain/40)
	logic[31:0] Ainv_r, Ainv_w; // A^-1

	logic[31:0] a0inv_r, a2_r, b0_r, b2_r;
	logic[31:0] a0inv_w, a2_w, b0_w, b2_w;

	logic[31:0] x0_r, x1_r, x2_r, y1_r, y2_r;
	logic[31:0] x0_w, x1_w, x2_w, y1_w, y2_w;

	logic[23:0][31:0] tmp;

	// calculate A, A^-1
	qmul mul0(g_r, g_r, tmp[0]);
	qmul mul1(c2, tmp[0], tmp[1]);
	qmul mul2(c1, (g_r[31] == 0) ? g_r : ~g_r+1, tmp[2]);
	qadd add0(c0, tmp[2], tmp[3]);
	qadd add1(tmp[1], tmp[3], tmp[4]);
	qmul mul3(c5, tmp[0], tmp[5]);
	qmul mul4(c4, (g_r[31] == 0) ? ~g_r+1 : g_r, tmp[6]);
	qadd add2(c3, tmp[6], tmp[7]);
	qadd add3(tmp[5], tmp[7], tmp[8]);

	// calculate a2, b0, b2
	qmul mul20(alpha, A_r, tmp[9]); // alpha*A
	qmul mul21(alpha, Ainv_r, tmp[10]); // alpha*A^-1
	qadd add20(fix1, tmp[9], tmp[11]); // b0
	qadd add21(fix1, ~tmp[9]+1, tmp[12]); // b2
	qadd add22(fix1, ~tmp[10]+1, tmp[13]); // a2, a0^-1

	// biquad filter
	qmul mul30(b0_r, x0_r, tmp[14]);
	qmul mul31(b1_r, x1_r, tmp[15]);
	qmul mul32(b2_r, x2_r, tmp[16]);
	qmul mul33(a1_r, y1_r, tmp[17]);
	qmul mul34(a2_r, y2_r, tmp[18]);
	qadd add30(tmp[14], tmp[15], tmp[19]);
	qadd add31(tmp[17], tmp[18], tmp[20]);
	qadd add32(tmp[16], tmp[19], tmp[21]);
	qadd add33(tmp[21], ~tmp[20]+1, tmp[22]);
	qmul mul35(a2_r, tmp[22], tmp[23]);

	assign o_data = tmp[23];

	always_comb begin
		set_state_w = set_state_r;
		run_state_w = run_state_r;
		count_w = count_r;
		g_w = g_r;
		A_w = A_r;
		Ainv_w = Ainv_r;
		a2_w = a2_r;
		b0_w = b0_r;
		b2_w = b2_r;
		x0_w = x0_r;
		x1_w = x1_r;
		x2_w = x2_r;
		y1_w = y1_r;
		y2_w = y2_r;

		case(run_state_r)
			S_IDLE: begin
				if(i_next) begin
					run_state_w = S_NEXT;
				end
			end
			S_NEXT: begin
				if(!i_next) begin
					x0_w = i_data;
					x1_w = x0_r;
					x2_w = x1_r;
					y1_w = tmp[23];
					y2_w = y1_r;
					run_state_w = S_IDLE;
				end
			end
		endcase

		// calculate and set coeffs
		case(set_state_r)
			S_WAIT: begin
				if(i_set) begin
					set_state_w = S_SET;
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
							Ainv_w = 1<<q_fp;
						end else if(g_r[31] == 0) begin
							A_w = tmp[4];
							Ainv_w = tmp[8];
						end else begin
							A_w = tmp[8];
							Ainv_w = tmp[4];
						end
					end
					1: begin //calculate a2, b0, b2
						b0_w = tmp[11];
						b2_w = tmp[12];
						a2_w = tmp[13];
					end
					2: begin 
						set_state_w = S_WAIT;
					end
					default: begin
					end
				endcase
				count_w = count_r + 1;
			end
		endcase
	end

	always_ff @(posedge i_clk or posedge i_rst) begin
		if(i_rst) begin
			set_state_r <= S_WAIT;
			run_state_r <= S_IDLE;
			count_r <= 0;
			A_r <= fix1;
			Ainv_r <= fix1;
			g_r <= 0;
			a2_r <= 0;
			b0_r <= fix1;
			b2_r <= 0;
			x0_r <= 0;
			x1_r <= 0;
			x2_r <= 0;
			y1_r <= 0;
			y2_r <= 0;
		end else begin
			set_state_r <= set_state_w;
			run_state_r <= run_state_w;
			count_r <= count_w;
			A_r <= A_w;
			Ainv_r <= Ainv_w;
			g_r <= g_w;
			a2_r <= a2_w;
			b0_r <= b0_w;
			b2_r <= b2_w;
			x0_r <= x0_w;
			x1_r <= x1_w;
			x2_r <= x2_w;
			y1_r <= y1_w;
			y2_r <= y2_w;
		end
	end

endmodule
