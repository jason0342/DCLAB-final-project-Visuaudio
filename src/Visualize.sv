module Visualize (
	input i_clk,
	input i_rst,
	input [10:0] i_VGA_X,
	input [10:0] i_VGA_Y,

	output [7:0] o_VGA_R,
	output [7:0] o_VGA_G, 
	output [7:0] o_VGA_B
	
);

	parameter PERIOD = 10000000;
	parameter CIRNUM = 25;
	parameter RAND_BIT = 25;

	assign o_VGA_R = CIRCLE_R;
	assign o_VGA_G = CIRCLE_G;
	assign o_VGA_B = CIRCLE_B;

	// Registers
	logic [31:0] count_r, count_w;
	logic [RAND_BIT:0] random_r, random_w;
	logic [CIRNUM-1:0][7:0] decade_r, decade_w;
	// Circle
	logic [CIRNUM-1:0][10:0] CENTER_X_r, CENTER_X_w;
	logic [CIRNUM-1:0][10:0] CENTER_Y_r, CENTER_Y_w;
	logic [CIRNUM-1:0][10:0] RADIUS_r, RADIUS_w;
	logic [CIRNUM-1:0][7:0] COLOR_R_r, COLOR_R_w;
	logic [CIRNUM-1:0][7:0] COLOR_G_r, COLOR_G_w;
	logic [CIRNUM-1:0][7:0] COLOR_B_r, COLOR_B_w;
	// Next circle's parameter
	logic [10:0] nextX_r, nextX_w;
	logic [10:0] nextY_r, nextY_w;
	logic [10:0] nextRAD_r, nextRAD_w;
	logic [7:0] nextR_r, nextR_w;
	logic [7:0] nextG_r, nextG_w;
	logic [7:0] nextB_r, nextB_w;

	// Wires
	logic [CIRNUM-1:0][7:0] INTER_CIRCLE_R, INTER_CIRCLE_G, INTER_CIRCLE_B;
	logic [CIRNUM-1:0] enableList;
	logic [CIRNUM-1:0][2:0] transList;
	logic [7:0] CIRCLE_R, CIRCLE_G, CIRCLE_B;
	logic [10:0] VGA_X, VGA_Y;

	Random #(.BIT(RAND_BIT)) rand_gen(
		.i_clk(clk),
		.i_rst(rst),
		.random(random_w)
	);

	LayerAdder #(.LAYERNUM(CIRNUM)) add(
		.i_LAYER_R(INTER_CIRCLE_R),
		.i_LAYER_G(INTER_CIRCLE_G),
		.i_LAYER_B(INTER_CIRCLE_B),
		.i_enableList(enableList),
		.i_transList(transList),
		.o_VGA_R(CIRCLE_R),
		.o_VGA_G(CIRCLE_G),
		.o_VGA_B(CIRCLE_B)
	);

	genvar i;
	generate
		for (i = 0; i < CIRNUM; i++) begin : gen_cir
			CircleRenderer cir(
				.i_center_X(CENTER_X_r[i]),
				.i_center_Y(CENTER_Y_r[i]),
				.i_radius(RADIUS_r[i]),
				.i_radius_off('0),
				.i_color_R(COLOR_R_r[i]),
				.i_color_G(COLOR_G_r[i]),
				.i_color_B(COLOR_B_r[i]),
				.i_VGA_X(i_VGA_X),
				.i_VGA_Y(i_VGA_Y),
				.o_VGA_R(INTER_CIRCLE_R[i]),
				.o_VGA_G(INTER_CIRCLE_G[i]),
				.o_VGA_B(INTER_CIRCLE_B[i]),
				.isEnable(enableList[i])
			);
		end
	endgenerate

	always_comb begin
		for (int i = 0; i < CIRNUM; i++) begin
			transList[i] = decade_r[i][7:5];
		end

		count_w = count_r + 1;
		CENTER_X_w = CENTER_X_r;
		CENTER_Y_w = CENTER_Y_r;
		RADIUS_w = RADIUS_r;
		COLOR_R_w = COLOR_R_r;
		COLOR_G_w = COLOR_G_r;
		COLOR_B_w = COLOR_B_r;
		nextX_w = nextX_r;
		nextY_w = nextY_r;
		nextRAD_w = nextRAD_r;
		nextR_w = nextR_r;
		nextG_w = nextG_r;
		nextB_w = nextB_r;
		decade_w = decade_r;

		// Decade the color
		if(count_r[19:0] == 1) begin
			for (int i = 0; i < CIRNUM; i++) begin
				if (decade_r[i] < 255) decade_w[i] = decade_r[i] + 1;
				if(COLOR_R_r[i] > 0) COLOR_R_w[i] = COLOR_R_r[i] - 1;
				if(COLOR_G_r[i] > 0) COLOR_G_w[i] = COLOR_G_r[i] - 1;
				if(COLOR_B_r[i] > 0) COLOR_B_w[i] = COLOR_B_r[i] - 1;
			end
		end

		// Update circles
		if(count_r[21:0] == 0) begin
			// Shift register and create new circle
			CENTER_X_w = {CENTER_X_r[CIRNUM-2:0], nextX_r};
			CENTER_Y_w = {CENTER_Y_r[CIRNUM-2:0], nextY_r};
			RADIUS_w = {RADIUS_r[CIRNUM-2:0], nextRAD_r};
			COLOR_R_w = {COLOR_R_r[CIRNUM-2:0], nextR_r};
			COLOR_G_w = {COLOR_G_r[CIRNUM-2:0], nextG_r};
			COLOR_B_w = {COLOR_B_r[CIRNUM-2:0], nextB_r};
			decade_w = {decade_r[CIRNUM-2:0], 8'b0};

			// Calculate the next circle
			if(random_r[9:0] >= 640) begin
				nextX_w = random_r[9:0] - 512;
			end else begin
				nextX_w = random_r[9:0];
			end
			if(random_r[18:10] >= 480) begin
				nextY_w = random_r[18:10] - 256;
			end else begin
				nextY_w = random_r[18:10];
			end

			nextRAD_w = 30 + random_r[25:19];

			if(nextX_w < 160) begin
				nextR_w = 255;
				nextG_w = (51 * nextX_w) >> 5;
				nextB_w = '0;
			end else if(nextX_w < 320) begin
				nextR_w = (51 * (319 - nextX_w)) >> 5;
				nextG_w = 255;
				nextB_w = '0;
			end else if(nextX_w < 480) begin
				nextR_w = '0;
				nextG_w = 255;
				nextB_w = (51 * (nextX_w - 320)) >> 5;
			end else begin
				nextR_w = '0;
				nextG_w = (51 * (639 - nextX_w)) >> 5;
				nextB_w = 255;
			end
		end
	end

always_ff @(posedge i_clk or posedge i_rst) begin
	if(i_rst) begin
		count_r <= '0;
		random_r <= '0;
		CENTER_X_r <= '0;
		CENTER_Y_r <= '0;
		RADIUS_r <= '0;
		COLOR_R_r <= '0;
		COLOR_G_r <= '0;
		COLOR_B_r <= '0;
		nextX_r <= '0;
		nextY_r <= '0;
		nextRAD_r <= '0;
		nextR_r <= '0;
		nextG_r <= '0;
		nextB_r <= '0;
		decade_r <= '0;
	end else begin
		count_r <= count_w;
		random_r <= random_w;
		CENTER_X_r <= CENTER_X_w;
		CENTER_Y_r <= CENTER_Y_w;
		RADIUS_r <= RADIUS_w;
		COLOR_R_r <= COLOR_R_w;
		COLOR_G_r <= COLOR_G_w;
		COLOR_B_r <= COLOR_B_w;
		nextX_r <= nextX_w;
		nextY_r <= nextY_w;
		nextRAD_r <= nextRAD_w;
		nextR_r <= nextR_w;
		nextG_r <= nextG_w;
		nextB_r <= nextB_w;
		decade_r <= decade_w;
	end
end

endmodule