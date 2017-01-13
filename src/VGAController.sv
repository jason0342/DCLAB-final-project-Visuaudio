module VGA_Controller(
	// Control Signal
	input  i_clk,
	input  i_reset,
	// Host Side
	output [10:0] o_VGA_X,
	output [10:0] o_VGA_Y,
	// VGA_Side
	output o_VGA_HS,
	output o_VGA_VS,
	output o_VGA_SYNC_N,
	output o_VGA_BLANK_N,
	output o_VGA_CLK
);

	// Horizontal Parameter
	parameter H_FRONT = 16;   //44;   //16
	parameter H_SYNC  = 96;   //108;  //96
	parameter H_BACK  = 48;   //249;  //48
	parameter H_ACT   = 640;  //1280; //640

	// Vertical Parameter
	parameter V_FRONT = 10;   //1;    //10
	parameter V_SYNC  = 2;    //3;    //2
	parameter V_BACK  = 33;   //38;   //33
	parameter V_ACT   = 480;  //1024; //480

	// Select DAC clock
	assign o_VGA_SYNC_N  = 1'b0;        // This pin is unused.
	assign o_VGA_BLANK_N = ~((h_state_r != S_HDISPLAY) || (v_state_r != S_VDISPLAY));
	assign o_VGA_CLK   = ~i_clk;
	assign o_VGA_HS = (h_state_r != S_HSYNC);
	assign o_VGA_VS = (v_state_r != S_VSYNC);
	assign o_VGA_X = x_r;
	assign o_VGA_Y = y_r;

	typedef enum {
			S_HFRONT,
			S_HSYNC,
			S_HBACK,
			S_HDISPLAY,
			S_VFRONT,
			S_VSYNC,
			S_VBACK,
			S_VDISPLAY
	} State;
	
	State h_state_r, h_state_w;
	State v_state_r, v_state_w;
	logic [10:0] h_count_r, h_count_w;
	logic [10:0] v_count_r, v_count_w;
	logic [10:0] x_r, x_w;
	logic [10:0] y_r, y_w;

	always_ff @(posedge i_clk or posedge i_reset) begin
		if(i_reset) begin
			h_state_r <= S_HFRONT;
			h_count_r <= 0;
			x_r <= 0;
		end else begin
			h_state_r <= h_state_w;
			h_count_r <= h_count_w;
			x_r <= x_w;
		end
	end

	always_ff @(posedge o_VGA_HS or posedge i_reset) begin
		if(i_reset) begin
			v_state_r <= S_VFRONT;
			v_count_r <= 0;
			y_r <= 0;
		end else begin
			v_state_r <= v_state_w;
			v_count_r <= v_count_w;
			y_r <= y_w;
		end
	end

	always_comb begin
		// Default values
		h_state_w = h_state_r;
		v_state_w = v_state_r;
		h_count_w = h_count_r + 1;
		v_count_w = v_count_r + 1;
		x_w = x_r;
		y_w = y_r;

		case (h_state_r)
			S_HFRONT: begin
				if(h_count_r == H_FRONT - 1) begin
					h_count_w = 0;
					h_state_w = S_HSYNC;
				end
			end
			S_HSYNC: begin
				if(h_count_r == H_SYNC - 1) begin
					h_count_w = 0;
					h_state_w = S_HBACK;
				end
			end
			S_HBACK: begin
				if(h_count_r == H_BACK - 1) begin
					h_count_w = 0;
					h_state_w = S_HDISPLAY;
				end
			end
			S_HDISPLAY: begin
				x_w = x_r + 1;
				if(h_count_r == H_ACT - 1) begin
					h_count_w = 0;
					x_w = 0;
					h_state_w = S_HFRONT;
				end
			end
		endcase

		case (v_state_r)
			S_VFRONT: begin
				if(v_count_r == V_FRONT - 1) begin
					v_count_w = 0;
					v_state_w = S_VSYNC;
				end
			end
			S_VSYNC: begin
				if(v_count_r == V_SYNC - 1) begin
					v_count_w = 0;
					v_state_w = S_VBACK;
				end
			end
			S_VBACK: begin
				if(v_count_r == V_BACK - 1) begin
					v_count_w = 0;
					v_state_w = S_VDISPLAY;
				end
			end
			S_VDISPLAY: begin
				y_w = y_r + 1;
				if(v_count_r == V_ACT - 1) begin
					v_count_w = 0;
					y_w = 0;
					v_state_w = S_VFRONT;
				end
			end
		endcase
	end
	
endmodule
