/* -----SPEED速度选择界面----- */

module Game_Speed(
    input            vga_clk_25,       
    input            rst_n,           
    input     [ 9:0] pixel_xpos,       
    input     [ 9:0] pixel_ypos,        
    
    output reg[16:0] pixel_data      
);
 
// 参数定义
parameter   H_DISP  = 10'd640;          // 分辨率--行 
parameter   V_DISP  = 10'd480;          // 分辨率--列
// ROW1
localparam  ROW1_X  = 10'd256;          // ROW1区域起始横坐标
localparam  ROW1_Y  = 10'd160;          // ROW1区域起始纵坐标
localparam  ROW1_H  = 10'd128;          // ROW1区水平长度
localparam  ROW1_V  = 10'd32;           // ROW1区垂直高度
// ROW2
localparam  ROW2_X  = 10'd258;          // ROW2区域起始横坐标
localparam  ROW2_Y  = 10'd210;          // ROW2区域起始纵坐标
localparam  ROW2_H  = 10'd120;          // ROW2区水平长度
localparam  ROW2_V  = 10'd24;           // ROW2区垂直高度
// ROW3
localparam  ROW3_X  = 10'd258;          // ROW3区域起始横坐标
localparam  ROW3_Y  = 10'd240;          // ROW3区域起始纵坐标
localparam  ROW3_H  = 10'd120;          // ROW3区水平长度
localparam  ROW3_V  = 10'd24;           // ROW3区垂直高度
// ROW4
localparam  ROW4_X  = 10'd258;          // ROW4区域起始横坐
localparam  ROW4_Y  = 10'd270;          // ROW4区域起始纵坐
localparam  ROW4_H  = 10'd120;          // ROW4区水平长度
localparam  ROW4_V  = 10'd24;           // ROW4区垂直高度
// ROW5
localparam  ROW5_X  = 10'd258;          // ROW5区域起始横坐
localparam  ROW5_Y  = 10'd300;          // ROW5区域起始纵坐
localparam  ROW5_H  = 10'd120;          // ROW5区水平长度
localparam  ROW5_V  = 10'd24;           // ROW5区垂直高度

// RGB565颜色值
localparam  WHITE  = 16'hFFFF;  // RGB565 白色
localparam  BLANK  = 16'h0000;  // RGB565 黑色
localparam  RED    = 16'hF800;  // RGB565 红色
localparam  GREEN  = 16'h0400;  // RGB565 绿色
localparam  BLUE   = 16'h001F;  // RGB565 蓝色
localparam  YELLOW = 16'hFFE0;  // RGB565 黄色
localparam  PURPLE = 16'h8010;  // RGB565 紫色
localparam  BROWN  = 16'hE618;  // RGB565 棕色

// 内部变量定义
reg [127:0] row_1 [31:0];   // 待显示第一行，“速度选择”---32*32
reg [119:0] row_2 [23:0];   // 待显示第二行，“上键：超快”--24*24
reg [119:0] row_3 [23:0];   // 待显示第一行，“下健：普快”--24*24
reg [119:0] row_4 [23:0];   // 待显示第一行，“左健：普慢”--24*24
reg [119:0] row_5 [23:0];   // 待显示第一行，“右健：超慢”--24*24
wire [9:0] x1_cnt;          // 相对于ROW1区域起始点的横坐标
wire [9:0] y1_cnt;          // 相当于ROW1区域起始点的纵坐标
wire [9:0] x2_cnt;          // 相对于ROW2区域起始点的横坐标
wire [9:0] y2_cnt;          // 相当于ROW2区域起始点的纵坐标 
wire [9:0] x3_cnt;          // 相对于ROW3区域起始点的横坐标
wire [9:0] y3_cnt;          // 相当于ROW3区域起始点的纵坐标 
wire [9:0] x4_cnt;          // 相对于ROW3区域起始点的横坐标
wire [9:0] y4_cnt;          // 相当于ROW3区域起始点的纵坐标 
//wire [9:0] x5_cnt;          // 相对于ROW3区域起始点的横坐标
//wire [9:0] y5_cnt;          // 相当于ROW3区域起始点的纵坐标 

/* -----main code----- */
 
// 获得显示汉字区域的X/Y坐标
assign x1_cnt = pixel_xpos - ROW1_X;
assign y1_cnt = pixel_ypos - ROW1_Y;
assign x2_cnt = pixel_xpos - ROW2_X;
assign y2_cnt = pixel_ypos - ROW2_Y;
assign x3_cnt = pixel_xpos - ROW3_X;
assign y3_cnt = pixel_ypos - ROW3_Y;
assign x4_cnt = pixel_xpos - ROW4_X;
assign y4_cnt = pixel_ypos - ROW4_Y;
assign x5_cnt = pixel_xpos - ROW5_X;
assign y5_cnt = pixel_ypos - ROW5_Y;


// 字段1：“速度选择”;  字段2：“上键：快速”;  字段3：“下健：慢速”
always @(posedge vga_clk_25)
begin
   /*  row_1[0]  <= 128'h00000000000000000000000000000000;
    row_1[1]  <= 128'h00000000000000000000000000000000;
    row_1[2]  <= 128'h00000000000000000000400001800000;
    row_1[3]  <= 128'h000060000001C0000000300000E00000;
    row_1[4]  <= 128'h000030000000E0000000300000E00380;
    row_1[5]  <= 128'h00002000000060000000300000403FC0;
    row_1[6]  <= 128'h0300200000001F00070230000043E380;
    row_1[7]  <= 128'h01C027000001FC000383300000400300;
    row_1[8]  <= 128'h00E1FF00007F00000183300000410600;
    row_1[9]  <= 128'h0067A00000601C0000823F000040CC00;
    row_1[10] <= 128'h00002100006408000006FC0000783800;
    row_1[11] <= 128'h00003FC000460BC00005F00001E03800;
    row_1[12] <= 128'h000FE1800046FF00000430000FC07E00;
    row_1[13] <= 128'h00042180005F980000083FC00040C780;
    row_1[14] <= 128'h0784210000C210000380FE000051B1E0;
    row_1[15] <= 128'h3F867F0000C238000FBF9800006618FC;
    row_1[16] <= 128'h0303E00000C3C0000300D80000C01878;
    row_1[17] <= 128'h0200600000C000000301980001C01F00;
    row_1[18] <= 128'h0200FC0000803C00030198000341FC00;
    row_1[19] <= 128'h0301A7000187DC00030310000E401800;
    row_1[20] <= 128'h010323800184180003021020384018E0;
    row_1[21] <= 128'h01862080010618000106103030407FF0;
    row_1[22] <= 128'h0188200003033000010C1830004FF800;
    row_1[23] <= 128'h013060000201B00001100FF000401800;
    row_1[24] <= 128'h0FE020000600E0000FC003E002C01800;
    row_1[25] <= 128'h3C3E20000400F0003C3E000001C01800;
    row_1[26] <= 128'h0007F80008039C000003F80E01C01800;
    row_1[27] <= 128'h00007FFC100E0F800000FFF800C01800;
    row_1[28] <= 128'h00000FE0203807F800001FE000001800;
    row_1[29] <= 128'h00000100004001FC0000000000000800;
    row_1[30] <= 128'h00000000000000000000000000000800;
    row_1[31] <= 128'h00000000000000000000000000000000; */
    
	row_1[1]  <= 128'h00000000000000000000000000000000 ;
	row_1[2]  <= 128'h00000000000000000600000000c07000 ;
	row_1[3]  <= 128'h00003c000003c00007c01e0001f0f000 ;
	row_1[4]  <= 128'h3c003c000003e00007801e0001f07800 ;
	row_1[5]  <= 128'h3e0038000f01e03c03871e1c01e07800 ;
	row_1[6]  <= 128'h1f3c383c0ffffffc038f1e1e03c03800 ;
	row_1[7]  <= 128'h0f3ffffc0e00001c03879e3e03c03c00 ;
	row_1[8]  <= 128'h0fbc383c0e0006000387de3c07be3c7c ;
	row_1[9]  <= 128'h07c038000e1e0780739fde7807bffffc ;
	row_1[10] <= 128'h039c38780e1e07007ffdfef00fbe007c ;
	row_1[11] <= 128'h001ffff80fde0738779dfff00f800000 ;
	row_1[12] <= 128'h001c38780ffffff80780dfe01f800000 ;
	row_1[13] <= 128'h719c38780fde073807c01e403f8600c0 ;
	row_1[14] <= 128'h7f9c38780e1e07000feffffc7f8f00f0 ;
	row_1[15] <= 128'h679c38780e1e07000ffffffc7f8f00f0 ;
	row_1[16] <= 128'h079c38780e1fff001ffe003cff8701e0 ;
	row_1[17] <= 128'h079ffff80e1c03001ff8003c378781e0 ;
	row_1[18] <= 128'h079dfe780ef001e03fbc003c078381e0 ;
	row_1[19] <= 128'h0781ff000effffe03fb8003c0783c1c0 ;
	row_1[20] <= 128'h0783ffc00ede03c07b87803c0783c3c0 ;
	row_1[21] <= 128'h0787bbe00e0f07c07b87fffc0781c3c0 ;
	row_1[22] <= 128'h078f39f00e0f8f80f387c03c0781e380 ;
	row_1[23] <= 128'h079f38f81e07df003380003c0781e380 ;
	row_1[24] <= 128'h07fe38781e03fe000380003c0780e780 ;
	row_1[25] <= 128'h07f838301e01fe000380003c0780f700 ;
	row_1[26] <= 128'h1ff038001e01fc000380003c0780e700 ;
	row_1[27] <= 128'h3fe03c003c0fff00038f003c07800f00 ;
	row_1[28] <= 128'h7df800003dfffff8038ffffc07f80e0e ;
	row_1[29] <= 128'h787fffff3fff07fe038ffffc07fffffe ;
	row_1[30] <= 128'h301ffffe7bf800fc0780003c07fc003e ;
	row_1[31] <= 128'h0000000039c000000780003c07800000 ;
	
    row_2[0]  <= 120'h00_00_00_00_01_c0_00_00_00_00_00_00_00_00_00;
    row_2[1]  <= 120'h00_3c_00_1e_01_e0_00_00_00_07_98_0e_0e_07_00;
    row_2[2]  <= 120'h00_38_00_1e_00_c0_00_00_00_07_1f_fe_0e_07_00;
    row_2[3]  <= 120'h00_38_00_1c_06_cc_00_00_00_37_73_9c_0e_07_00;
    row_2[4]  <= 120'h00_38_00_3c_ff_fc_00_00_00_3f_e3_9c_0e_e7_38;
    row_2[5]  <= 120'h00_38_00_3f_be_dc_00_00_00_37_63_9c_0f_ff_f8;
    row_2[6]  <= 120'h00_38_00_70_3c_df_00_00_00_07_07_9c_7f_c7_38;
    row_2[7]  <= 120'h00_38_00_f0_7f_ff_0f_00_00_07_07_1c_7f_87_38;
    row_2[8]  <= 120'h00_38_18_e3_fc_df_0f_00_00_e7_3f_fc_7f_c7_38;
    row_2[9]  <= 120'h00_3f_f8_7f_fe_dc_0f_00_00_ff_fe_7c_7f_c7_38;
    row_2[10] <= 120'h00_38_18_7f_ff_fc_00_00_00_e3_fc_00_7f_c7_38;
    row_2[11] <= 120'h00_38_00_1d_fe_cc_00_00_00_03_9c_0c_ff_e7_3f;
    row_2[12] <= 120'h00_38_00_5d_f8_c0_00_00_00_3f_9f_fc_ef_ff_ff;
    row_2[13] <= 120'h00_38_00_7f_bf_fc_00_00_00_3b_bc_1c_0f_ef_8f;
    row_2[14] <= 120'h00_38_00_7d_fe_cc_00_00_00_3b_fc_1c_0e_0f_c0;
    row_2[15] <= 120'h00_38_00_1c_fc_c6_00_00_00_3b_bc_1c_0e_0f_c0;
    row_2[16] <= 120'h00_38_00_1c_ff_fe_0f_00_00_3b_9f_fc_0e_1e_e0;
    row_2[17] <= 120'h00_38_00_1d_fc_c6_0f_00_00_3f_9c_1c_0e_1c_f0;
    row_2[18] <= 120'h00_38_00_1f_f9_c0_0f_00_00_7f_9c_1c_0e_3c_78;
    row_2[19] <= 120'h70_38_0e_1f_fd_c0_00_00_00_7f_c0_00_0e_78_3c;
    row_2[20] <= 120'h7f_ff_fe_1f_ff_00_00_00_00_f7_ff_ff_0f_f0_1f;
    row_2[21] <= 120'h78_00_0e_1d_e7_ff_00_00_00_f0_ff_ff_0f_e0_0f;
    row_2[22] <= 120'h00_00_00_1d_c0_00_00_00_00_60_00_00_0f_c0_06;
    row_2[23] <= 120'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;

    row_3[0]  <= 120'h00_00_00_00_01_c0_00_00_00_01_81_80_00_00_00;
    row_3[1]  <= 120'h00_00_00_1e_01_e0_00_00_00_03_81_c0_0e_07_00;
    row_3[2]  <= 120'h78_00_1e_1e_00_c0_00_00_00_03_c3_c0_0e_07_00;
    row_3[3]  <= 120'h7f_ff_fe_1c_06_cc_00_00_00_3d_e3_bc_0e_07_00;
    row_3[4]  <= 120'h70_38_0e_3c_ff_fc_00_00_00_3f_ff_fc_0e_e7_38;
    row_3[5]  <= 120'h00_38_00_3f_be_dc_00_00_00_3c_e7_3c_0f_ff_f8;
    row_3[6]  <= 120'h00_38_00_70_3c_df_00_00_00_1e_e7_78_7f_c7_38;
    row_3[7]  <= 120'h00_38_00_f0_7f_ff_0f_00_00_0f_e7_f0_7f_87_38;
    row_3[8]  <= 120'h00_3f_00_e3_fc_df_0f_00_00_07_e7_e0_7f_c7_38;
    row_3[9]  <= 120'h00_3f_80_7f_fe_dc_0f_00_00_03_e7_c0_7f_c7_38;
    row_3[10] <= 120'h00_3b_c0_7f_ff_fc_00_00_00_70_e7_0e_7f_c7_38;
    row_3[11] <= 120'h00_39_e0_1d_fe_cc_00_00_00_7f_ff_fe_ff_e7_3f;
    row_3[12] <= 120'h00_38_f0_5d_f8_c0_00_00_00_70_00_0e_ef_ff_ff;
    row_3[13] <= 120'h00_38_78_7f_bf_fc_00_00_00_00_00_00_0f_ef_8f;
    row_3[14] <= 120'h00_38_3c_7d_fe_cc_00_00_00_0f_ff_e0_0e_0f_c0;
    row_3[15] <= 120'h00_38_18_1c_fc_c6_00_00_00_0e_00_e0_0e_0f_c0;
    row_3[16] <= 120'h00_38_00_1c_ff_fe_0f_00_00_0e_00_e0_0e_1e_e0;
    row_3[17] <= 120'h00_38_00_1d_fc_c6_0f_00_00_0f_ff_e0_0e_1c_f0;
    row_3[18] <= 120'h00_38_00_1f_f9_c0_0f_00_00_0e_00_e0_0e_3c_78;
    row_3[19] <= 120'h00_38_00_1f_fd_c0_00_00_00_0e_00_e0_0e_78_3c;
    row_3[20] <= 120'h00_38_00_1f_ff_00_00_00_00_0f_ff_e0_0f_f0_1f;
    row_3[21] <= 120'h00_38_00_1d_e7_ff_00_00_00_0e_00_e0_0f_e0_0f;
    row_3[22] <= 120'h00_38_00_1d_c0_00_00_00_00_0e_00_f0_0f_c0_06;
    row_3[23] <= 120'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00; 

    row_4[0]  <= 120'h0x00_70_00_00_01_c0_00_00_00_00_00_00_08_00_00;
    row_4[1]  <= 120'h0x00_78_00_1e_01_e0_00_00_00_07_98_0e_0e_70_18;
    row_4[2]  <= 120'h0x00_78_00_1e_00_c0_00_00_00_07_1f_fe_0e_7f_f8;
    row_4[3]  <= 120'h0x00_70_00_1c_06_cc_00_00_00_37_73_9c_0e_70_38;
    row_4[4]  <= 120'h0x78_70_1c_3c_ff_fc_00_00_00_3f_e3_9c_0e_7f_f8;
    row_4[5]  <= 120'h0x7f_ff_fc_3f_be_dc_00_00_00_37_63_9c_0f_f0_38;
    row_4[6]  <= 120'h0x7c_e0_1c_70_3c_df_00_00_00_07_07_9c_7f_ff_f8;
    row_4[7]  <= 120'h0x00_e0_00_f0_7f_ff_0f_00_00_07_07_1c_7f_f0_1e;
    row_4[8]  <= 120'h0x01_e0_00_e3_fc_df_0f_00_00_e7_3f_fc_7f_ff_fe;
    row_4[9]  <= 120'h0x01_c0_00_7f_fe_dc_0f_00_00_ff_fe_7c_7e_ee_ee;
    row_4[10] <= 120'h0x03_c0_00_7f_ff_fc_00_00_00_e3_fc_00_fe_ee_ee;
    row_4[11] <= 120'h0x03_80_18_1d_fe_cc_00_00_00_03_9c_0c_ee_ee_ee;
    row_4[12] <= 120'h0x07_ff_f8_5d_f8_c0_00_00_00_3f_9f_fc_6e_ee_ee;
    row_4[13] <= 120'h0x07_0e_18_7f_bf_fc_00_00_00_3b_bc_1c_0e_ff_fe;
    row_4[14] <= 120'h0x0f_0e_00_7d_fe_cc_00_00_00_3b_fc_1c_0e_e0_0e;
    row_4[15] <= 120'h0x1e_0e_00_1c_fc_c6_00_00_00_3b_bc_1c_0e_7f_fc;
    row_4[16] <= 120'h0x7c_0e_00_1c_ff_fe_0f_00_00_3b_9f_fc_0e_7c_38;
    row_4[17] <= 120'h0xf8_0e_00_1d_fc_c6_0f_00_00_3f_9c_1c_0e_1e_78;
    row_4[18] <= 120'h0x70_0e_00_1f_f9_c0_0f_00_00_7f_9c_1c_0e_0f_f0;
    row_4[19] <= 120'h0x0e_0e_0e_1f_fd_c0_00_00_00_7f_c0_00_0e_07_c0;
    row_4[20] <= 120'h0x0f_ff_fe_1f_ff_00_00_00_00_f7_ff_ff_0e_1f_f8;
    row_4[21] <= 120'h0x0e_00_0e_1d_e7_ff_00_00_00_f0_ff_ff_0f_fe_ff;
    row_4[22] <= 120'h0x00_00_00_1d_c0_00_00_00_00_60_00_00_0f_f0_1e;
    row_4[23] <= 120'h0x00_00_00_00_00_00_00_00_00_00_00_00_00_00_00; 

	row_5[0]  <= 120'h00_30_00_00_01_c0_00_00_00_00_00_00_08_00_00;
    row_5[1]  <= 120'h00_78_00_1e_01_e0_00_00_00_07_98_0e_0e_70_18;
    row_5[2]  <= 120'h00_78_00_1e_00_c0_00_00_00_07_1f_fe_0e_7f_f8;
    row_5[3]  <= 120'h00_70_00_1c_06_cc_00_00_00_37_73_9c_0e_70_38;
    row_5[4]  <= 120'h70_70_0e_3c_ff_fc_00_00_00_3f_e3_9c_0e_7f_f8;
    row_5[5]  <= 120'h7f_ff_fe_3f_be_dc_00_00_00_37_63_9c_0f_f0_38;
    row_5[6]  <= 120'h70_e0_0e_70_3c_df_00_00_00_07_07_9c_7f_ff_f8;
    row_5[7]  <= 120'h00_e0_00_f0_7f_ff_0f_00_00_07_07_1c_7f_f0_1e;
    row_5[8]  <= 120'h01_e0_00_e3_fc_df_0f_00_00_e7_3f_fc_7f_ff_fe;
    row_5[9]  <= 120'h01_c0_00_7f_fe_dc_0f_00_00_ff_fe_7c_7e_ee_ee;
    row_5[10] <= 120'h03_c0_00_7f_ff_fc_00_00_00_e3_fc_00_fe_ee_ee;
    row_5[11] <= 120'h03_ff_f0_1d_fe_cc_00_00_00_03_9c_0c_ee_ee_ee;
    row_5[12] <= 120'h07_80_70_5d_f8_c0_00_00_00_3f_9f_fc_6e_ee_ee;
    row_5[13] <= 120'h0f_80_70_7f_bf_fc_00_00_00_3b_bc_1c_0e_ff_fe;
    row_5[14] <= 120'h1f_80_70_7d_fe_cc_00_00_00_3b_fc_1c_0e_e0_0e;
    row_5[15] <= 120'h3f_80_70_1c_fc_c6_00_00_00_3b_bc_1c_0e_7f_fc;
    row_5[16] <= 120'h7f_80_70_1c_ff_fe_0f_00_00_3b_9f_fc_0e_7c_38;
    row_5[17] <= 120'h7b_80_70_1d_fc_c6_0f_00_00_3f_9c_1c_0e_1e_78;
    row_5[18] <= 120'h33_80_70_1f_f9_c0_0f_00_00_7f_9c_1c_0e_0f_f0;
    row_5[19] <= 120'h03_ff_f0_1f_fd_c0_00_00_00_7f_c0_00_0e_07_c0;
    row_5[20] <= 120'h03_80_70_1f_ff_00_00_00_00_f7_ff_ff_0e_1f_f8;
    row_5[21] <= 120'h03_80_70_1d_e7_ff_00_00_00_f0_ff_ff_0f_fe_ff;
    row_5[22] <= 120'h00_00_00_1d_c0_00_00_00_00_60_00_00_0f_f0_1e;
    row_5[23] <= 120'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00; 
	
end

// 根据不同的区域进行不同颜色绘制
always @(posedge vga_clk_25 or negedge rst_n)
begin
    if(!rst_n)
        pixel_data <= WHITE;
    else begin
        if( ((pixel_xpos >= ROW1_X) && (pixel_xpos < ROW1_X+ROW1_H))
          && ((pixel_ypos >= ROW1_Y) && (pixel_ypos < ROW1_Y+ROW1_V)) ) begin
            if(row_1[y1_cnt][10'd127 - x1_cnt])  
                pixel_data <= BLUE;              
            else
                pixel_data <= WHITE;           
        end 
        else if( ((pixel_xpos >= ROW2_X) && (pixel_xpos < ROW2_X+ROW2_H))
               && ((pixel_ypos >= ROW2_Y) && (pixel_ypos < ROW2_Y+ROW2_V)) ) begin
                   if(row_2[y2_cnt][10'd120 - x2_cnt])  
                       pixel_data <= BLANK;              
                    else
                       pixel_data <= WHITE;           
        end 
        else if( ((pixel_xpos >= ROW3_X) && (pixel_xpos < ROW3_X+ROW3_H))
               && ((pixel_ypos >= ROW3_Y) && (pixel_ypos < ROW3_Y+ROW3_V)) ) begin
                   if(row_3[y3_cnt][10'd120 - x3_cnt])  
                       pixel_data <= BLANK;              
                   else
                       pixel_data <= WHITE;           
        end   
		else if( ((pixel_xpos >= ROW4_X) && (pixel_xpos < ROW4_X+ROW4_H))
               && ((pixel_ypos >= ROW4_Y) && (pixel_ypos < ROW4_Y+ROW4_V)) ) begin
                   if(row_4[y4_cnt][10'd120 - x4_cnt])  
                       pixel_data <= BLANK;              
                   else
                       pixel_data <= WHITE;           
        end
		else if( ((pixel_xpos >= ROW5_X) && (pixel_xpos < ROW5_X+ROW5_H))
               && ((pixel_ypos >= ROW5_Y) && (pixel_ypos < ROW5_Y+ROW5_V)) ) begin
                   if(row_5[y5_cnt][10'd120 - x5_cnt])  
                       pixel_data <= BLANK;              
                   else
                       pixel_data <= WHITE;           
        end		
        else
            pixel_data <= WHITE;               
    end
end

endmodule 