module SingleCycleMIPS( 
    clk,
    rst_n,
    IR_addr,
    IR,
    ReadDataMem,
    CEN,
    WEN,
    A,
    Data2Mem,
    OEN
);

//==== in/out declaration =================================
    //-------- processor ----------------------------------
    input         clk, rst_n;
    input  [31:0] IR;
    output reg [31:0] IR_addr;
    //-------- data memory --------------------------------
    input  [31:0] ReadDataMem;  
    output    reg    CEN;  
    output    reg    WEN;  
    output  [6:0] A;  
    output [31:0] Data2Mem;  
    output    reg  OEN;  

//==== reg/wire declaration ===============================
    integer i;
    //lw/sw/branch
    wire signed [15:0] address;
    wire signed [31:0] address_ex, address_exs;
    //pc
    reg [31:0] PC_in,IR_addr_4,jump_addr,branch_addr;
    wire branchh;
    wire [31:0] shamt_ex;
    //reg
    reg signed [31:0] register[31:0];
    reg signed [31:0] n_register[31:0];
    reg signed [31:0] read_data_1,read_data_2;
    wire [4:0] rs, rt, rd, shamt;
    reg [4:0] write_i;
    //control
    wire [5:0] opcode, funct;
    reg RegDst, jump, branch, branch_n, mem2reg, ALUsrc, regwrite, storeRA, jumpReg, memread, memwrite;
    reg [1:0] ALUop;
    //ALU
    reg [3:0] ALU_control;
    wire signed [31:0] ALU_input;
    reg signed [31:0] ALU_output;
    reg zero;



//==== wire connection to submodule ======================
//Example:
//	ctrl control(
//	.clk(clk),
//	.rst_n(rst_n), ......

//	);

//==== combinational part =================================
    assign opcode = IR[31:26];
    assign rs = IR[25:21];
    assign rt = IR[20:16];
    assign rd = IR[15:11];
    assign shamt = IR[10:6];
    assign funct = IR[5:0];
    assign address = IR[15:0];
    assign address_ex[15:0] = address[15:0];
    assign address_ex[31:16] = (address[15])?16'b1111_1111_1111_1111:16'b0;
    assign address_exs = address_ex<<2;
    assign shamt_ex = {27'b000000000000000000000000000,shamt};
//control
always@(*)begin
    case(opcode)
        //add
        6'b000000:begin
            if(funct==6'h08)begin
           		RegDst = 1;
            	jump = 0;
            	jumpReg = 1;
            	storeRA = 0;
            	branch = 0;
            	branch_n = 0;
            	mem2reg = 0;
            	ALUsrc = 0;
            	regwrite = 0;
            	ALUop[1] = 1;
            	ALUop[0] = 0;
            	memread = 0;
                memwrite = 0;
                WEN = 0;
            	OEN = 1;
        	end
        	else begin
        		RegDst = 1;
            	jump = 0;
            	jumpReg = 0;
            	storeRA = 0;
            	branch = 0;
            	branch_n = 0;
            	mem2reg = 0;
            	ALUsrc = 0;
            	regwrite = 1;
            	ALUop[1] = 1;
            	ALUop[0] = 0;
            	memread = 0;
                memwrite = 0;
                WEN = 0;
            	OEN = 1;
        	end
        end
        //addi
        6'b001000:begin
            RegDst = 0;
            jump = 0;
            jumpReg = 0;
            storeRA = 0;
            branch = 0;
            branch_n = 0;
            mem2reg = 0;
            ALUsrc = 1;
            regwrite = 1;
            ALUop[1] = 0;
            ALUop[0] = 0;
            memread = 0;
            memwrite = 0;
            WEN = 0;
            OEN = 1;
        end
        //lw
        6'b100011:begin
            RegDst = 0;
            jump = 0;
            jumpReg = 0;
            storeRA = 0;
            branch = 0;
            branch_n = 0;
            OEN = 0;
            mem2reg = 1;
            WEN = 1;
            ALUsrc = 1;
            regwrite = 1;
            ALUop[1] = 0;
            ALUop[0] = 0;
            memread = 1;
            memwrite = 0;
        end
        //sw
        6'b101011:begin
            RegDst = 0;
            jump = 0;
            jumpReg = 0;
            storeRA = 0;
            branch = 0;
            branch_n = 0;
            OEN = 1;
            mem2reg = 0;
            WEN = 0;
            ALUsrc = 1;
            regwrite = 0;
            ALUop[1] = 0;
            ALUop[0] = 0;
            memwrite = 1;
            memread = 0;
        end
        //beq
        6'b000100:begin
            RegDst = 0;
            jump = 0;
            jumpReg = 0;
            storeRA = 0;
            branch = 1;
            branch_n = 0;
            mem2reg = 0;
            ALUsrc = 0;
            regwrite = 0;
            ALUop[1] = 0;
            ALUop[0] = 1;
            memread = 0;
            memwrite = 0;
            WEN = 0;
            OEN = 1;
        end
        //bne
        6'b000101:begin
            RegDst = 0;
            jump = 0;
            jumpReg = 0;
            storeRA = 0;
            branch = 0;
            branch_n = 1;
            mem2reg = 0;
            ALUsrc = 0;
            regwrite = 0;
            ALUop[1] = 0;
            ALUop[0] = 1;
            memread = 0;
            memwrite = 0;
            WEN = 0;
            OEN = 1;
        end
        //j
        6'b000010:begin
            RegDst = 0;
            jump = 1;
            jumpReg = 0;
            storeRA = 0;
            branch = 0;
            branch_n = 0;
            mem2reg = 0;
            ALUsrc = 0;
            regwrite = 0;
            ALUop[1] = 0;
            ALUop[0] = 0;
            memread = 0;
            memwrite = 0;
            WEN = 0;
            OEN = 1;
        end
        //jal*
        6'b000011:begin
            RegDst = 0;
            jump = 1;
            jumpReg = 0;
            storeRA = 1;
            branch = 0;
            branch_n = 0;
            mem2reg = 0;
            ALUsrc = 0;
            regwrite = 0;
            ALUop[1] = 0;
            ALUop[0] = 0;
            memwrite = 0;
            memread = 0;
            WEN = 0;
            OEN = 1;
        end


        default:begin
            RegDst = 1'bx;
            jump = 1'bx;
            jumpReg = 1'bx;
            storeRA = 1'bx;
            branch = 1'bx;
            branch_n = 1'bx;
            mem2reg = 1'bx;
            ALUsrc = 1'bx;
            regwrite = 1'bx;
            ALUop[1] = 1'bx;
            ALUop[0] = 1'bx;
            memwrite = 1'b0;
            memread = 1'b0;
            OEN = 0;
            WEN = 1;
        end
    endcase
end
//ALUcontrol
always@(*)begin
    case (ALUop)
        2'b00:begin
            ALU_control = 4'b0010;//lw//sw
        end
        2'b01:begin
            ALU_control = 4'b0110;//beq//bne
        end
        2'b10:begin
            case(funct)
                6'b000000:begin
                	ALU_control = 4'b0011;//sll
                end
                6'b000010:begin
                	ALU_control = 4'b0100;//srl
                end
                6'b100000:begin
                    ALU_control = 4'b0010;//add
                end
                6'b100010:begin
                    ALU_control = 4'b0110;//substract
                end
                6'b100100:begin
                    ALU_control = 4'b0000;//and
                end
                6'b100101:begin
                    ALU_control = 4'b0001;//or
                end
                6'b101010:begin
                    ALU_control = 4'b0111;//slt
                end
                default:ALU_control = 4'bxxxx;
             
            endcase 
        end
        default:ALU_control = 4'bxxxx;
    endcase   
end

//registers
always@(*)begin
    read_data_1 = register[rs];
    read_data_2 = register[rt];
    write_i = (RegDst==1)?rd:rt;
end 
//ALU
assign ALU_input = (ALUsrc==1)?address_ex:read_data_2;
always@(*)begin
   case (ALU_control)
   		4'b0000:begin//and
   			zero = 0;
   			ALU_output = ALU_input&read_data_1;
   		end
   		4'b0001:begin//or
   			zero = 0;
   			ALU_output = ALU_input|read_data_1;
   		end
   		4'b0010:begin//add
   			zero = 0;
   			ALU_output = ALU_input+read_data_1;
   		end
   		4'b0110:begin//subtract
   			zero = (ALU_input==read_data_1)?1:0;
   			ALU_output = read_data_1- ALU_input;
   		end
   		4'b0111:begin//slt
   			zero = 0;
   			ALU_output = (read_data_1<ALU_input)?1:0;
   		end
   		4'b0011:begin
   			zero = 0;
            ALU_output = ALU_input << shamt_ex;//sll
   		end
   		4'b0100:begin
   			zero = 0;
            ALU_output = ALU_input >> shamt_ex;//srl
   		end
    
        default : begin
        	zero = 1'bx;
        	ALU_output = 32'bx;
        end
    endcase
end 
assign A = ALU_output[8:2];
assign Data2Mem = read_data_2;
//write back
always@(*)begin
    CEN = ~((memread&~memwrite)|(~memread&memwrite));
    for(i=0;i<31;i=i+1)begin
        if((i==write_i)&&(regwrite==1))begin
            n_register[i] = (mem2reg)?ReadDataMem:ALU_output;
        end
        else begin
            n_register[i] = register[i];
        end
    end    
    //CEN = 1'b1;
end
//PC
assign branchh = (branch_n&~zero)|(branch&zero);
always@(*)begin
    IR_addr_4 = IR_addr+4;
    jump_addr = {IR_addr_4[31:28],IR[25:0],2'b00};
    branch_addr = IR_addr_4+address_exs;
    n_register[31] = (storeRA)?IR_addr_4:register[31];
    if(jumpReg)begin
        PC_in = register[rs];
    end
    else begin
        PC_in = (jump)?jump_addr:(branchh)?branch_addr:IR_addr_4;
    end
end
//==== sequential part ====================================
always@(posedge clk)begin
    if(rst_n==0)begin
        for(i = 0;i < 32; i=i+1)begin
            register[i] <= 0;
        end
        IR_addr<=0;
    end
    else begin
        for(i=0;i<32;i=i+1)begin
            register[i] <= n_register[i];
        end
        IR_addr<=PC_in;
	end

end

endmodule

// recommend you to use submodule for easier debugging 
//=========================================================
//Example:
//	module ctrl(
//		clk,
//		rst_n, ....


//	);





//	endmodule
 

		