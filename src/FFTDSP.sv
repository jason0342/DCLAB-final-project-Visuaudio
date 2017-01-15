module FFTDSP(
	input i_clk,
	input i_rst,
	input i_fft_done,
	input[15:0][15:0] i_data,
	output[15:0][15:0] o_data
);

	logic[15:0][17:0] data1_r, data2_r, data3_r, data4_r;
	logic[15:0][17:0] data1_w, data2_w, data3_w, data4_w;

always_comb begin
	data1_w = data1_r;
	data2_w = data2_r;
	data3_w = data3_r;
	data4_w = data4_r;

	for(int i = 0; i < 16; i++) begin
		o_data[i] = (data1_r[i] + data2_r[i] + data3_r[i] + data4_r[i]) >> 2;
	end

	if(i_fft_done) begin
		for (int i = 0; i < 16; i++) begin
			data1_w[i] = (i_data[i][15])? (2**16-i_data[i]) : i_data[i];
		end
		data2_w = data1_r;
		data3_w = data2_r;
		data4_w = data3_r;
	end

end

always_ff@(posedge i_clk or posedge i_rst) begin
	if(i_rst) begin
		data1_r <= 0;
		data2_r <= 0;
		data3_r <= 0;
		data4_r <= 0;
	end else begin
		data1_r <= data1_w;
		data2_r <= data2_w;
		data3_r <= data3_w;
		data4_r <= data4_w;
	end
end

endmodule