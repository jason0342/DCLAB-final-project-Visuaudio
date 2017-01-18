module LayerAdder (
	input [LAYERNUM-1:0][7:0] i_LAYER_R,
	input [LAYERNUM-1:0][7:0] i_LAYER_G,
	input [LAYERNUM-1:0][7:0] i_LAYER_B,
	input [LAYERNUM-1:0] i_enableList,
	input [LAYERNUM-1:0][2:0] i_transList,

	output [7:0] o_VGA_R,
	output [7:0] o_VGA_G,
	output [7:0] o_VGA_B
);

	parameter LAYERNUM;

	always_comb begin
		o_VGA_R = '0;
		o_VGA_G = '0;
		o_VGA_B = '0;

		for (int i = 0; i < LAYERNUM; i++) begin
			if(i_enableList[i]) begin
				case (i_transList[i])
					0: begin
						// trans = 1/4
						o_VGA_R = o_VGA_R - (o_VGA_R >> 2) + (i_LAYER_R[i] >> 2);
						o_VGA_G = o_VGA_G - (o_VGA_G >> 2) + (i_LAYER_G[i] >> 2);
						o_VGA_B = o_VGA_B - (o_VGA_B >> 2) + (i_LAYER_B[i] >> 2);
					end
					1: begin
						// trans = 1/8
						o_VGA_R = o_VGA_R - (o_VGA_R >> 3) + (i_LAYER_R[i] >> 3);
						o_VGA_G = o_VGA_G - (o_VGA_G >> 3) + (i_LAYER_G[i] >> 3);
						o_VGA_B = o_VGA_B - (o_VGA_B >> 3) + (i_LAYER_B[i] >> 3);
					end
					2: begin
						// trans = 1/16
						o_VGA_R = o_VGA_R - (o_VGA_R >> 4) + (i_LAYER_R[i] >> 4);
						o_VGA_G = o_VGA_G - (o_VGA_G >> 4) + (i_LAYER_G[i] >> 4);
						o_VGA_B = o_VGA_B - (o_VGA_B >> 4) + (i_LAYER_B[i] >> 4);
					end
					3: begin
						// trans = 1/32
						o_VGA_R = o_VGA_R - (o_VGA_R >> 5) + (i_LAYER_R[i] >> 5);
						o_VGA_G = o_VGA_G - (o_VGA_G >> 5) + (i_LAYER_G[i] >> 5);
						o_VGA_B = o_VGA_B - (o_VGA_B >> 5) + (i_LAYER_B[i] >> 5);
					end
					// Just disappear
					default : begin end
				endcase
			end
		end
		
	end

endmodule