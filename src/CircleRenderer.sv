module CircleRenderer (
	input [10:0] i_center_X,
	input [10:0] i_center_Y,
	input [10:0] i_radius,
	input [4:0] i_radius_off,
	input [7:0] i_color_R,
	input [7:0] i_color_G,
	input [7:0] i_color_B,
	input [10:0] i_VGA_X,
	input [10:0] i_VGA_Y,
	output [7:0] o_VGA_R,
	output [7:0] o_VGA_G,
	output [7:0] o_VGA_B,
	output isEnable
);

	logic [31:0] distance;

always_comb begin
	o_VGA_R = '0;
	o_VGA_G = '0;
	o_VGA_B = '0;
	isEnable = '0;

	distance = (i_VGA_X - i_center_X) ** 2 + (i_VGA_Y - i_center_Y) ** 2;
	if(distance <= (i_radius + i_radius_off) ** 2) begin
		o_VGA_R = i_color_R;
		o_VGA_G = i_color_G;
		o_VGA_B = i_color_B;
		isEnable = '1;
	end

end

endmodule