module sweepcontrol 
(
   // ----------------------- inputs ---------------------

   // master clock
   input logic clk,
	
	// data and address bus
	input logic [7:0]  data_in,
	input logic [3:0]  address_in,
	input logic write,
	
	// rotary encoder signals
	input logic rot_phase_a , rot_phase_b,
	
	// sampling enable
	input logic enable_sampling,
	
	// ----------------------- outputs ---------------------

	// dac output
	output logic [7:0] dac,
		
   // sampler gate signals		
	output reg sample_gate_a , sample_gate_b ,
	
	// channel selection
	output reg [1:0] channel_select,   // drives relays or multiplexer
	output reg channel_ab,       // notifies cpu what channel is sampled
	
	// sampling done 
	output reg sample_ready,     // notifies cpu samples have been collected
	
	// cursor generation
	output reg [1:0] cursor_state,
   
	// voltage dac
	output reg [7:0] dac_y
);


// internal registers  

reg [7:0] cursor_a , cursor_b ;
reg [7:0] rotary_limit;
reg [11:0] loopcounter;
reg auto_channel;
reg [2:0] selected_trace;
reg [7:0] step1;
reg [7:0] step2;
reg [7:0] step3;
reg [7:0] step4;
reg [7:0] step5;
reg [3:0] edge_detector;
reg [1:0] rotary_binding;

// This is a pure combinatorial block 
// We bring out the lowest 8 bit of the loopcounter to drive the dac

always_comb begin
   dac[7:0] <=loopcounter [7:0];
end

always_ff @(posedge clk) begin
   
	// Always running upcounter. on counter overrun increment sweep counter
	loopcounter <= loopcounter +11'd1;
	if (loopcounter == 11'b100_11111111) begin
		loopcounter <=0;
		if (auto_channel ==1) begin
		   case (channel_select)
			  2'b00 : channel_select <= 2'b00;
			  2'b01 : channel_select <= 2'b10;
			  2'b10 : channel_select <= 2'b01;
			  2'b11 : channel_select <= 2'b00;   // this can't happen , but if it does : turn all off
			endcase
		end
	end	
	
	// this can run always too : update vertical dac 
	case (loopcounter[10:8])
	   3'b000 : dac_y <= step1;
		3'b001 : dac_y <= step2;
		3'b010 : dac_y <= step3;
		3'b011 : dac_y <= step4;
		3'b100 : dac_y <= step5;
	endcase
	
	
	if (channel_select == 2'b10) channel_ab <=1;
	if (channel_select == 2'b01) channel_ab <=0;
	
	// rotary encoder edge detector
	
	edge_detector[3:0] <= { edge_detector [2:0],rot_phase_a};
	
	// sampling logic
	
	if (loopcounter[10:8] == selected_trace) begin
	   if (sample_ready == 1'b0) begin
			if (loopcounter[7:0] == 8'b0) begin
				 sample_gate_a <= 1'b1;
				 sample_gate_b <= 1'b1;
			end
			case (cursor_state)
			2'b00   :	begin
								if (loopcounter [7:0] == cursor_a) begin
									cursor_state  <= 2'b01;
									sample_gate_a <= 1'b0;
								end
								if (loopcounter [7:0] == cursor_b)begin
									cursor_state  <= 2'b01;
									sample_gate_b <= 1'b0;
									sample_ready  <= 1'b1;
								end;	
							end 
			2'b01   :   cursor_state <= 2'b11;
			2'b11   :   cursor_state <= 2'b00;
			default :   cursor_state <= 2'b00;
			endcase
		end
		else begin
			if (enable_sampling == 1'b1) sample_ready <=1'b0;
		end
	end	
	
	// cursor control
	if (edge_detector == 4'b0111) begin
		case (rotary_binding)
		2'b00 :  if (rot_phase_b ==0) begin
		            if (cursor_b !=255) cursor_a <= cursor_a+ 8'd1;
					end
					else begin
					   if (cursor_a !=0) cursor_a <= cursor_a-8'd1;
					end
					
		2'b01 :  if (rot_phase_b ==0) begin
		            if (cursor_b !=255) cursor_b <= cursor_b+8'd1;
					end
					else begin
					   if (cursor_b !=0) cursor_b <= cursor_b-8'd1;
					end
		2'b10 : 	if (rot_phase_b ==0) begin
		            if (selected_trace != 3'b100) selected_trace <= selected_trace+3'd1;
					end
					else begin
					   if (selected_trace !=0) selected_trace <= selected_trace-3'd1;
					end	
		endcase
	end
	
	
	
	// process the register writes. Since this happens later it takes priority (scheduled logic)
	if (write ==1) begin
		case (address_in)
			4'b0000 : cursor_a       <= data_in;
			4'b0001 : cursor_b       <= data_in;
			4'b0010 : selected_trace <= data_in [2:0];
			4'b0011 : rotary_limit   <= data_in;
			4'b0100 : begin
							if (auto_channel==0) begin                                     // don't allow this when in autochannel
								if (data_in[1:0] != 2'b11) channel_select <= data_in[1:0];  // protect from user stupidity. block enabling both channels
							end	
						end	
			4'b0101 : auto_channel   <= data_in[0];
         4'b0110 : rotary_binding [1:0] <= data_in[1:0];
			4'b0111 : begin                                                             // reset command
							sample_ready <=1'b0;                                            // force sample write register
							cursor_state <=2'b0;
							channel_select <=2'b0;
							sample_gate_a <=1'b0;
							sample_gate_b <=1'b0;
							loopcounter <=0;
							dac_y <=0;
						 end	
			
			4'b1000 : step1 <= data_in;
			4'b1001 : step2 <= data_in;
			4'b1010 : step3 <= data_in;
			4'b1011 : step4 <= data_in;
			4'b1100 : step5 <= data_in;
		endcase
	end
	
end


/*
always_ff @(posedge latch_cur_a) begin
   cursor_a <= databus;
end

always_ff @(posedge latch_cur_b) begin
   cursor_b <= databus;
end

always_ff @(posedge latch_trace) begin
   selected_trace <= databus [2:0];
end
*/

endmodule



//module sweepcontrol 
//(
//   input logic latch_cur_a , latch_cur_b  , clk , latch_trace,
//	input logic [7:0]  databus ,
//	input logic rot_phase_a , rot_phase_b,
//	input logic [1:0] addr,
//	input logic write,
//	//output wire cursor_enable , cursor_polarity ,
//	output reg [2:0] current_trace,
//	output reg [7:0] sweep ,
//	output reg sample_gate_a , sample_gate_b , 
//	output reg [1:0] cursor_state,
//   output logic [7:0] dac
//);
//
//reg [7:0] cursor_a , cursor_b ;
//reg [2:0] selected_trace;
//reg [7:0] rotary_limit;
//reg [11:0] loopcounter;
//
//always_comb begin
//   dac[7:0] <=loopcounter [7:0];
//end
//
//always_ff @(posedge clk) begin
//   
//	// Always running upcounter. on counter overrun increment sweep counter
//	sweep <= sweep +8'd1;
//	if (sweep == 255) begin
//	   if (current_trace == 4) begin
//		    current_trace <=0;
//		end else begin
//		    current_trace <= current_trace +2'b001;
//		end
//	end
//	
//	/*
//	// alternate way : have a 11 bit counter
//	   loopcounter <= loopcounter +1;
//		if (loopcounter == 11'b101_11111111) loopcounter <=0;
//	
//	*/
//	
//	if (current_trace == selected_trace) begin
//	   if (sweep == 7'b0) begin
//		    sample_gate_a <= 1'b1;
//			 sample_gate_b <= 1'b1;
//		end
//  	   case (cursor_state)
//	   2'b00   :	begin
//							if (sweep == cursor_a) begin
//								cursor_state <= 2'b01;
//								sample_gate_a <= 1'b0;
//							end
//							if (sweep == cursor_b)begin
//								cursor_state <= 2'b01;
//								sample_gate_b <= 1'b0;
//							end;	
//		            end 
//	   2'b01   :   cursor_state <= 2'b11;
//	   2'b11   :   cursor_state <= 2'b00;
//	   default :   cursor_state <= 2'b00;
//	   endcase
//	end	
//	
//	
//	
//	
//	// process the register writes. Since this happens later it takes priority (scheduled logic)
//	if (write ==1) begin
//		case (addr)
//			2'b00 : cursor_a       <= databus;
//			2'b01 : cursor_b       <= databus;
//			2'b10 : selected_trace <= databus [2:0];
//			2'b11 : rotary_limit   <= databus;
//		endcase
//	end
//	
//end
//
//
///*
//always_ff @(posedge latch_cur_a) begin
//   cursor_a <= databus;
//end
//
//always_ff @(posedge latch_cur_b) begin
//   cursor_b <= databus;
//end
//
//always_ff @(posedge latch_trace) begin
//   selected_trace <= databus [2:0];
//end
//*/
//
//endmodule
//*/