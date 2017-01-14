module log2(
	input[15:0] i_data,
	output[15:0] o_data
);

always_comb begin
	o_data = 0;
	for (int i = 0; i < 16; i++) begin
		if(i_data[i] == 1) begin 
			o_data = i;
		end
	end
end

endmodule