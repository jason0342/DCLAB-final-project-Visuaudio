module Biquad(
	input i_clk,
	input i_rst,
	input i_set,
	input[15:0] i_gain, // 16bit signed int 
	input[31:0] i_data, // fixed point
	output[31:0] o_data
);
	
	parameter f0 = 100;
	parameter fs = 32000;
	parameter q = 2;
	parameter pi = 3.1415926;

	parameter a1_r = int'(-2 * cos(2*pi*f0/fs) * 2**16); // covert to fixpoint
	parameter b1_r = a1_r;
	parameter alpha = int'(sin(2*pi*f0/fs) * 2**16 / (2*q));

	enum{ S_WAIT, S_SET } state_r, state_w;

	logic[3:0] count_r, count_w;
	logic[31:0] A_r, A_w;

	logic[31:0] a0_r, a2_r, b0_r, b2_r;
	logic[31:0] a0_w, a2_w, b0_w, b2_w;

	always_comb begin
		case(state_r)
			S_WAIT: begin
				if(i_set) begin
					state_w = S_SET;
					count_w = 0;
				end
			end

			S_SET: begin
				case(count_r) begin
					0: begin //calculate A

					end
					1: begin
					end
				endcase
			end
		endcase
	end

	always_ff @(posedge i_clk or posedge i_rst) begin
		if(i_rst) begin
		end else begin
		end
	end
