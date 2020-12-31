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
    reg [4:0] write_i,write_i_f;
    //control
    wire [5:0] opcode, funct;
    reg RegDst, jump, branch, branch_n, mem2reg, ALUsrc, regwrite, storeRA, jumpReg, memread, memwrite;
    reg [2:0] ALUop;
    //ALU
    reg [3:0] ALU_control;
    wire signed [31:0] ALU_input;
    reg signed [31:0] ALU_output;
    reg zero;
//============FP===============================================
    reg signed [31:0] ALU_output_2;
    wire [4:0] fmt,ft,fs,fd;
    reg signed [31:0] fpreg[31:0];
    reg signed [31:0] n_fpreg[31:0];
    reg inte,single,double,fpcond,n_fpcond,double_2,n_double_2;
    wire [2:0] rnd;
    reg signed [31:0] read_data_1_s,read_data_2_s;
    reg signed [63:0] read_data_1_d,read_data_2_d;
    wire [31:0] addout_s, subout_s, mulout_s, divout_s;
    wire [63:0] addout_d, subout_d;
    wire [7:0] addstatus_s, addstatus_d, substatus_s, substatus_d, mulstatus_s, divstatus_s;
//==== wire connection to submodule ======================
//Example:
//	ctrl control(
//	.clk(clk),
//	.rst_n(rst_n), ......

//	);
    DW_fp_add single_add(.a(read_data_1_s),.b(read_data_2_s),.rnd(rnd),.z(addout_s),.status(addstatus_s));
    DW_fp_sub single_sub(.a(read_data_1_s),.b(read_data_2_s),.rnd(rnd),.z(subout_s),.status(substatus_s));
    DW_fp_mult single_mult(.a(read_data_1_s),.b(read_data_2_s),.rnd(rnd),.z(mulout_s),.status(mulstatus_s));
    DW_fp_div single_div(.a(read_data_1_s),.b(read_data_2_s),.rnd(rnd),.z(divout_s),.status(divstatus_s));
    DW_fp_add #(52,11,0) double_add(.a(read_data_1_d),.b(read_data_2_d),.rnd(rnd),.z(addout_d),.status(addstatus_d));
    DW_fp_sub #(52,11,0) double_sub(.a(read_data_1_d),.b(read_data_2_d),.rnd(rnd),.z(subout_d),.status(substatus_d));
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
//fp
    assign rnd = 3'b000;
    assign fmt = IR[25:21];
    assign ft = IR[20:16];
    assign fs = IR[15:11];
    assign fd = IR[10:6];
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
            	ALUop[2] = 0;
                ALUop[1] = 1;
            	ALUop[0] = 0;
            	inte = 1;
                single = 0;
                double = 0;
                n_double_2 = 0;
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
            	ALUop[2] = 0;
                ALUop[1] = 1;
            	ALUop[0] = 0;
            	inte = 1;
                single = 0;
                double = 0;
                n_double_2 = 0;
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
            ALUop[2] = 0;
            ALUop[1] = 0;
            ALUop[0] = 0;
            inte = 1;
            single = 0;
            double = 0;
            n_double_2 = 0;
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
            ALUop[2] = 0;
            ALUop[1] = 0;
            ALUop[0] = 0;
            inte = 1;
            single = 0;
            double = 0;
            n_double_2 = 0;
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
            ALUop[2] = 0;
            ALUop[1] = 0;
            ALUop[0] = 0;
            inte = 1;
            single = 0;
            double = 0;
            n_double_2 = 0;
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
            ALUop[2] = 0;
            ALUop[1] = 0;
            ALUop[0] = 1;
            inte = 1;
            single = 0;
            double = 0;
            n_double_2 = 0;
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
            ALUop[2] = 0;
            ALUop[1] = 0;
            ALUop[0] = 1;
            inte = 1;
            single = 0;
            double = 0;
            n_double_2 = 0;
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
            ALUop[2] = 0;
            ALUop[1] = 0;
            ALUop[0] = 0;
            inte = 1;
            single = 0;
            double = 0;
            n_double_2 = 0;
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
            ALUop[2] = 0;
            ALUop[1] = 0;
            ALUop[0] = 0;
            inte = 1;
            single = 0;
            double = 0;
            n_double_2 = 0;
            memwrite = 0;
            memread = 0;
            WEN = 0;
            OEN = 1;
        end
        6'b010001:begin//single add/sub/mul/div
            if(fmt==5'h10)begin
                RegDst = 1;
                jump = 0;
                jumpReg = 0;
                storeRA = 0;
                branch = 0;
                branch_n = 0;
                mem2reg = 0;
                ALUsrc = 0;
                regwrite = 1;
                ALUop[2] = 1;
                ALUop[1] = 0;
                ALUop[0] = 0;
                inte = 0;
                single = 1;
                double = 0;
                n_double_2 = 0;
                memread = 0;
                memwrite = 0;
                WEN = 0;
                OEN = 1;
            end
            else if(fmt==5'h8)begin//single bclt
                RegDst = 0;
                jump = 0;
                jumpReg = 0;
                storeRA = 0;
                branch = 1;
                branch_n = 0;
                mem2reg = 0;
                ALUsrc = 0;
                regwrite = 0;
                ALUop[2] = 1;
                ALUop[1] = 0;
                ALUop[0] = 1;
                inte = 0;
                single = 1;
                double = 0;
                n_double_2 = 0;
                memread = 0;
                memwrite = 0;
                WEN = 0;
                OEN = 1;
            end
            else begin//double add/sub
                RegDst = 1;
                jump = 0;
                jumpReg = 0;
                storeRA = 0;
                branch = 0;
                branch_n = 0;
                mem2reg = 0;
                ALUsrc = 0;
                regwrite = 1;
                ALUop[2] = 1;
                ALUop[1] = 1;
                ALUop[0] = 0;
                inte = 0;
                single = 0;
                double = 1;
                n_double_2 = 0;
                memread = 0;
                memwrite = 0;
                WEN = 0;
                OEN = 1;
            end
        end
        6'b110001:begin//lwcl
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
            ALUop[2] = 0;
            ALUop[1] = 0;
            ALUop[0] = 0;
            inte = 0;
            single = 1;
            double = 0;
            n_double_2 = 0;
            memread = 1;
            memwrite = 0;
        end
        6'b111001:begin//swcl
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
            ALUop[2] = 0;
            ALUop[1] = 0;
            ALUop[0] = 0;
            inte = 0;
            single = 1;
            double = 0;
            n_double_2 = 0;
            memread = 0;
            memwrite = 1;
        end
        6'b110101:begin//ldcl
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
            ALUop[2] = 0;
            ALUop[1] = 0;
            ALUop[0] = 0;
            inte = 0;
            single = 0;
            double = 1;
            n_double_2 = ~double_2;
            memread = 1;
            memwrite = 0;
        end
        6'b111101:begin//sdcl
            RegDst = 0;
            jump = 0;
            jumpReg = 0;
            storeRA = 0;
            branch = 0;
            branch_n = 0;
            OEN = 1;
            mem2reg = 1;
            WEN = 0;
            ALUsrc = 1;
            regwrite = 1;
            ALUop[2] = 0;
            ALUop[1] = 0;
            ALUop[0] = 0;
            inte = 0;
            single = 0;
            double = 1;
            n_double_2 = ~double_2;
            memread = 0;
            memwrite = 1;
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
            ALUop[2] = 1'bx;
            ALUop[1] = 1'bx;
            ALUop[0] = 1'bx;
            inte = 1'bx;
            single = 1'bx;
            double = 1'bx;
            n_double_2 = 1'bx;
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
        3'b000:begin
            ALU_control = 4'b0010;//lw//sw
        end
        3'b001:begin
            ALU_control = 4'b0110;//beq//bne
        end
        3'b010:begin
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
        3'b100:begin
            case(funct)
                6'b000000:begin//add
                    ALU_control = 4'b1000;
                end
                6'b000001:begin//sub
                    ALU_control = 4'b1001;
                end
                6'b000010:begin//mul
                    ALU_control = 4'b1010;
                end
                6'b000011:begin//div
                    ALU_control = 4'b1011;
                end
                6'b110010:begin//c.eq.s
                    ALU_control = 4'b1100;
                end
                default:ALU_control = 4'bxxxx;
            endcase
        end
        3'b101:begin//bclt
            ALU_control = 4'b1101;
        end
        3'b110:begin//double
            case(funct)
                6'b000000:ALU_control = 4'b1110;
                6'b000001:ALU_control = 4'b1111;
            endcase 
        end
        default:ALU_control = 4'bxxxx;
    endcase   
end

//registers
always@(*)begin
    read_data_1 = register[rs];
    read_data_2 = register[rt];
    read_data_1_s = fpreg[fs];
    read_data_2_s = fpreg[ft];
    read_data_1_d = {fpreg[fs],fpreg[fs+1]};
    read_data_2_d = {fpreg[ft],fpreg[ft+1]};
    write_i = (RegDst==1)?rd:rt;
    write_i_f = (RegDst==1)?fd:((double_2)?(rt+1):rt);
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
        4'b1000:begin
            zero = 0;
            ALU_output = addout_s;
        end
        4'b1001:begin
            zero = 0;
            ALU_output = subout_s;
        end
        4'b1010:begin
            zero = 0;
            ALU_output = mulout_s;
        end
        4'b1011:begin
            zero = 0;
            ALU_output = divout_s;
        end
        4'b1100:begin
            zero = (subout_s==0)?1:0;
            ALU_output = 32'bx;
        end
        4'b1101:begin
            zero = fpcond;
            ALU_output = 32'bx;
        end
        4'b1110:begin
            zero = 0;
            ALU_output = addout_d [63:32];
        end
        4'b1111:begin
            zero = 0;
            ALU_output = subout_d [63:32];
        end
        default : begin
        	zero = 1'bx;
        	ALU_output = 32'bx;
        end
    endcase
    n_fpcond = (ALU_control==4'b1100)?zero:0;
    if(ALU_control==4'b1110)begin
        ALU_output_2 = addout_d[31:0];
    end
    else if (ALU_control==4'b1111) begin
        ALU_output_2 = subout_d[31:0];
    end
    else begin
        ALU_output_2 = 32'b0;
    end
end 
assign A = (double_2)?(ALU_output[8:2]+1):ALU_output[8:2];
assign Data2Mem = (inte)?read_data_2:((double_2)?fpreg[rt+1]:fpreg[rt]);
//write back
always@(*)begin
    CEN = ~((memread&~memwrite)|(~memread&memwrite));
    for(i=0;i<32;i=i+1)begin
        if((inte==1)&&(i==write_i)&&(regwrite==1))begin
            n_register[i] = (mem2reg)?ReadDataMem:ALU_output;
        end
        else begin
            n_register[i] = register[i];
        end
    end    
    for(i=0;i<32;i=i+1)begin
        if((single|double ==1)&&(i==write_i_f )&&(regwrite==1))begin
                if(opcode==6'h11&&fmt==5'h11&&mem2reg==0)begin
                    n_fpreg[i] = (mem2reg)?ReadDataMem:ALU_output;
                    n_fpreg[i+1] = (mem2reg)?ReadDataMem:ALU_output_2;
                    i = i+1;
                end
                else begin    
                    n_fpreg[i] = (mem2reg)?ReadDataMem:ALU_output;
                end
            //      $display(i,double_2,ALU_output_2);
        end
        else begin
            n_fpreg[i] = fpreg[i];
        end
    end
    /*for(i=0;i<32;i=i+1)begin
        if((double==1)&&(i==write_i_f)&&(regwrite==1)&&(double_2==0))begin
            n_fpreg[i] = (mem2reg)?ReadDataMem:ALU_output;
        end
        else begin
            n_fpreg[i] = fpreg[i];
        end
    end
    for(i=0;i<32;i=i+1)begin
        if((double==1)&&(i==(write_i_f+1))&&(regwrite==1)&&(double_2==1))begin
            n_fpreg[i] = (mem2reg)?ReadDataMem:ALU_output_2;
        end
        else begin
            n_fpreg[i] = fpreg[i];
        end
    end*/

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
        PC_in = (n_double_2)?IR_addr:((jump)?jump_addr:(branchh)?branch_addr:IR_addr_4);
    end
end
//==== sequential part ====================================
always@(posedge clk)begin
    if(rst_n==0)begin
        for(i = 0;i < 32; i=i+1)begin
            register[i] <= 0;
            fpreg[i] <= 0;
        end
        IR_addr<=0;
        fpcond <=0;
        double_2 <= 0;
    end
    else begin
        for(i=0;i<32;i=i+1)begin
            register[i] <= n_register[i];
            fpreg[i] <= n_fpreg[i];
        end
        IR_addr<=PC_in;
        fpcond <= n_fpcond;
        double_2 <= n_double_2;
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
 

		