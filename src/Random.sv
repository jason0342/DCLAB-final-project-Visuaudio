module Random (
	input i_clk,
	input i_rst,
	output [BIT:0] random
);

	parameter BIT = 47;

	logic [BIT:0][15:0] data_r, data_w;

always_comb begin
	random = '0;
	if(data_r == '0) begin
		for (int i = 0; i < BIT; i++) begin
			data_w[i] <= 177 * i;
		end
	end else begin
		for (int i = 0; i < BIT; i++) begin
			random[i] = data_r[i][15] ^ data_r[i][13] ^ data_r[i][12] ^ data_r[i][10];
			data_w[i] = {data_r[i][14:0], random[i]};
		end
	end
end

always_ff @(posedge i_clk or posedge i_rst) begin
	if(i_rst) begin
		data_r = '0;
	end else begin
		data_r <= data_w;
	end
end

endmodule