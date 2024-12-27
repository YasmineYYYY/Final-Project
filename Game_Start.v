/* -----START开始界面----- */

module Game_Start(
    input         vga_clk_25,       
    input         rst_n,           
    input  [ 9:0] pixel_xpos,      
    input  [ 9:0] pixel_ypos,      
    
    output [15:0] pixel_data     
);

// 参数定义
parameter   H_DISP  = 10'd640;          // 分辨率--行 
parameter   V_DISP  = 10'd480;          // 分辨率--列

localparam  START_X = 10'd267;          // 图片区域起始横坐标
localparam  START_Y = 10'd126;          // 图片区域起始纵坐标
localparam  PHOTO_H = 10'd160;          // 待显图片的水平宽度，图片像素155*100
localparam  PHOTO_V = 10'd100;          // 待显图片的垂直高度
localparam  PHOTO   = 16'd16000;        // 图片区域总像素数

localparam  WHITE  = 16'hFFFF;  // RGB565 白色
localparam  BLANK  = 16'h0000;  // RGB565 黑色
localparam  RED    = 16'hF100;  // RGB565 红色
localparam  GREEN  = 16'h0400;  // RGB565 绿色
localparam  BLUE   = 16'h001F;  // RGB565 蓝色
localparam  YELLOW = 16'hFFE0;  // RGB565 黄色
localparam  PURPLE = 16'h8010;  // RGB565 紫色
localparam  BROWN  = 16'hE618;  // RGB565 棕色

// 内部变量定义
reg  [16:0] rom_addr;    // 读ROM地址
reg         rom_valid;  

wire [15:0] rom_data;    // ROM输出的数据
wire        rom_rd_en;   // 读ROM使能信号

/* -----main code----- */

// 例化ROM_IP核
pic_rom	u_pic_rom(
    .clock      (vga_clk_25),
	.address    (rom_addr  ),   // 读ROM地址
	.rden       (rom_rd_en ),   // 读ROM使能信号
    
	.q          (rom_data  )    // ROM输出有效数据
);

// ROM输出数据
assign rom_rd_en = ( ((pixel_xpos >= START_X) && (pixel_xpos < START_X + PHOTO_H))
                   && ((pixel_ypos >= START_Y) && (pixel_ypos < START_Y + PHOTO_V)) )
                   ? 1'b1 : 1'b0;
                   
// 在有效显示区，进行数据输出
assign pixel_data = rom_valid ? rom_data : WHITE;
//assign pixel_data = rom_data;
// 控制ROM读数据的地址
always @(posedge vga_clk_25 or negedge rst_n)
begin
    if(!rst_n)
        rom_addr <= 16'd0;
    else begin
        if(rom_rd_en) begin
            if(rom_addr == PHOTO - 1'b1)
                rom_addr <= 16'd0;              // 读完有效数据后，即读到ROM有效末地址后，从首地址重新开始读操作
            else    
                rom_addr <= rom_addr + 16'd1;   // 每次ROM数据后，读地址+1
        end
        else 
            rom_addr <= rom_addr;
    end
end

// 对读使能信号rom_rd_en延时一个VGA时钟周期
always @(posedge vga_clk_25 or negedge rst_n)
begin
    if(!rst_n)
        rom_valid <= 1'b0;
    else 
        rom_valid <= rom_rd_en;
end

endmodule 