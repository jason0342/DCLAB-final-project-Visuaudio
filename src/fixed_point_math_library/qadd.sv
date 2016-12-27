module qadd(
	input[31:0] a,
	input[31:0] b,
	output[31:0] c
);

	logic[31:0] res;

always_comb begin
	res = int'(a) + int'(b); // cast to signed int
	if(a[31]&b[31]&(~res[31])) begin
		c[31] = 1;
		c[30:0] = '0; // saturate to neg max
	end else if((~a[31])&(~b[31])&res[31]) begin
		c[31] = 0;
		c[30:0] = '1; // saturate to pos max
	end else begin
		c = res;
	end
end