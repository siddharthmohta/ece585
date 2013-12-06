`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:01:17 11/19/2013 
// Design Name: 
// Module Name:    version_2 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module version_2();
reg[31:0] address;
integer n;
integer tracefile;
integer file;
parameter HIT = 0;
parameter HITM = 1;
parameter MISS = 2;
//parameter SETS = 0;


//parameter WAYS = 1;
//parameter INDEX = 2;
parameter NULL = 0;
//parameter LINES = 8;

// Bit requirements for L2 Cache  
parameter SETS = 2;//16384;
parameter LINES = 8;
parameter TAG_WIDTH = 12;
parameter OFFSET_WIDTH = 6;
parameter INDEX_WIDTH = 14;
parameter LRU_WIDTH = 3;

integer hitcount = 0;
integer misscount = 0;
integer writecount = 0;
reg hit,miss;
integer  getsnoop;
integer snoop;
integer readmem;
integer state , nextstate;
//integer MESI;
integer bus;
integer N;
integer readcount = 0;
integer readvalue;
//integer snoopresult;
integer way_1;
integer way_2;
integer way_3;
integer cache_hits;
integer cache_miss;

//Cache storage bits
reg [0:OFFSET_WIDTH-1] offset_bits;
reg [0:INDEX_WIDTH-1] index_bits;
reg [0:TAG_WIDTH-1] tag_bits[0:SETS-1] [0:LINES-1];
reg valid[0:SETS-1] [0:LINES-1]; 
reg dirty[0:SETS-1] [0:LINES-1];
reg [0:LRU_WIDTH-1] LRU_bits[0:SETS-1] [0:LINES-1];
integer MESI[0:SETS-1] [0:LINES-1];

//Cache array 16K X 8
reg [0:16]cache_l2[0:SETS-1] [0:LINES-1];
reg [0:TAG_WIDTH-1]Temptag;  
reg [0:INDEX_WIDTH-1]Tempindex;


parameter ADDRESS_R = 0;
parameter ADDRESS_W = 1;
parameter ADDRESS_M = 2;
parameter ADDRESS_I = 3;

reg returnvalue;
reg operation;
reg value;
//reg  [31:0] testadd;

reg [1:0] snoopaddress;

parameter M = 0;                           // states 
parameter E = 1;
parameter S = 2;
parameter I = 3;

initial
begin:file_block

//always @(*)
//begin



file = $fopen("N:\\test.txt","r");
initialise;

if(file == NULL)
begin
disable file_block;
end


//n = $fgetc(file);
//n = N - 48;

n=0;
//readcount = 0;
 while (!$feof(file))
 begin
tracefile = $fscanf(file,"%d %h:\n",n,address);		
//$display("n=%d",n);
//snoopaddress = address[0:1];
//testadd = address;
//snoop = $fscanf(file,"%N:/Downloads/merged.vb",snoopaddress);
//N = $fgetc(file);
//n = N - 48;
//getsnoop = HIT;
//hit = 0;


											//checktag
case (n)
	
	0:
	
		begin
		  Tempindex = address[19:6];
		  CheckTag(/*l1_addr,*/way_1);
		  //$display("way1=%d",way_1);	
			readcount=readcount + 1;
			//$display("Read request from L1 data cache\n");
			
			if (way_1 < LINES) // way<8
			begin
				if ((MESI[Tempindex][way_1] == M) ||(MESI[Tempindex][way_1] == E)  ||(MESI[Tempindex][way_1] == S) ) 
				begin
				 hit_func (/*l1_addr,*/way_1);				//	hitfunction
				 update_LRU_hit(/*l1_addr,*/way_1);													// update lru
				  //hitcount = hitcount + 1;
				end
		
			  else//if state = I
				
			   begin
			    //  CheckTag(/*l1_addr,*/way_1);
					//$display("This is an 'I' miss");
					CheckValidity(/*l1_addr,*/way_2);
					//$display("way = %d",way_1);			
					if (way_2 < LINES)
					begin																		// check lru
					miss_func (/*l1_addr,*/way_2);													// miss function
					update_LRU_miss(/*l1_addr,*/way_2);																	// update lru
					end
					else
					  begin
					     CheckLRU(/*l1_addr,*/way_3);
					     miss_func (way_3);
				       update_LRU_hit(/*l1_addr,*/way_3);	
					  end
					//misscount = misscount + 1;
					//$display("R %h ",address);
   				//readmem;
					getsnoopresult(operation,value);
					if ((value == HIT) ||(value == HITM))
					begin
					  $display ("Enter S");
							MESI[Tempindex][way_3]= S;
							//$display("%d",value);
					end
					else
					begin
					  $display ("Enter E");
						MESI[Tempindex][way_3] = E;
					end
				end		
			end
			else//  (way =  8)
			begin
					//$display("R,%h",address);
					//$display("total miss");
					//$display("way = %d",way_1);	
					getsnoopresult(operation,value);
					CheckValidity(/*l1_addr,*/way_2);
					//$display("way2=%d",way_2);
					if(way_2 != LINES)							// present but invalid
					begin
           		 // $display("invalid line");
           		  miss_func(/*l1_addr,*/way_2);
               update_LRU_miss(/*l1_addr,*/way_2);
					end
					else
               begin
                // $display("no present");
                 //$display("way = %d",way_1);	
                 CheckLRU(/*l1_addr,*/way_3);
                // $display("way3 = %d",way_3);
					       miss_func(way_3);
					       update_LRU_miss(/*l1_addr,*/way_3);
					end
					
					//misscount = misscount + 1;
					//				LRU; find which line to evict
					//readmem;
					//update LRU
					if ((value == HIT) ||(value == HITM))
					begin
					  $display ("Enter S");
						MESI[Tempindex][way_3]= S;
					end
					else
					begin
					  $display ("Enter E");
						MESI[Tempindex][way_3] = E;
					end
				end	//end for miss
			L1_stub(address);					// send to L1
		end//
		
/*

	2:		
		begin
			//state = M;
			readcount=readcount + 1;
			bus = ADDRESS_R;
			$display("%d read request from L1 Instruction cache\n",bus);
			 getsnoopresult(operation,value);
			if (hit)
			begin
				if ((state == M) ||(state == E)  ||(state == S) ) 
				begin
					hitcount = hitcount + 1;
				end
				else//if state = I
				begin
					misscount = misscount + 1;
					$display("R %h ",address);
					//readmem;
					if ((snoopresult == HIT) ||(snoopresult == HITM))
					begin
							MESI= S;
					end
					else
					begin
						MESI = E;
					end
				end		
			end
			else// else if miss
			begin
					$display("R %h ",address);
					misscount = misscount + 1;
	//				LRU; find which line to evict
					//readmem;
					//update LRU
					if ((snoopresult == HIT) ||(snoopresult == HITM))
					begin
						MESI= S;
					end
					else
					begin
						MESI = E;
					end
				end	//end for miss
				L1_stub(address);		// send to L1
		end
		
		1:
		   begin
			writecount = writecount + 1;
			//snoop = getsnoop;
			bus = ADDRESS_W;
			$display("%d Write request from L1 data cache\n",bus);
			if (hit)
				begin
					if ((state == M) || (state == E) || (state == S))
					begin	
						hitcount = hitcount + 1;
						//bus = ADDRESS_I;
						$display("M %h ",address);
					end
					else
					begin
					misscount = misscount + 1;
					bus = ADDRESS_M;
					$display("M %h ",address);
					memory_stub(address);				//readmem
					end
				end
			else
				begin
				misscount = misscount + 1;
				bus = ADDRESS_M;
				$display("M %h ",address);
				memory_stub(address); 				// readmem
				end
			MESI = M;			
			end
		
			
		3:
			begin
			if (hit)
				begin
					if ((state == M) || (state == E) || (state == S))
					begin
							MESI = I;
							$display("I %h ",address);
					end
					else
					begin
			
					end
				end	
			else
				begin
			
				end
			end
			
			
			
		4:
			begin
			if (hit)
				begin
					if ((state == M) || (state == E) || (state == S))
					begin
					if (state == M)
					begin
					putsnoopresult(operation,returnvalue);
					//MESI = M;
					//$display("Snoop result is %d\n",bus);
					// put response on bus
					end
					MESI = S;
					end
					else
					begin
					putsnoopresult(operation,returnvalue);
					MESI = I;
					$display("I %h ",address);
					end
				end	
			else
				begin
			//	misscount = misscount + 1;
				end
			end
			
			
			5: 
			   begin
				if (hit)
			   	begin
						if ((state == M) || (state == E) || (state == S))
						begin
						putsnoopresult(operation,returnvalue);
						$display("Stall");
						//hitcount = hitcount + 1;
						end
						else
						putsnoopresult(operation,returnvalue);
						$display("Stall");
						begin
						//misscount = misscount + 1;
						end
					end
				else
					begin
					//misscount = misscount + 1;
					end
				MESI = I;
				$display("I %d ",address);
				end	
				
			6:
				begin
				if (hit)
					begin
						if ((state == M) || (state == E) || (state == S))
						begin
						putsnoopresult(operation,returnvalue);
						$display("I %d ",address);
						//hitcount = hitcount + 1;
						end
						else
						begin
						//misscount = misscount + 1; 
						$display("I %d ",address);
						end
					end
				else
					begin
					//misscount = misscount + 1;
					end
				MESI = I;	
				$display("I %d ",address);
				end	
				
	*/			
endcase //end od case(n)
end // while
$fclose(file);
//end	//always	
end //initial



task putsnoopresult;

//input address;
input operation;
output integer result;
parameter HIT = 2'b00;
parameter HITM = 2'b01;
parameter MISS = 2'b11;

begin
 if (hit)
 begin
	if (state == M)
	begin
		 value = HITM;
		$display("Snoopresult to be put on bus : %d",value);
		// $display("")
	end
	else if((state == E) || (state == S))
	begin
		 value = HIT;
		 $display("Snoopresult to be put on bus : %d",value);
	end
	else
	begin
		 value = MISS;
		 $display("Snoopresult to be put on bus : %d",value);
	end
 end
 
end 
endtask

task getsnoopresult;

//input address;
input operation;
output integer snoopresult;


begin
snoopaddress = address[1:0];
if (snoopaddress == 2'b00)
snoopresult = HIT;
$display("snoopresult = %d",snoopresult);
if  (snoopaddress == 2'b10)
snoopresult = HITM;
if ((snoopaddress == 2'b01) || (snoopaddress == 2'b11))
snoopresult = MISS;
end
endtask


task L1_stub;

input address;

begin

end

endtask

task memory_stub;

input address;

begin

end

endtask


task CheckTag;
//	input [31:0]l1_addr_new;
	output integer way;
	//reg [0:TAG_WIDTH-1]Temptag;  
	//reg [0:INDEX_WIDTH-1]Tempindex;  
	integer line_number;
	begin
      //$display("begin checktag");	  
		Temptag = address [31:20];                        // Masking of Tag bits from the address
    Tempindex = address [19:6];  
       // $display("%b",l1_addr);
		//$display("%b",Temptag);
       //$display("%b",Tempindex);		
							// Masking of Index bits from the address
		line_number = 0;
		while(line_number != LINES)
		begin
		
			if(tag_bits[Tempindex][line_number] == Temptag)
			begin
				way = line_number;
				line_number = LINES;
					
			end
			else
			  begin
				line_number = line_number+1;
				way = line_number;
			end
		end
	end
endtask

//Check LRU for the eviction
task CheckLRU;
//	input [31:0]l1_addr_new; 
	//reg [0:TAG_WIDTH-1]Temptag;
	//reg [0:INDEX_WIDTH-1]Tempindex;  
	output integer way;
	integer line_number;
	begin
		    Temptag = address [31:20];                        // Masking of Tag bits from the address
        Tempindex = address [19:6];                       // Masking of Index bits from the address
		
		line_number = 3'b000;
		while(line_number != LINES)
		begin
			if( LRU_bits[Tempindex][line_number] == 3'b000)
			begin
				way = line_number;
				line_number = LINES;
			end
			else
			  begin
				line_number = line_number+1;
				way = line_number;
			end
		end
	end
endtask

//Update the LRU bits
task update_LRU_miss;
  //input [31:0]address_temp;
	input integer LRU_line;
	//input miss_hit;
	//reg [31:0] l1_addr_new1;
	//reg [0:INDEX_WIDTH-1]Tempindex; 						
	integer  j,i; 
	begin
		//l1_addr_new1 = address_temp; 
		//$display("enter update lru miss");	
		Tempindex = address[19:6];                       // Masking of Index bits from the address
		//if(miss_hit == 1)
			for(j = 0; j< LINES; j= j+1)
			begin
				//$display("%d",LRU_line);
				if(LRU_line != j)
				  begin
					LRU_bits[Tempindex][j] = LRU_bits[Tempindex][j] - 1;
					end
				else
				  begin
					LRU_bits [Tempindex][LRU_line] = 3'b111;
				  end
			end 
		end
	endtask
		
task update_LRU_hit;
  //input [31:0]address_temp;
	input integer LRU_line;
	//input miss_hit;
	//reg [31:0] l1_addr_new1;
	//reg [0:INDEX_WIDTH-1]Tempindex; 						
	integer  j,i; 
	begin		
	 // l1_addr_new1 = address_temp;  
		Tempindex = address[19:6];                       // Masking of Index bits from the address
			for (i=0 ; i<LINES ; i=i+1)
			begin
				if(LRU_line != i)
				begin
					if(LRU_bits[Tempindex][LRU_line]<LRU_bits [Tempindex][i])
					begin
						LRU_bits [Tempindex][i] = LRU_bits [Tempindex][i] - 1;
					end	
				end
			end
			LRU_bits [Tempindex][LRU_line] =  3'b111;
		end
endtask


// Miss Function
task miss_func;
  //input [31:0]l1_addr_new;
  input integer way_miss;
  //integer cache_miss_1;
  //reg [0:TAG_WIDTH-1]Temptag;
	//reg [0:INDEX_WIDTH-1]Tempindex; 
         begin
			      $display("miss");
            Temptag = address [31:20];                        // Masking of Tag bits from the address
            Tempindex = address[19:6];                       // Masking of Index bits from the address
            tag_bits [Tempindex][way_miss] = Temptag;
            valid[Tempindex][way_miss] = 1'b1;
            dirty [Tempindex][way_miss] = 1'b0;
            cache_miss = cache_miss+1;
         end   
endtask

// Hit Function
task hit_func;  
  //input [31:0]l1_addr_new;
  input integer way_hit;
  //integer cache_hits;
  //integer temp_cache_hit;
  //reg[0:TAG_WIDTH-1]Temptag;
	//reg[0:INDEX_WIDTH-1]Tempindex; 
         begin
				//$display("hit");
            Temptag = address[31:20];                        // Masking of Tag bits from the address
            Tempindex = address [19:6];                       // Masking of Index bits from the address
            valid [Tempindex][way_hit] = 1'b1;
            dirty [Tempindex][way_hit] = 1'b0;
            cache_hits = cache_hits+1;
            
         end  
     endtask

task CheckValidity;
	//input [31:0]l1_addr_new;
	output integer way;
//	reg [0:TAG_WIDTH-1]Temptag;
	//reg [0:INDEX_WIDTH-1]Tempindex;
	//integer hit_miss;
	integer line_number;
	begin
		Temptag = address [31:20];                        // Masking of Tag bits from the address
    Tempindex = address [19:6];                       // Masking of Index bits from the address
		line_number = 0;
		while(line_number != LINES)
		begin
			if(valid[Tempindex][line_number] == 1'b0)
			begin
				way = line_number;
			//	$display("valid bit of line number = %d",line_number);
				line_number = LINES;
			end
			else
			  begin
				line_number = line_number+1;
				way = line_number;
			end
		end
	end
endtask

  
// Cache initialization
    task initialise;
      integer line_count;
      integer sets_count;
      begin
        //$display("enter initialize");
        //cache_read = 0;
        //cache_write = 0;
        cache_hits = 0;
        cache_miss = 0;
        //cache_hits_ratio = 0;
        //cache_miss_ratio = 0;
        
        for(sets_count=0 ; sets_count<SETS ; sets_count= sets_count + 1)
            begin 
              for(line_count=0 ; line_count<LINES ; line_count=line_count+1)
                begin
                  valid[sets_count][line_count] = 1'b0;   //??
                  dirty[sets_count][line_count] = 1'b0;
                  LRU_bits [sets_count][line_count] = line_count;
                  tag_bits[sets_count][line_count] = 12'bzzzzzzzzzzzz;
                  MESI [sets_count][line_count] = I;
                end
              end 
             end
           endtask

endmodule 


