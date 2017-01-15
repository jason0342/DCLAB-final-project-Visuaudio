module log2(
	input[length-1:0][15:0] i_data,
	output[length-1:0][3:0] o_data
);

parameter length = 16;

always_comb begin
	o_data = '0;
	for (int i = 0; i < length; i++) begin
		for (int j = 0; j < 16; j++) begin
			if(i_data[i][j] == 1) begin 
				o_data[i] = j;
			end
		end
	end
end

endmodule