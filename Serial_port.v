`timescale 1ns / 10ps
module Input_FIFO(
  input  w_e,r_e,clk,
  input  [7:0]input_data,
  output [7:0]output_data,
  output e_f,f_f
    );
  parameter depth=8 , width=8;
  reg  [(width-1):0] I_fifo [0:(depth-1)];
  reg  e_r,f_r;
  reg  [3:0] RD_pointer,WR_pointer;
  reg  [7:0]input_r;
  reg	 [7:0]output_r;
  
  initial 
	begin
	RD_pointer=4'b0000;
	WR_pointer=4'b0000;
	f_r=0;
	e_r=1;
	end
  assign f_f=f_r;
  assign e_f=e_r;
  assign output_data=output_r;
	always @(posedge clk)
		begin
		if (w_e==1) 
			begin
				if (f_r==0)
				begin
				I_fifo[WR_pointer[2:0]]=input_data;
				WR_pointer=WR_pointer+1;
				if({~WR_pointer[3],WR_pointer[2:0]}==RD_pointer[3:0]) f_r=1;	
				else f_r=0;	
				e_r=0;
				end
			end
			
		if(r_e==1)
			begin
				if(e_r==0)
				begin
				output_r=I_fifo[RD_pointer[2:0]];
				RD_pointer=RD_pointer+1;
				f_r=0;
					if(WR_pointer==RD_pointer)
					begin
					RD_pointer=0;
					WR_pointer=0;
					#6
					e_r=1;
					f_r=0;
					end
				end
			end
		
		end
endmodule

//***********************control_Parity*******************\\

module control_Parity(
		input  e_f,Ok,clk,
		input  [7:0] input_data,
		output data_available,r_e,
		output [8:0] Data
    );
	reg [7:0]r_input;
	reg [8:0]r_output;
	reg parity,r_r_e,r_data_available;
	reg status;
	parameter full=1'b1 , empty=1'b0;
	
	initial r_data_available=0;
	initial r_r_e=0;
	initial status=empty;
	always @(posedge clk)
		begin 
		case(status)
		empty:
			begin
			if(e_f==0)
				begin
				r_r_e=1;
				status=full;
				end
			end
		full:
			begin
			r_r_e=0;
			r_input = input_data;
			parity=(r_input[7]^r_input[6]^r_input[5]^r_input[4]^r_input[3]^r_input[2]^r_input[1]^r_input[0]);
			r_output={r_input,parity};
			//#2
			r_data_available=1;
			if(Ok==1) 
				begin
				r_data_available=0;
				status=empty;
				end
			end	
			endcase

		end	
		assign Data=r_output;
		assign r_e=r_r_e;
		assign data_available=r_data_available;
endmodule


//***********************transmitter*******************\\


module Transmitter(
		input data_available,clk,
		input [8:0] input_data,
		output Ok,
		output line
    );
	reg r_line; 
	parameter baud_rate=4; 
	parameter active=1'b1 , idle=1'b0;
	reg [8:0] data_line;
	reg r_Ok,status;
	integer i;	
	
	initial 
	begin
	r_Ok=0;
	r_line=1;
	status=idle;
	end
		always @ (posedge clk)
		begin
			case(status)
				idle:
					begin 
						if(data_available==1)
						begin
						#2
						data_line=input_data;
						r_Ok=0;
						status=active;
						end
					end
				active:
					begin
					// start bit of frame
					r_line=0;
					#baud_rate;
					// data
					for(i=0;i<=8;i=i+1)
						begin
						r_line=data_line[i];
						#baud_rate;
						end
					// stop bit of frame	
					r_line=1;
					#baud_rate;
					// 2 bits between frames
					#baud_rate;
					#baud_rate;
					r_Ok=1;
					status=idle;
					end

			endcase	
		end
	assign line=r_line;
	assign Ok=r_Ok;
endmodule

//***********************Reciever*******************\\

module Reciever(
		input Ok,clk,line,
		output data_available,
		output [8:0] output_data
    );
	parameter baud_rate=4; 
	reg [8:0] data_line,complete_data;
	reg r_data_available;
	reg status;
	parameter idle=1'b0,active=1'b1;
	initial 
	begin 
	status=idle;
	r_data_available=0;
	end
	integer i;	
		always @ (posedge clk)
		begin
		case(status)
			idle:
			begin
				if (Ok==1) r_data_available=0;
				if (line==0)status=active;
			end
			active:
			begin
				#baud_rate
				for(i=0;i<=8;i=i+1)
				begin
				data_line[i]=line;
				#baud_rate;
				end
				if(line==1)
				begin
				complete_data=data_line;
				r_data_available=1;
				status=idle;
				end
			end
		endcase
		end
	assign output_data=complete_data;
	assign data_available=r_data_available;
endmodule


//***********************control_Parity_checker*******************\\


module control_Parity_checker(
		input   data_available,f_f,clk,
		input   [8:0] Data,
		output  Ok,w_e,
		output  [7:0] output_data
    );
	
	reg r_Ok,r_w_e;	
	reg [8:0]r_input;
	reg [7:0]r_output;
	reg parity,parity_checker;
	reg status;
	parameter full=1'b1 , empty=1'b0;
	initial
	begin
	r_Ok=0;
	status=empty;
	end
	always @(posedge clk)
		begin
		case(status)
		
			empty:
			begin
				if (data_available==1)
					begin
						status=full;
					end
				else 
					begin
					r_Ok=0;
					status=empty;
					end
			end
			
			full :
			begin
			r_input=Data;
			r_Ok=1;
			parity=r_input[0];
			parity_checker=(r_input[8]^r_input[7]^r_input[6]^r_input[5]^r_input[4]^r_input[3]^r_input[2]^r_input[1]);
				if(parity==parity_checker)
				begin
					if(f_f==0)
					begin
					r_w_e=1;
					r_output=r_input[8:1];
					#3 // wait for write byte in FIFO 
					r_w_e=0;
					end
				end
				status=empty;
			end
		endcase
		end
		assign output_data=r_output;
		assign w_e=r_w_e;
		assign Ok=r_Ok;
endmodule


//***********************output_FIFO*******************\\


module output_FIFO(
  input  w_e,r_e,clk,
  input  [7:0]input_data,
  output [7:0]output_data,
  output e_f,f_f
    );
  parameter depth=8 , width=8;
  reg  [(width-1):0] O_fifo [0:(depth-1)];
  reg  e_r,f_r;
  reg  [3:0] RD_pointer,WR_pointer;
  reg  [7:0]input_r;
  reg	 [7:0]output_r;
  
  initial 
	begin
	RD_pointer=4'b0000;
	WR_pointer=4'b0000;
	f_r=0;
	e_r=1;
	end
  assign f_f=f_r;
  assign e_f=e_r;
  assign output_data=output_r;
	always @(posedge clk)
		begin
		if (w_e==1) 
			begin
				if (f_r==0)
				begin
				O_fifo[WR_pointer[2:0]]=input_data;
				WR_pointer=WR_pointer+1;
				if({~WR_pointer[3],WR_pointer[2:0]}==RD_pointer[3:0]) f_r=1;	
				else f_r=0;		
				e_r=0;
				end
			end
			
		if(r_e==1)
			begin
				if(e_r==0)
				begin
				output_r=O_fifo[RD_pointer[2:0]];
				RD_pointer=RD_pointer+1;	
				f_r=0;
					if(WR_pointer==RD_pointer)
					begin
					RD_pointer=0;
					WR_pointer=0;
					e_r=1;
					f_r=0;
					end
				end
			end
		
		end
endmodule


//***********************Serial_port*******************\\


module Serial_port(
  input  w_e,r_e,clk,
  input  [7:0]input_data,
  output [7:0]output_data,
  output e_f,f_f);
  
	 wire  W_T_re,W_T_EF,W_T_davi,W_T_Ok,W_LINE,W_R_davi,W_R_Ok,W_R_en,W_R_FF;
	 wire [7:0] W_T_od,W_R_id;
	 wire [8:0] W_T_Data,W_R_Data;
	 
		Input_FIFO 					Input_FIFOmodule(w_e,W_T_re,clk,input_data,W_T_od,W_T_EF,f_f);
		
		control_Parity				control_Paritymodule(W_T_EF,W_T_Ok,clk,W_T_od,W_T_davi,W_T_re,W_T_Data);
		
		Transmitter 				Transmittermodule(W_T_davi,clk,W_T_Data,W_T_Ok,W_LINE);
		
		Reciever						Recievermodule(W_R_Ok,clk,W_LINE,W_R_davi,W_R_Data);
		
		control_Parity_checker	control_Parity_checkermodule(W_R_davi,W_R_FF,clk,W_R_Data,W_R_Ok,W_R_en,W_R_id);
		
		output_FIFO					output_FIFOmodule(W_R_en,r_e,clk,W_R_id,output_data,e_f,W_R_FF);
		
		
endmodule
