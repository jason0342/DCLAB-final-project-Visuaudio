module BeatDetection(
	input i_clk,
	input i_rst,
	input i_frame_clk,
	input[2:0][3:0] i_data,
	output[3:0] o_beat,
	output[4:0] o_radius
);
	
	parameter S_WAIT = 0;

	logic[6:0] d1, d2, d3, d4;
	logic[6:0] prev_data_r, prev_data_w;
	logic[6:0] threshold_r, threshold_w;
	logic[3:0] count_r, count_w;
	logic[4:0] radius_r, radius_w;

	assign o_beat = count_r;
	assign o_radius = radius_r;
	assign d1 = i_data[0];
	assign d2 = i_data[1];
	assign d3 = i_data[2];
	// assign d4 = i_data[3];

always_comb begin
	threshold_w = threshold_r;
	count_w = count_r;
	radius_w = radius_r;

	if(count_r == S_WAIT) begin
		if(d1 + d2 + d3 >= prev_data_r + threshold_r) begin
			count_w = count_r + 1;
		end
	end else begin
		count_w = count_r + 1;
		if(count_r == 15) begin
			count_w = 0;
		end
	end

	if(count_r == 0) begin
		radius_w = 0;
	end else if(count_r == 1) begin
		radius_w = 10;
	end else if(count_r == 2) begin
		radius_w = 20;
	end else if(count_r == 3) begin
		radius_w = 31;
	end else begin
		radius_w = 31 - (count_r << 1);
	end


end

always_ff @(posedge i_clk or posedge i_rst) begin
	if(i_rst) begin
		prev_data_r <= 0;
		threshold_r <= 6;
		count_r <= 0;
		radius_r <= 0;
	end else begin
		prev_data_r <= d1 + d2 + d3;
		threshold_r <= threshold_w;
		count_r <= count_w;
		radius_r <= radius_w;
	end
end



endmodule