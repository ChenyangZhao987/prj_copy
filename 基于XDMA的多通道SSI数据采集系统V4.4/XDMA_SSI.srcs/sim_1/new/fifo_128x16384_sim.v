`timescale 1ns / 1ps

module fifo_128x16384(
	input					rst,
	input					wr_clk,
	input					rd_clk,
	input		[127:0]		din,
	input					wr_en,
	input					rd_en,
	output	reg	[127:0]		dout,
	output					full,
	output					empty,
	output		[14:0]		rd_data_count,
	output					wr_rst_busy,
	output					rd_rst_busy
);

localparam DEPTH = 2048;

reg		[127:0]	mem[0:DEPTH-1];
reg		[10:0]	wr_ptr;
reg		[10:0]	rd_ptr;
reg		[11:0]	count;

assign full				= (count == DEPTH);
assign empty			= (count == 12'd0);
assign rd_data_count	= {4'd0,count[10:0]};
assign wr_rst_busy		= 1'b0;
assign rd_rst_busy		= 1'b0;

always@(posedge wr_clk)begin
	if(rst)begin
		wr_ptr	<= 11'd0;
		rd_ptr	<= 11'd0;
		count	<= 12'd0;
		dout	<= 128'd0;
	end else begin
		if(wr_en && !full)begin
			mem[wr_ptr] <= din;
			wr_ptr <= wr_ptr + 1'b1;
		end

		if(rd_en && !empty)begin
			dout <= mem[rd_ptr];
			rd_ptr <= rd_ptr + 1'b1;
		end

		case({wr_en && !full, rd_en && !empty})
			2'b10	:	count <= count + 1'b1;
			2'b01	:	count <= count - 1'b1;
			default	:	count <= count;
		endcase
	end
end

endmodule
