module DACcontroller(
	// parameters
	input i_play,
	input i_intpol,
	input [19:0] i_start_pos,
	input [19:0] i_end_pos,
	// Chip wires
	input i_DACLRCK,
	input i_BCLK,
	input [15:0] i_SRAM_DATA,

	output o_SRAM_OE,
	output [19:0] o_SRAM_ADDR,
	output o_DACDAT,
	output o_done,

	output [2:0] o_state
);

	typedef enum {
		S_IDLE,
		S_READ,
		S_WAIT,
		S_WRITE_LEFT,
		S_WRITE_RIGHT,
		S_DONE
	} State;

	State state_r, state_w;
	logic [19:0] position_r, position_w;
	logic [31:0] next_data_r, next_data_w;
	logic [31:0] curr_data_r, curr_data_w;
	logic [3:0] bitnum_r, bitnum_w;
	logic done_r, done_w;
	logic pre_LRCLK_r, pre_LRCLK_w;
	logic dacdat_r, dacdat_w;
	logic pre_fetched_r, pre_fetched_w;

	logic is_intpo_r, is_intpo_w;
	logic intpo_next_r, intpo_next_w;
	logic intpo_reset_r, intpo_reset_w;
	logic [31:0] i_intpol_dat;
	logic [2:0] intpo_num_r, intpo_num_w;

	IntPol intpo(
		.i_bclk(i_BCLK),
		.i_next(intpo_next_r),
		.i_reset(intpo_reset_r),
		.i_intpol(i_intpol),
		.i_speed(i_speed[2:0]),
		.i_prev_dat(curr_data_r),
		.i_dat(next_data_r),
		.o_intpol_dat(i_intpol_dat)
	);

	assign o_SRAM_OE = (state_r != S_READ);
	assign o_SRAM_ADDR = position_r;
	assign o_DACDAT = dacdat_r;
	assign o_done = done_r;
	assign o_state = state_r;

	always_ff @( posedge i_BCLK ) begin 
		pre_LRCLK_r <= pre_LRCLK_w;
		position_r <= position_w;
		state_r <= state_w;
		next_data_r <= next_data_w;
		curr_data_r <= curr_data_w;
		bitnum_r <= bitnum_w;
		done_r <= done_w;
		dacdat_r <= dacdat_w;
		pre_fetched_r <= pre_fetched_w;
		is_intpo_r <= is_intpo_w;
		intpo_next_r <= intpo_next_w;
		intpo_reset_r <= intpo_reset_w;
		intpo_num_r <= intpo_num_w;
	end
	
	always_comb begin
		pre_LRCLK_w = i_DACLRCK;
		position_w = position_r;
		state_w = state_r;
		next_data_w = next_data_r;
		curr_data_w = curr_data_r;
		bitnum_w = bitnum_r;
		done_w = done_r;
		dacdat_w = dacdat_r;
		pre_fetched_w = pre_fetched_r;
		is_intpo_w = is_intpo_r;
		intpo_next_w = intpo_next_r;
		intpo_reset_w = intpo_reset_r;
		intpo_num_w = intpo_num_r;

		case (state_r)
			S_IDLE: begin 
				pre_fetched_w = 0;
				is_intpo_w = 0;
				position_w = i_start_pos;
				done_w = 0;
				bitnum_w = 0;
				intpo_next_w = 0;
				intpo_reset_w = 0;
				intpo_num_w = 0;
				if(i_play) begin
					state_w = S_READ;
				end
			end

			S_READ: begin 
				pre_fetched_w = 1;  // After the first fetch, it is fetched
				is_intpo_w = 0;  // The first time is not interpolated signal
				intpo_num_w = i_speed[2:0];  // Set interpolated signal to #times
				intpo_reset_w = 1;  // Reset interpolation after new data is available

				// Read in data next -> curr, sram -> curr
				curr_data_w = next_data_r;
				next_data_w[15:0] = i_SRAM_DATA;
				next_data_w[31:16] = i_SRAM_DATA;

				if(pre_fetched_r) state_w = S_WAIT;  // Wait for lrclk edge to start writing data
				else begin
					state_w = S_READ; // Read again if not pre-fetched
					intpo_reset_w = 0; // Reset should only happen when all data is fetched
				end

				if(i_speed[3])		position_w = position_r + 1;  // Slow down shall always read the next one
				else				position_w = position_r + i_speed[2:0] + 1;  // Speed up will skip

				// Terminate condition
				if((position_r >= i_end_pos - i_speed[2:0] - 1) && pre_fetched_r) begin
					done_w = 1;
					state_w = S_DONE;
					position_w = position_r - i_speed[2:0] - 1;
				end
			end

			S_WAIT: begin
				bitnum_w = 0;  // Start from first bit again
				intpo_next_w = 0; // Stop the next interpolation signal in the next clock
				intpo_reset_w = 0;  // Stop the reset

				if(pre_LRCLK_r == 1 && i_DACLRCK == 0)		state_w = S_WRITE_LEFT;
				else if(pre_LRCLK_r == 0 && i_DACLRCK == 1)	state_w = S_WRITE_RIGHT;
				if(is_intpo_r && intpo_num_r == 0) state_w = S_READ;
			end

			S_WRITE_LEFT: begin 
				if(i_play == 0) begin 
					state_w = S_IDLE;
				end else begin
					if(is_intpo_r) begin
						dacdat_w = i_intpol_dat[bitnum_r];
						bitnum_w = bitnum_r + 1;
						if(bitnum_r == 15) state_w = S_WAIT;
					end else begin 
						dacdat_w = curr_data_r[bitnum_r];
						bitnum_w = bitnum_r + 1;
						if(bitnum_r == 15) state_w = S_WAIT;
					end
				end
			end

			S_WRITE_RIGHT: begin 
				if(i_play == 0) begin 
					state_w = S_IDLE;
				end else begin
					if(is_intpo_r) begin
						dacdat_w = i_intpol_dat[16 + bitnum_r];
						bitnum_w = bitnum_r + 1;
						if(bitnum_r == 15) begin
							intpo_num_w = intpo_num_r - 1; // Update the interpolation number
							intpo_next_w = 1; // Request the next interpolation signal
							state_w = S_WAIT;
						end
					end else begin 
						dacdat_w = curr_data_r[16 + bitnum_r];
						bitnum_w = bitnum_r + 1;
						if(bitnum_r == 15) begin
							if (i_speed[3]) begin
								is_intpo_w = 1; // Starting from the next loop, it is interpolated signal
								intpo_next_w = 1; // Request the next interpolation signal
								state_w = S_WAIT;
							end else begin
								state_w = S_READ;
							end
						end
					end
				end
			end
		
			S_DONE: begin 
				state_w = S_IDLE;
			end
		endcase
	end

endmodule
