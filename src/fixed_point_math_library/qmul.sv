module qmul (
	input[31:0] a,
	input[31:0] b,
	output[31:0] c
);
	
	parameter Q = 15;

	logic[63:0] res;
	logic[31:0] ans;

	assign c = ans;

always_comb begin
	res = int'(a) * int'(b);
	if(res[63] && res[63:Q] < {{(33-Q){1'b1}}, {31{1'b0}}}) begin
		ans[31] = 1;
		ans[30:0] = '0;
	end else if(~res[63] && res[63:Q] > {{(33-Q){1'b0}}, {31{1'b1}}}) begin
		ans[31] = 0;
		ans[30:0] = '1;
	end else begin
		ans = res[Q+31:Q];
	end
end

endmodule
