module SpectrumRenderer (
	input [15:0][3:0] i_DATA,
	input [10:0] i_VGA_X,
	input [10:0] i_VGA_Y,
	output [7:0] o_VGA_R,
	output [7:0] o_VGA_G,
	output [7:0] o_VGA_B
);

	logic isShade;
	logic [7:0] VGA_R, VGA_G, VGA_B;
	logic [31:0] red, green, blue;
	logic [10:0] index, specY, relativeX, relativeY, heightY;

	assign o_VGA_R = isShade ? VGA_R >> 2 : VGA_R;
	assign o_VGA_G = isShade ? VGA_G >> 2 : VGA_G;
	assign o_VGA_B = isShade ? VGA_B >> 2 : VGA_B;

	parameter BLOCK_X = 40;
	parameter BLOCK_Y = 15;
	parameter PADDING_X = 3;
	parameter PADDING_Y = 2;

always_comb begin

	VGA_R = '0;
	VGA_G = '0;
	VGA_B = '0;
	heightY = '0;

	// Color calculations
	if(i_VGA_X < 160) begin
		red = 255;
		green = (51 * i_VGA_X) >> 5;
		blue = '0;
	end else if(i_VGA_X < 320) begin
		red = (51 * (319 - i_VGA_X)) >> 5;
		green = 255;
		blue = '0;
	end else if(i_VGA_X < 480) begin
		red = '0;
		green = 255;
		blue = (51 * (i_VGA_X - 320)) >> 5;
	end else begin
		red = '0;
		green = (51 * (639 - i_VGA_X)) >> 5;
		blue = 255;
	end

	// Location calculations
	if(i_VGA_Y < 240) begin
		heightY = 239 - i_VGA_Y;
		isShade = 0;
	end else begin
		heightY = i_VGA_Y - 240;
		isShade = 1;
	end
	index = 0;
	relativeY = 0;
	for (int i = 0; i < 16; i++) begin
		if(i_VGA_X > (i * BLOCK_X)) begin
			index = i;
		end
	end
	relativeX = i_VGA_X - (index * BLOCK_X);
	for (int i = 0; i < 16; i++) begin
		if(heightY > (i * BLOCK_Y)) begin
			relativeY = heightY - (i * BLOCK_Y);
		end
	end
	specY = (i_DATA[index] + 1) * BLOCK_Y;

	// Per pixel drawing
	if(relativeX >= PADDING_X && relativeX < BLOCK_X - PADDING_X && heightY >= PADDING_Y) begin
		if(heightY < specY) begin
			// Background halo (brightness * 0.5)
			VGA_R = red >> 1;
			VGA_G = green >> 1;
			VGA_B = blue >> 1;
			if(relativeY >= PADDING_Y && relativeY < BLOCK_Y - PADDING_Y) begin
				// Full color in blocks
				VGA_R = red;
				VGA_G = green;
				VGA_B = blue;
			end
		end else if(heightY < 25 + specY) begin
			// Background decade
			// 0.5 * (32 - x) / 32
			VGA_R = (red * (32 + specY - heightY)) >> 6;
			VGA_G = (green * (32 + specY - heightY)) >> 6;
			VGA_B = (blue * (32 + specY - heightY)) >> 6;
		end else if(heightY < 56 + specY) begin
			// Background decade
			// 0.125 * (32 + 24 - x) / 32
			VGA_R = (red * (56 + specY - heightY)) >> 8;
			VGA_G = (green * (56 + specY - heightY)) >> 8;
			VGA_B = (blue * (56 + specY - heightY)) >> 8;
		end
	end

end

endmodule