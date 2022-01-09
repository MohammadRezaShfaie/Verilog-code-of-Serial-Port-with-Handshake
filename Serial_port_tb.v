`timescale 1ns / 1ps
module Serial_port_tb();
  reg	   w_e,r_e,clk;
  reg    [7:0]input_data;
  wire 	[7:0]output_data;
  wire	e_f,f_f;  
	Serial_port DUT (w_e,r_e,clk,input_data,output_data,e_f,f_f);

	initial 
	begin
		clk<=0;
		w_e<=0;
		r_e<=0;
	end	
	always #1 clk=~clk;
	initial
	begin 
	//1
	#2
	w_e<=1;
	r_e<=0;
	input_data<=8'b01101000;
	//2
	#2
	w_e<=1;
	r_e<=0;
	input_data<=8'b01100101;
	//3
	#2
	w_e<=1;
	r_e<=0;
	input_data<=8'b01101100;
	//4
	#2
	w_e<=1;
	r_e<=0;
	input_data<=8'b01101100;
	//5
	#2
	w_e<=1;
	r_e<=0;
	input_data<=8'b01101111;
	//6
	#2
	w_e<=1;
	r_e<=0;
	input_data<=8'b00100000;
	//7
	#2
	w_e<=1;
	r_e<=0;
	input_data<=8'b01110111;
	//8
	#2
	w_e<=1;
	r_e<=0;
	input_data<=8'b01101111;
	//9
	#2
	w_e<=1;
	r_e<=0;
	input_data<=8'b01110010;
	#2
	w_e<=0;
	//10
	#100
	r_e<=1;
	#300
	w_e<=1;
	input_data<=8'b01101100;
	//11
	#2
	w_e<=1;
	input_data<=8'b01100100;
	#2
	w_e<=0;
	end
endmodule
