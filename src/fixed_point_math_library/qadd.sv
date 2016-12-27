module qadd(
	input[31:0] a,
	input[31:0] b,
	output[31:0] c
);

	logic[31:0] res, ans;

	assign c = ans;

always_comb begin
	res = int'(a) + int'(b); // cast to signed int
	if(a[31]&b[31]&(~res[31])) begin
		ans[31] = 1'b1;
		ans[30:0] = '0; // saturate to neg max
	end else if((~a[31])&(~b[31])&res[31]) begin
		ans[31] = 1'b0;
		ans[30:0] = '1; // saturate to pos max
	end else begin
		ans = res;
	end
end

endmodule

