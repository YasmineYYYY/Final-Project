/* -----VGA驱动模块，根据输入的当前状态模式，负责切换START->SPEED->PLAY->END四种不同的显示界面----- */

module VGA_Driver(
    input         vga_clk_25,   
    input         rst_n,       
    input  [ 3:0] state_m,      // 接收当前状态模式，用于选择显示界面
    input  [15:0] data_start,   // START界面传输的数据
    input  [15:0] data_speed,   // SPEED界面传输的数据 
    input  [15:0] data_play,    // PLAY界面传输的数据
    input  [15:0] data_end,     // END界面传输的数据
                
    //output [23:0] vga_rgb,     
    output [15:0] vga_rgb,
    output        vga_hs,     
    output        vga_vs,    
    output        vga_blank,    // 场消隐信号
    output [ 9:0] pixel_xpos,  
    output [ 9:0] pixel_ypos   
);
//sjld
// 参数定义 
parameter  H_SYNC   =  10'd96;    // 行同步
parameter  H_BACK   =  10'd48;    // 行显示后沿
parameter  H_DISP   =  10'd640;   // 行有效数据
parameter  H_FRONT  =  10'd16;    // 行显示前沿
parameter  H_TOTAL  =  10'd800;   // 行扫描周期

parameter  V_SYNC   =  10'd2;     // 场同步
parameter  V_BACK   =  10'd33;    // 场显示后沿
parameter  V_DISP   =  10'd480;   // 场有效数据
parameter  V_FRONT  =  10'd10;    // 场显示前沿
parameter  V_TOTAL  =  10'd525;   // 场扫描周期
// 四种状态模式参数定义
localparam START = 4'b0001;
localparam SPEED = 4'b0010;
localparam PLAY  = 4'b0100;
localparam END   = 4'b1000;

// 内部变量定义
reg [ 9:0] H_cnt;   // 行计数器
reg [ 9:0] V_cnt;   // 场计数器
reg [15:0] vga_m;   

wire vga_en;        // VGA有效像素点显示区标定
wire pixel_req;     

/* -----main code----- */

// 行/场同步信号
assign vga_hs = (H_cnt >= H_SYNC) ? 1'b1 : 1'b0; 
assign vga_vs = (V_cnt >= V_SYNC) ? 1'b1 : 1'b0; 

// 有效像素显示区
assign vga_en = (((H_cnt >= (H_SYNC+H_BACK)) && (H_cnt < (H_TOTAL-H_FRONT)))
                 && ((V_cnt >= (V_SYNC+V_BACK)) && (V_cnt < (V_TOTAL-V_FRONT))))
                 ? 1'b1 : 1'b0;
assign vga_blank = vga_en;  
                    
// 判断在不同模式下，屏幕选择显示不同界面 
assign vga_rgb = vga_m;
always @(posedge vga_clk_25 or negedge rst_n)
begin
    if(!rst_n) 
        vga_m <= 16'd0;
    else if(vga_en) begin
        case(state_m)
            START:   vga_m <= data_start;
            SPEED:   vga_m <= data_speed;
            PLAY :   vga_m <= data_play;  
            END  :   vga_m <= data_end;
            default: vga_m <= data_start;
        endcase
    end
    else
        vga_m <= 16'd0;
end                

// 返回像素点的坐标值
assign pixel_req = (((H_cnt >= (H_SYNC+H_BACK-10'd1)) && (H_cnt < (H_TOTAL-H_FRONT-10'd1)))
                 && ((V_cnt >= (V_SYNC+V_BACK)) && (V_cnt < (V_TOTAL-V_FRONT))))
                 ? 1'b1 : 1'b0;
assign pixel_xpos = pixel_req ? (H_cnt - (H_SYNC+H_BACK-10'd1)) : 10'd0;
assign pixel_ypos = pixel_req ? (V_cnt - (V_SYNC+V_BACK-10'd1)) : 10'd0;              

// 行计数器对vga时钟计数
always @(posedge vga_clk_25 or negedge rst_n)
begin
    if(!rst_n) begin
        H_cnt <= 10'd0;
    end
    else begin
        if(H_cnt == H_TOTAL - 10'd1) 
            H_cnt <= 10'd0;
        else 
            H_cnt <= H_cnt + 10'd1;
    end

end

// 场计数器对行计数
always @(posedge vga_clk_25 or negedge rst_n)
begin
    if(!rst_n) begin
        V_cnt <= 10'd0;
    end
    else if(H_cnt == H_TOTAL - 10'd1) begin
        if(V_cnt == V_TOTAL - 10'd1) 
            V_cnt <= 10'd0;
        else 
            V_cnt <= V_cnt + 10'd1;
    end
    else 
        V_cnt <= V_cnt;
end

endmodule 