module SevenHexDecoder(
	// input [4:0] timer,
	input [2:0] i_state,
	input [2:0] i_menu_state,
	input [2:0] i_band,
	input [31:0] i_gain,
	input [2:0] i_offset,
	input i_play_enable,
	// input [1:0] speedStat,
	// input [3:0] speed,
	// input [1:0] iniState,
	// input [1:0] recState,
	// input [2:0] playState,
	// input [15:0] i_sram_data,
	// input [3:0] speedtoDac,
	output logic [6:0] o_s0,
	output logic [6:0] o_s1,
	output logic [6:0] o_s2,
	output logic [6:0] o_s3,
	output logic [6:0] o_s4,
	output logic [6:0] o_s5,
	output logic [6:0] o_s6,
	output logic [6:0] o_s7
);
	/* The layout of seven segment display, 1: dark
	 *    00
	 *   5  1
	 *    66
	 *   4  2
	 *    33
	 */
	parameter D0 = 7'b1000000;
	parameter D1 = 7'b1111001;
	parameter D2 = 7'b0100100;
	parameter D3 = 7'b0110000;
	parameter D4 = 7'b0011001;
	parameter D5 = 7'b0010010;
	parameter D6 = 7'b0000010;
	parameter D7 = 7'b1011000;
	parameter D8 = 7'b0000000;
	parameter D9 = 7'b0010000;
	parameter A  = 7'b0001000;
	parameter B  = 7'b0000011;
	parameter C  = 7'b1000110;
	parameter D  = 7'b0100001;
	parameter E  = 7'b0000110;
	parameter F  = 7'b0001110;
	parameter H  = 7'b0001001;
	parameter L  = 7'b1000111;
	parameter N  = 7'b0101011;
	parameter O  = 7'b0100011;
	parameter P  = 7'b0001100;
	parameter Q  = 7'b0011000;
	parameter R  = 7'b1001110;
	parameter S  = 7'b0010010;
	parameter T  = 7'b1111000;
	parameter U  = 7'b1000001;
	parameter Y  = 7'b0010001;
	parameter NE = 7'b0111111;
	parameter DK = 7'b1111111;

	always_comb begin
		o_s0 = DK;
		o_s1 = DK;
		o_s2 = DK;
		o_s3 = DK;
		o_s4 = DK;
		o_s5 = DK;
		o_s6 = DK;
		o_s7 = DK;

		case(i_state)
			0: begin
				o_s2 = D1;
				o_s1 = N;
				o_s0 = D1;
			end

			1: begin
				if(i_play_enable) begin
					o_s3 = P;
					o_s2 = L;
					o_s1 = A;
					o_s0 = Y;
				end else begin
					o_s7 = D1;
					o_s6 = D0;
					o_s5 = L;
					o_s4 = E;
				end
			end

			2: begin
				case(i_menu_state)
					0: begin
						o_s1 = E;
						o_s0 = Q;
					end

					1: begin
						o_s5 = D0;
						o_s4 = F;
						o_s3 = F;
						o_s2 = S;
						o_s1 = E;
						o_s0 = T;
					end

					2: begin
						o_s4 = R;
						o_s3 = E;
						o_s2 = S;
						o_s1 = E;
						o_s0 = T;
					end
				endcase
			end

			3: begin
				o_s1 = H;
				o_s0 = D2;
				o_s5 = D0;
				o_s4 = D0;
				case(i_band)
					1: begin
						o_s6 = D1;
					end

					2: begin
						o_s6 = D2;
					end

					3: begin
						o_s6 = D4;
					end

					4: begin
						o_s6 = D8;
					end

					5: begin
						o_s7 = D1;
						o_s6 = D6;
					end

					6: begin
						o_s7 = D3;
						o_s6 = D2;
					end

					default: begin end
				endcase
			end

			4: begin
				o_s1 = D;
				o_s0 = B;
				case(i_gain)
					0: begin o_s4 = D0; end
					1: begin o_s4 = D1; end
					2: begin o_s4 = D2; end
					3: begin o_s4 = D3; end
					4: begin o_s4 = D4; end
					5: begin o_s4 = D5; end
					6: begin o_s4 = D6; end
					7: begin o_s4 = D7; end
					8: begin o_s4 = D8; end
					9: begin o_s4 = D9; end
					10: begin o_s5 = D1; o_s4 = D0; end
					11: begin o_s5 = D1; o_s4 = D1; end
					12: begin o_s5 = D1; o_s4 = D2; end
					default: begin end
				endcase
				case(~i_gain+1)
					1: begin o_s5 = NE; o_s4 = D1; end
					2: begin o_s5 = NE; o_s4 = D2; end
					3: begin o_s5 = NE; o_s4 = D3; end
					4: begin o_s5 = NE; o_s4 = D4; end
					5: begin o_s5 = NE; o_s4 = D5; end
					6: begin o_s5 = NE; o_s4 = D6; end
					7: begin o_s5 = NE; o_s4 = D7; end
					8: begin o_s5 = NE; o_s4 = D8; end
					9: begin o_s5 = NE; o_s4 = D9; end
					10: begin o_s6 = NE; o_s5 = D1; o_s4 = D0; end
					11: begin o_s6 = NE; o_s5 = D1; o_s4 = D1; end
					12: begin o_s6 = NE; o_s5 = D1; o_s4 = D2; end
					default: begin end
				endcase
			end

			5: begin
				o_s1 = D;
				o_s0 = B;
				o_s5 = NE;
				case(i_offset)
					0: begin o_s5 = DK; o_s4 = D0; end
					1: begin o_s4 = D3; end
					2: begin o_s4 = D6; end
					3: begin o_s4 = D9; end
					4: begin o_s4 = D1; o_s3 = D2; end
					default: begin end
				endcase
			end
			default: begin end
		endcase
	end
endmodule
