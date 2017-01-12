module DACcontroller(
	// parameters
	input i_play,
	input i_valid,
	// Chip wires
	input i_DACLRCK,
	input i_BCLK,
	input [15:0] i_DATA,

	output o_DACDAT
);

	typedef enum {
		S_READ,
		S_WAIT,
		S_WRITE_LEFT,
		S_WRITE_RIGHT
	} State;

	State state_r, state_w;
	logic [31:0] data_r, data_w;
	logic [3:0] bitnum_r, bitnum_w;
	logic pre_LRCLK_r, pre_LRCLK_w;
	logic dacdat_r, dacdat_w;

	assign o_DACDAT = (i_play) ? dacdat_r : 0;

	always_ff @( posedge i_BCLK ) begin 
		pre_LRCLK_r <= pre_LRCLK_w;
		state_r <= state_w;
		data_r <= data_w;
		bitnum_r <= bitnum_w;
		dacdat_r <= dacdat_w;
	end
	
	always_comb begin
		pre_LRCLK_w = i_DACLRCK;
		state_w = state_r;
		data_w = data_r;
		bitnum_w = bitnum_r;
		dacdat_w = dacdat_r;

		case (state_r)
			S_READ: begin
				if(i_valid) begin
					state_w = S_WAIT;
					// Read in data
					data_w[15:0] = i_DATA;
					data_w[31:16] = i_DATA;
				end
			end

			S_WAIT: begin
				bitnum_w = 0;  // Start from first bit again
				if(pre_LRCLK_r == 1 && i_DACLRCK == 0) begin
					dacdat_w = data_r[15];
					bitnum_w = bitnum_r + 1;
					state_w = S_WRITE_LEFT;
				end else if(pre_LRCLK_r == 0 && i_DACLRCK == 1)	begin
					dacdat_w = data_r[31];
					bitnum_w = bitnum_r + 1;
					state_w = S_WRITE_RIGHT;
				end
			end

			S_WRITE_LEFT: begin 
				dacdat_w = data_r[15 - bitnum_r];
				bitnum_w = bitnum_r + 1;
				if(bitnum_r == 15) state_w = S_WAIT;
			end

			S_WRITE_RIGHT: begin
				dacdat_w = data_r[31 - bitnum_r];
				bitnum_w = bitnum_r + 1;
				if(bitnum_r == 15) state_w = S_READ;
			end
		
		endcase
	end

endmodule
