module BubbleRenderer (
	input i_clk,
	input i_rst,
	input [15:0][3:0] i_DATA,
	input [10:0] i_VGA_X,
	input [10:0] i_VGA_Y,
	input [4:0] i_radius_off,

	output [7:0] o_VGA_R,
	output [7:0] o_VGA_G, 
	output [7:0] o_VGA_B
	
);

	parameter PERIOD = 10000000;
	parameter CIRNUM = 28;
	parameter RAND_BIT = 33;
	parameter MIN_RADIUS = 45;

	assign o_VGA_R = CIRCLE_R;
	assign o_VGA_G = CIRCLE_G;
	assign o_VGA_B = CIRCLE_B;

	// Registers
	logic [31:0] count_r, count_w;
	logic [RAND_BIT:0] random_r, random_w;
	logic [CIRNUM-1:0][7:0] decay_r, decay_w;
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
	logic [CIRNUM-1:0] enableList_r, enableList_w;
	logic [CIRNUM-1:0][2:0] transList;
	logic [7:0] CIRCLE_R, CIRCLE_G, CIRCLE_B;
	logic [31:0] intensity;
	logic [31:0] tmp0;
	assign tmp0 = (int'(random_r[9:0]) * 640) >> 10;

	Random #(.BIT(RAND_BIT)) rand_gen(
		.i_clk(i_clk),
		.i_rst(rst),
		.random(random_w)
	);

	LayerAdder #(.LAYERNUM(CIRNUM)) add(
		.i_LAYER_R(COLOR_R_r),
		.i_LAYER_G(COLOR_G_r),
		.i_LAYER_B(COLOR_B_r),
		.i_enableList(enableList_r),
		.i_transList(transList),
		.o_VGA_R(CIRCLE_R),
		.o_VGA_G(CIRCLE_G),
		.o_VGA_B(CIRCLE_B)
	);

always_comb begin
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
	decay_w = decay_r;
	enableList_w = '0;

	// Calculations
	for (int i = 0; i < CIRNUM; i++) begin
		// int distance;
		// distance = (i_VGA_X  + 1 - CENTER_X_r[i]) ** 2 + (i_VGA_Y - CENTER_Y_r[i]) ** 2;
		if(((i_VGA_X  + 1 - CENTER_X_r[i]) ** 2 + (i_VGA_Y - CENTER_Y_r[i]) ** 2)
			<= (RADIUS_r[i] + i_radius_off) ** 2) enableList_w[i] = 1;
		transList[i][1:0] = decay_r[i][7:6];
	end

	// Decade the color
	if(count_r[18:0] == 1) begin
		for (int i = 0; i < CIRNUM; i++) begin
			if(decay_r[i] < 255) decay_w[i] = decay_r[i] + 1;
			if(COLOR_R_r[i] > 0) COLOR_R_w[i] = COLOR_R_r[i] - 1;
			if(COLOR_G_r[i] > 0) COLOR_G_w[i] = COLOR_G_r[i] - 1;
			if(COLOR_B_r[i] > 0) COLOR_B_w[i] = COLOR_B_r[i] - 1;
		end
	end

	intensity = i_DATA[0] + i_DATA[1] + i_DATA[2] + i_DATA[3] + i_DATA[4] + i_DATA[5] + i_DATA[6] + i_DATA[7] +
				i_DATA[8] + i_DATA[9] + i_DATA[10] + i_DATA[11] + i_DATA[12] + i_DATA[13] + i_DATA[14] + i_DATA[15];

	// Update circles
	if((count_r[20:0] == 0) && (intensity > random_r[33:26])) begin
		// Shift register and create new circle
		CENTER_X_w = {CENTER_X_r[CIRNUM-2:0], nextX_r};
		CENTER_Y_w = {CENTER_Y_r[CIRNUM-2:0], nextY_r};
		RADIUS_w = {RADIUS_r[CIRNUM-2:0], nextRAD_r};
		COLOR_R_w = {COLOR_R_r[CIRNUM-2:0], nextR_r};
		COLOR_G_w = {COLOR_G_r[CIRNUM-2:0], nextG_r};
		COLOR_B_w = {COLOR_B_r[CIRNUM-2:0], nextB_r};
		decay_w = {decay_r[CIRNUM-2:0], 8'b0};

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
		// if(random_r[17:10] + random_r[25:18] >= 480) begin
		// 	nextY_w = random_r[17:10] + random_r[25:18] - 256;
		// end else begin
		// 	nextY_w = random_r[17:10] + random_r[25:18];
		// end


		// nextRAD_w = 45 + random_r[25:19];

		if(nextX_w < 160) begin
			nextRAD_w = MIN_RADIUS + (i_DATA[1] << 2) + random_r[23:19];
			nextR_w = 255;
			nextG_w = (51 * nextX_w) >> 5;
			nextB_w = '0;
		end else if(nextX_w < 320) begin
			nextRAD_w = MIN_RADIUS + (i_DATA[5] << 2) + random_r[23:19];
			nextR_w = (51 * (319 - nextX_w)) >> 5;
			nextG_w = 255;
			nextB_w = '0;
		end else if(nextX_w < 480) begin
			nextRAD_w = MIN_RADIUS + (i_DATA[9] << 2) + random_r[23:19];
			nextR_w = '0;
			nextG_w = 255;
			nextB_w = (51 * (nextX_w - 320)) >> 5;
		end else begin
			nextRAD_w = MIN_RADIUS + (i_DATA[13] << 2) + random_r[23:19];
			nextR_w = '0;
			nextG_w = (51 * (639 - nextX_w)) >> 5;
			nextB_w = 255;
		end


		// nextX_w = tmp0;
		// if(random_r[17:10] + random_r[25:18] >= 480) begin
		// 	nextY_w = random_r[17:10] + random_r[25:18] - 256;
		// end else begin
		// 	nextY_w = random_r[17:10] + random_r[25:18];
		// end

		// if(nextX_w < 220) begin
		// 	nextRAD_w = (i_DATA[2] << 3) + random_r[24:19];
		// 	nextR_w = 255;
		// 	nextG_w = '0;
		// 	nextB_w = '0;
		// end else if(nextX_w < 420) begin
		// 	nextRAD_w = (i_DATA[9] << 3) + random_r[24:19];
		// 	nextR_w = '0;
		// 	nextG_w = 255;
		// 	nextB_w = '0;
		// end else begin
		// 	nextRAD_w = (i_DATA[13] << 3) + random_r[24:19];
		// 	nextR_w = '0;
		// 	nextG_w = '0;
		// 	nextB_w = 255;
		// end

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
		decay_r <= '0;
		enableList_r <= '0;
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
		decay_r <= decay_w;
		enableList_r <= enableList_w;
	end
end

endmodule