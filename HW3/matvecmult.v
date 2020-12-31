module matvecmult(
    CLK,
    RST,
    vector_x,
    vector_b,
    vector_y,
    Q,
    A,
    finish
);

input               CLK;
input               RST;
input       [127:0]	vector_x;
input       [127:0]	vector_b;
output  reg [127:0]	vector_y;
input       [127:0]	Q;
output  reg [3:0]   A;
output  reg         finish;

integer i;
integer j;
reg [7:0] vector_x_w[0:15],vector_x_r[0:15];
reg [7:0] vector_b_w[0:15],vector_b_r[0:15];
reg [7:0] vector_y_w[0:15],vector_y_r[0:15];
reg [7:0] part_matrix_a_w[0:15],part_matrix_a_r[0:15];
reg       finish_w,finish_r;
reg [3:0] counter_w,counter_r;
reg [7:0] temp;


always @(*) begin
    vector_x_w[0] = vector_x[7:0];
    vector_x_w[1] = vector_x[15:8];
    vector_x_w[2] = vector_x[23:16];
    vector_x_w[3] = vector_x[31:24];
    vector_x_w[4] = vector_x[39:32];
    vector_x_w[5] = vector_x[47:40];
    vector_x_w[6] = vector_x[55:48];
    vector_x_w[7] = vector_x[63:56];
    vector_x_w[8] = vector_x[71:64];
    vector_x_w[9] = vector_x[79:72];
    vector_x_w[10] = vector_x[87:80];
    vector_x_w[11] = vector_x[95:88];
    vector_x_w[12] = vector_x[103:96];
    vector_x_w[13] = vector_x[111:104];
    vector_x_w[14] = vector_x[119:112];
    vector_x_w[15] = vector_x[127:120];
    vector_b_w[0] = vector_b[7:0];
    vector_b_w[1] = vector_b[15:8];
    vector_b_w[2] = vector_b[23:16];
    vector_b_w[3] = vector_b[31:24];
    vector_b_w[4] = vector_b[39:32];
    vector_b_w[5] = vector_b[47:40];
    vector_b_w[6] = vector_b[55:48];
    vector_b_w[7] = vector_b[63:56];
    vector_b_w[8] = vector_b[71:64];
    vector_b_w[9] = vector_b[79:72];
    vector_b_w[10] = vector_b[87:80];
    vector_b_w[11] = vector_b[95:88];
    vector_b_w[12] = vector_b[103:96];
    vector_b_w[13] = vector_b[111:104];
    vector_b_w[14] = vector_b[119:112];
    vector_b_w[15] = vector_b[127:120];
    part_matrix_a_w[0] = Q[7:0];
    part_matrix_a_w[1] = Q[15:8];
    part_matrix_a_w[2] = Q[23:16];
    part_matrix_a_w[3] = Q[31:24];
    part_matrix_a_w[4] = Q[39:32];
    part_matrix_a_w[5] = Q[47:40];
    part_matrix_a_w[6] = Q[55:48];
    part_matrix_a_w[7] = Q[63:56];
    part_matrix_a_w[8] = Q[71:64];
    part_matrix_a_w[9] = Q[79:72];
    part_matrix_a_w[10] = Q[87:80];
    part_matrix_a_w[11] = Q[95:88];
    part_matrix_a_w[12] = Q[103:96];
    part_matrix_a_w[13] = Q[111:104];
    part_matrix_a_w[14] = Q[119:112];
    part_matrix_a_w[15] = Q[127:120];
    for(i=0;i<=15;i=i+1) begin
        vector_y_w[i] = vector_y_r[i];
    end
    temp =  2*part_matrix_a_w[15]*vector_x_w[0]+
            2*part_matrix_a_w[14]*vector_x_w[1]+
            2*part_matrix_a_w[13]*vector_x_w[2]+
            2*part_matrix_a_w[12]*vector_x_w[3]+
            2*part_matrix_a_w[11]*vector_x_w[4]+
            2*part_matrix_a_w[10]*vector_x_w[5]+
            2*part_matrix_a_w[9]*vector_x_w[6]+
            2*part_matrix_a_w[8]*vector_x_w[7]+
            2*part_matrix_a_w[7]*vector_x_w[8]+
            2*part_matrix_a_w[6]*vector_x_w[9]+
            2*part_matrix_a_w[5]*vector_x_w[10]+
            2*part_matrix_a_w[4]*vector_x_w[11]+
            2*part_matrix_a_w[3]*vector_x_w[12]+
            2*part_matrix_a_w[2]*vector_x_w[13]+
            2*part_matrix_a_w[1]*vector_x_w[14]+
            2*part_matrix_a_w[0]*vector_x_w[15];
    finish_w = 1'b0;
    counter_w = counter_r;

    if(RST)
        counter_w = 1'b0;
    else if(counter_r<4'b1111) begin
        i = counter_r;
        vector_y_w[i] = vector_y_r[i]+temp+vector_b_w[i];
        counter_w = counter_r+1'b1;
    end
    else begin
        finish_w = 1'b1;
        if(finish_r==1'b0)
            vector_y_w[15] = vector_y_r[15]+temp+vector_b_w[15];
        else
            vector_y_w[15] = vector_y_r[15];
    end
    finish = finish_r;
    A = counter_w;
    vector_y = {vector_y_r[15],vector_y_r[14],vector_y_r[13],vector_y_r[12],vector_y_r[11],vector_y_r[10],vector_y_r[9],vector_y_r[8],vector_y_r[7],vector_y_r[6],vector_y_r[5],vector_y_r[4],vector_y_r[3],vector_y_r[2],vector_y_r[1],vector_y_r[0]};
end


always @(posedge CLK or posedge RST) begin
    if (RST) begin
        // reset
        counter_r <= 1'b0;
        finish_r <= 1'b0;
        for(i=0;i<=15;i=i+1) begin
            part_matrix_a_r[i]<=1'b0;
            vector_y_r[i]<=1'b0;
        end
    end
    else begin
        counter_r <= counter_w;
        finish_r <= finish_w;
        for(i=0;i<=15;i=i+1) begin
            part_matrix_a_r[i]<=part_matrix_a_w[i];
            vector_y_r[i]<=vector_y_w[i];
        end

    end

end

endmodule