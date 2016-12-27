module qmul (
	input[31:0] a,
	input[31:0] b,
	output[31:0] c
);
	
	parameter Q = 15;

	logic[63:0] res;

always_comb begin
	res = int'(a) * int'(b);
	if(res[63] && res[63:Q] < {33'1, (31-Q)'0}) begin
		c[31] = 1;
		c[30:0] = '0;
	end else if(~res[63] && res[63:Q] > {33'0, (31-Q)'1}) begin
		c[31] = 0;
		c[30:0] = '1;
	end else begin
		c = res[Q+31:Q];
	end
end

endmodule