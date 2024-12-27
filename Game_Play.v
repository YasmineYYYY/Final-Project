/* -----PLAY游戏界面,蛇头加蛇身最长共计25节----- */

module Game_Play(
    input            vga_clk_25,     
    input            rst_n,            
    input     [ 9:0] pixel_xpos,      
    input     [ 9:0] pixel_ypos,       
    input     [ 3:0] state_m,          // 当前游戏状态      
    input     [ 1:0] speed_m,          // 游戏速度---0->快速，1->慢速 
    input     [ 3:0] move_dirt,        // 控制贪吃蛇移动方向
    
    output           game_over,        // 游戏结束信号
    output    [ 5:0] game_score,       // 游戏得分，吃到的苹果总数
    output reg[15:0] pixel_data        
);

// 参数定义
parameter   H_DISP = 10'd640;          // 分辨率--行 
parameter   V_DISP = 10'd480;          // 分辨率--列

localparam  Border = 10'd16;           // 游戏界面的红色边墙--16像素值
localparam  BODY   = 10'd16;           // 一节蛇身--16像素值
localparam  FASTER = 26'd2000_000;
localparam  FAST   = 26'd4000_000;     // 快速模式--150ms单位速度移动
localparam  SLOW   = 26'd6000_000;     // 慢速模式--250ms单位速度移动
localparam  SLOWER = 26'd8000_000;

localparam  WHITE  = 16'hFFFF;  // RGB565 白色
localparam  BLANK  = 16'h0000;  // RGB565 黑色
localparam  RED    = 16'hF100;  // RGB565 红色
localparam  GREEN  = 16'h0400;  // RGB565 绿色
localparam  BLUE   = 16'h001F;  // RGB565 蓝色
localparam  YELLOW = 16'hFFE0;  // RGB565 黄色
localparam  PURPLE = 16'h8010;  // RGB565 紫色
localparam  BROWN  = 16'hE618;  // RGB565 棕色
// 参数定义四种游戏状态
localparam START = 4'b0001;
localparam SPEED = 4'b0010;
localparam PLAY  = 4'b0100;
localparam END   = 4'b1000;
// 参数定义贪吃蛇四种移动方向
localparam RIGHT = 4'b0001;  
localparam LEFT  = 4'b0010;  
localparam DOWN  = 4'b0100;
localparam UP    = 4'b1000;  

// 内部变量定义
reg [25:0] speed_cnt;     // 时钟分频计数器
reg        move_en;       // 移动标志信号
reg [ 9:0] head_x;        // 蛇头X坐标
reg [ 9:0] head_y;        // 蛇头Y坐标
reg [ 9:0] body_x [26:0]; // 每一节蛇身X坐标
reg [ 9:0] body_y [26:0]; // 每一节蛇身Y坐标
reg        meet_wall;     // 蛇头撞墙信号   
reg        meet_body;     // 蛇头撞到自身信号
reg [ 9:0] apple_x;       // 随机生成苹果X坐标
reg [ 9:0] apple_y;       // 随机生成苹果Y坐标
reg [ 9:0] aple_x_cnt;    // 准备下一个苹果X坐标
reg [ 9:0] aple_y_cnt;    // 准备下一个苹果Y坐标
reg        apple_eat;     // 吃到苹果标志位
reg [ 5:0] apple_cnt;     // 计数吃到的苹果总数

/* -----main code----- */

// 游戏结束信号
assign game_over  = meet_wall || meet_body;
// 游戏得分输出
assign game_score = apple_cnt;

/* ``````设置游戏速度部分，即蛇移动速度`````` */
 
// move_en信号：快速模式->250ms来一次高电平  慢速模式->150ms来一次高电平
always @(posedge vga_clk_25 or negedge rst_n)
begin
    if(!rst_n) begin
        speed_cnt  <= 24'd0;
        move_en    <= 1'b0; 
    end
    else begin
        case(speed_m)
            2'b00:  begin
                if(speed_cnt == SLOWER - 1'b1) begin
                    speed_cnt <= 24'd0;
                    move_en   <= 1'b1;
                end
                else begin    
                    speed_cnt <= speed_cnt + 1'b1;
                    move_en   <= 1'b0;
                end
            end

            2'b01:  begin
                if(speed_cnt == SLOW - 1'b1) begin
                    speed_cnt <= 24'd0;
                    move_en   <= 1'b1;
                end
                else begin    
                    speed_cnt <= speed_cnt + 1'b1;
                    move_en   <= 1'b0;
                end
            end
			2'b10:  begin
                if(speed_cnt == FAST - 1'b1) begin
                    speed_cnt <= 24'd0;
                    move_en   <= 1'b1;
                end
                else begin    
                    speed_cnt <= speed_cnt + 1'b1;
                    move_en   <= 1'b0;
                end
            end
            2'b11:  begin
                if(speed_cnt == FASTER - 1'b1) begin
                    speed_cnt <= 24'd0;
                    move_en   <= 1'b1;
                end
                else begin    
                    speed_cnt <= speed_cnt + 1'b1;
                    move_en   <= 1'b0;
                end
            end            
            default: begin
                speed_cnt <= 24'd0;
                move_en   <= 1'b0; 
            end
        endcase
    end
end


/* ``````蛇头、蛇身控制部分，方向控制及增长控制`````` */

// 根据按键输入控制蛇移动方向，初始方向为向右移动，初始显示前两节（蛇头加一节蛇身），最长共计25节
always @(posedge move_en or negedge rst_n)
begin
    if(!rst_n) begin
        head_x    <= 10'd96;         // 蛇头初始X坐标
        head_y    <= 10'd48;         // 蛇头初始Y坐标
        body_x[0] <= 10'd96 - BODY;  // 第一节蛇身初始X坐标
        body_y[0] <= 10'd48;         // 第一节蛇身初始Y坐标
		body_x[1] <= 10'd80 - BODY; 
        body_y[1] <= 10'd48; 
		body_x[2] <= 10'd64 - BODY; 
        body_y[2] <= 10'd48; 
		body_x[3] <= 10'd48 - BODY; 
        body_y[3] <= 10'd48; 
    end
    else if(state_m == START) begin  // 每次重新开始游戏时，从初始位置重新开始
        head_x    <= 10'd96;        
        head_y    <= 10'd48;        
        body_x[0] <= 10'd96 - BODY; 
        body_y[0] <= 10'd48; 
		body_x[1] <= 10'd80 - BODY; 
        body_y[1] <= 10'd48; 
		body_x[2] <= 10'd64 - BODY; 
        body_y[2] <= 10'd48; 
		body_x[3] <= 10'd48 - BODY; 
        body_y[3] <= 10'd48; 
    end
    else if(state_m == PLAY) begin 
        case(move_dirt) 
            RIGHT:   begin
                head_x    <= head_x + 10'd16;
                head_y    <= head_y;
                body_x[0] <= head_x;
                body_y[0] <= head_y;
			 	body_x[1] <= body_x[0];
				body_y[1] <= body_y[0];
			 	body_x[2] <= body_x[1];
				body_y[2] <= body_y[1];
			 	body_x[3] <= body_x[2];
				body_y[3] <= body_y[2];
            end
            
            LEFT:    begin
                head_x    <= head_x - 10'd16;
                head_y    <= head_y;
                body_x[0] <= head_x; 
                body_y[0] <= head_y;
			 	body_x[1] <= body_x[0];
				body_y[1] <= body_y[0];
			 	body_x[2] <= body_x[1];
				body_y[2] <= body_y[1];
			 	body_x[3] <= body_x[2];
				body_y[3] <= body_y[2];
            end
            
            DOWN:    begin
                head_y    <= head_y + 10'd16;
                head_x    <= head_x;
                body_y[0] <= head_y;  
                body_x[0] <= head_x;
			 	body_x[1] <= body_x[0];
				body_y[1] <= body_y[0];
			 	body_x[2] <= body_x[1];
				body_y[2] <= body_y[1];
			 	body_x[3] <= body_x[2];
				body_y[3] <= body_y[2];
            end
            
            UP:      begin
                head_y    <= head_y - 10'd16;
                head_x    <= head_x;
                body_y[0] <= head_y;
                body_x[0] <= head_x;
			 	body_x[1] <= body_x[0];
				body_y[1] <= body_y[0];
			 	body_x[2] <= body_x[1];
				body_y[2] <= body_y[1];
			 	body_x[3] <= body_x[2];
				body_y[3] <= body_y[2];
            end
        
            default: begin
                head_x    <= 10'd0;
                head_y    <= 10'd0;
                body_x[0] <= 10'd0;
                body_y[0] <= 10'd0;
				body_x[1] <= 10'd0;
                body_y[1] <= 10'd0;
				body_x[2] <= 10'd0;
                body_y[2] <= 10'd0;
				body_x[3] <= 10'd0;
                body_y[3] <= 10'd0;
				
            end
        endcase 
    end   
end

// 第二节以后的蛇身，根据吃苹果数不断增长
always @(posedge move_en or negedge rst_n)
begin
    if(!rst_n) begin
        body_x[ 24] <= 10'd0;   body_y[ 24] <= 10'd0;  
        body_x[ 25] <= 10'd0;   body_y[ 25] <= 10'd0;
        body_x[ 26] <= 10'd0;   body_y[ 26] <= 10'd0;
//		body_x[ 1] <= 10'd0;   body_y[ 1] <= 10'd0;
//        body_x[ 2] <= 10'd0;   body_y[ 2] <= 10'd0;
//        body_x[ 3] <= 10'd0;   body_y[ 3] <= 10'd0;
        body_x[ 4] <= 10'd0;   body_y[ 4] <= 10'd0;
        body_x[ 5] <= 10'd0;   body_y[ 5] <= 10'd0;
        body_x[ 6] <= 10'd0;   body_y[ 6] <= 10'd0;
        body_x[ 7] <= 10'd0;   body_y[ 7] <= 10'd0;
        body_x[ 8] <= 10'd0;   body_y[ 8] <= 10'd0;
        body_x[ 9] <= 10'd0;   body_y[ 9] <= 10'd0;  
        body_x[10] <= 10'd0;   body_y[10] <= 10'd0;
        body_x[11] <= 10'd0;   body_y[11] <= 10'd0;
        body_x[12] <= 10'd0;   body_y[12] <= 10'd0;
        body_x[13] <= 10'd0;   body_y[13] <= 10'd0;
        body_x[14] <= 10'd0;   body_y[14] <= 10'd0;
        body_x[15] <= 10'd0;   body_y[15] <= 10'd0;
        body_x[16] <= 10'd0;   body_y[16] <= 10'd0;
        body_x[17] <= 10'd0;   body_y[17] <= 10'd0;
        body_x[18] <= 10'd0;   body_y[18] <= 10'd0;
        body_x[19] <= 10'd0;   body_y[19] <= 10'd0;
        body_x[20] <= 10'd0;   body_y[20] <= 10'd0;
        body_x[21] <= 10'd0;   body_y[21] <= 10'd0;
        body_x[22] <= 10'd0;   body_y[22] <= 10'd0;
        body_x[23] <= 10'd0;   body_y[23] <= 10'd0;
    end
    else if(state_m == START) begin                  // 重新开始游戏后，第二节以后蛇身清零 
        body_x[ 24] <= 10'd0;   body_y[ 24] <= 10'd0;  
        body_x[ 25] <= 10'd0;   body_y[ 25] <= 10'd0;
        body_x[ 26] <= 10'd0;   body_y[ 26] <= 10'd0;
        body_x[ 4] <= 10'd0;   body_y[ 4] <= 10'd0;
        body_x[ 5] <= 10'd0;   body_y[ 5] <= 10'd0;
        body_x[ 6] <= 10'd0;   body_y[ 6] <= 10'd0;
        body_x[ 7] <= 10'd0;   body_y[ 7] <= 10'd0;
        body_x[ 8] <= 10'd0;   body_y[ 8] <= 10'd0;
        body_x[ 9] <= 10'd0;   body_y[ 9] <= 10'd0;  
        body_x[10] <= 10'd0;   body_y[10] <= 10'd0;
        body_x[11] <= 10'd0;   body_y[11] <= 10'd0;
        body_x[12] <= 10'd0;   body_y[12] <= 10'd0;
        body_x[13] <= 10'd0;   body_y[13] <= 10'd0;
        body_x[14] <= 10'd0;   body_y[14] <= 10'd0;
        body_x[15] <= 10'd0;   body_y[15] <= 10'd0;
        body_x[16] <= 10'd0;   body_y[16] <= 10'd0;
        body_x[17] <= 10'd0;   body_y[17] <= 10'd0;
        body_x[18] <= 10'd0;   body_y[18] <= 10'd0;
        body_x[19] <= 10'd0;   body_y[19] <= 10'd0;
        body_x[20] <= 10'd0;   body_y[20] <= 10'd0;
        body_x[21] <= 10'd0;   body_y[21] <= 10'd0;
        body_x[22] <= 10'd0;   body_y[22] <= 10'd0;
        body_x[23] <= 10'd0;   body_y[23] <= 10'd0;
    end
    else if(state_m == PLAY) begin                     // 吃到苹果后，依次增加蛇身长度
        case(move_dirt)                              
            RIGHT,LEFT,DOWN,UP:   begin              
                if(apple_cnt >= 6'd1)  begin body_x[ 4] <= body_x[ 3];  body_y[ 4] <= body_y[ 3];  
                if(apple_cnt >= 6'd2)  begin body_x[ 5] <= body_x[ 4];  body_y[ 5] <= body_y[ 4];
                if(apple_cnt >= 6'd3)  begin body_x[ 6] <= body_x[ 5];  body_y[ 6] <= body_y[ 5];
                if(apple_cnt >= 6'd4)  begin body_x[ 7] <= body_x[ 6];  body_y[ 7] <= body_y[ 6];
                if(apple_cnt >= 6'd5)  begin body_x[ 8] <= body_x[ 7];  body_y[ 8] <= body_y[ 7];
                if(apple_cnt >= 6'd6)  begin body_x[ 9] <= body_x[ 8];  body_y[ 9] <= body_y[ 8];
                if(apple_cnt >= 6'd7)  begin body_x[10] <= body_x[ 9];  body_y[10] <= body_y[ 9];
                if(apple_cnt >= 6'd8)  begin body_x[11] <= body_x[10];  body_y[11] <= body_y[10];
                if(apple_cnt >= 6'd9)  begin body_x[12] <= body_x[11];  body_y[12] <= body_y[11];
                if(apple_cnt >= 6'd10) begin body_x[13] <= body_x[12];  body_y[13] <= body_y[12];
                if(apple_cnt >= 6'd11) begin body_x[14] <= body_x[13];  body_y[14] <= body_y[13];
                if(apple_cnt >= 6'd12) begin body_x[15] <= body_x[14];  body_y[15] <= body_y[14];
                if(apple_cnt >= 6'd13) begin body_x[16] <= body_x[15];  body_y[16] <= body_y[15];
                if(apple_cnt >= 6'd14) begin body_x[17] <= body_x[16];  body_y[17] <= body_y[16];
                if(apple_cnt >= 6'd15) begin body_x[18] <= body_x[17];  body_y[18] <= body_y[17];
                if(apple_cnt >= 6'd16) begin body_x[19] <= body_x[18];  body_y[19] <= body_y[18];
                if(apple_cnt >= 6'd17) begin body_x[20] <= body_x[19];  body_y[20] <= body_y[19];
                if(apple_cnt >= 6'd18) begin body_x[21] <= body_x[20];  body_y[21] <= body_y[20];
                if(apple_cnt >= 6'd19) begin body_x[22] <= body_x[21];  body_y[22] <= body_y[21];
                if(apple_cnt >= 6'd20) begin body_x[23] <= body_x[22];  body_y[23] <= body_y[22];
                if(apple_cnt >= 6'd21) begin body_x[24] <= body_x[23];  body_y[24] <= body_y[23];
                if(apple_cnt >= 6'd22) begin body_x[25] <= body_x[24];  body_y[25] <= body_y[24];
                if(apple_cnt >= 6'd23) begin body_x[26] <= body_x[25];  body_y[26] <= body_y[25];

                end end end end end end end end end end
                end end end end end end end end end end
                end end end      
            end 
            default: ;
        endcase 
    end
end

// 判断是否吃到苹果，一旦吃到苹果，输出“已吃”信号
always @(posedge vga_clk_25 or negedge rst_n)
begin
    if(!rst_n) begin
        apple_eat <= 1'b0;
        apple_cnt <= 6'd0;
    end
    else if(state_m == START)              // 重新开始游戏时，吃到的苹果总数清零
        apple_cnt <= 6'd0;
    else if(state_m == PLAY) begin
        if( (((head_x >= apple_x) && (head_x < apple_x+BODY)) && ((head_y >= apple_y) && (head_y < apple_y+BODY))) ) begin
            apple_eat <= 1'b1;             // 吃到苹果时，给出高电平脉冲 
            if(apple_eat == 1'b0)
                apple_cnt <= apple_cnt + 1'b1;
            else
                apple_cnt <= apple_cnt;
        end
        else 
            apple_eat <= 1'b0;
    end
end


/* ``````苹果生成模块，随机生成`````` */

// 进入PLAY游戏状态，苹果一旦被吃，则新苹果随机生成
always @(posedge vga_clk_25 or negedge rst_n)
begin
    if(!rst_n) begin
        apple_x    <= 10'd352;        // 苹果默认出现的坐标
        apple_y    <= 10'd256;
        aple_x_cnt <= 10'd16;         // 随机生成苹果新的坐标
        aple_y_cnt <= 10'd16;
    end
    else if(state_m == START) begin   // 重新开始游戏时，初始苹果出现的坐标
        apple_x    <= 10'd352;        
        apple_y    <= 10'd256;
    end  
    else if(state_m == PLAY) begin    // 根据游戏开始运动时间，利用加法随机产生苹果坐标
        if(apple_eat == 1'b1) begin  
            apple_x <= aple_x_cnt;
            apple_y <= aple_y_cnt;
        end  
        else if(aple_x_cnt > H_DISP-Border-BODY-10'd16)
            aple_x_cnt <= 10'd32;
        else if(aple_y_cnt > V_DISP-Border-BODY-10'd16)
            aple_y_cnt <= 10'd32;
        else begin
            aple_x_cnt <= aple_x_cnt + 10'd16;
            aple_y_cnt <= aple_y_cnt + 10'd16;
        end
    end
end

/* ``````蛇头撞墙或蛇身部分，发出结束游戏信号`````` */

// 蛇头撞墙信号
always @(posedge vga_clk_25 or negedge rst_n)
begin
    if(!rst_n)
        meet_wall <= 1'b0;  
    else if(state_m == START) 
        meet_wall <= 1'b0;
    else if(state_m == PLAY) begin
        if( ((head_x < Border) || (head_x > H_DISP-Border-BODY))
          || ((head_y < Border) || (head_y > V_DISP-Border-BODY)) )
            meet_wall <= 1'b1; 
        else
            meet_wall <= 1'b0;
    end
end

// 蛇头撞到蛇身信号
always @(posedge vga_clk_25 or negedge rst_n)
begin
    if(!rst_n)
        meet_body <= 1'b0;  
    else if(state_m == START) 
        meet_body <= 1'b0;
    else if(state_m == PLAY) begin
        if( (((head_x >= body_x[0]) && (head_x < body_x[0]+BODY)) && ((head_y >= body_y[0]) && (head_y < body_y[0]+BODY)))
          || (((head_x >= body_x[1]) && (head_x < body_x[1]+BODY)) && ((head_y >= body_y[1]) && (head_y < body_y[1]+BODY)))
          || (((head_x >= body_x[2]) && (head_x < body_x[2]+BODY)) && ((head_y >= body_y[2]) && (head_y < body_y[2]+BODY)))
          || (((head_x >= body_x[3]) && (head_x < body_x[3]+BODY)) && ((head_y >= body_y[3]) && (head_y < body_y[3]+BODY)))
          || (((head_x >= body_x[4]) && (head_x < body_x[4]+BODY)) && ((head_y >= body_y[4]) && (head_y < body_y[4]+BODY)))
          || (((head_x >= body_x[5]) && (head_x < body_x[5]+BODY)) && ((head_y >= body_y[5]) && (head_y < body_y[5]+BODY)))
          || (((head_x >= body_x[6]) && (head_x < body_x[6]+BODY)) && ((head_y >= body_y[6]) && (head_y < body_y[6]+BODY)))
          || (((head_x >= body_x[7]) && (head_x < body_x[7]+BODY)) && ((head_y >= body_y[7]) && (head_y < body_y[7]+BODY)))
          || (((head_x >= body_x[8]) && (head_x < body_x[8]+BODY)) && ((head_y >= body_y[8]) && (head_y < body_y[8]+BODY)))
          || (((head_x >= body_x[9]) && (head_x < body_x[9]+BODY)) && ((head_y >= body_y[9]) && (head_y < body_y[9]+BODY)))
          || (((head_x >= body_x[10]) && (head_x < body_x[10]+BODY)) && ((head_y >= body_y[10]) && (head_y < body_y[10]+BODY)))
          || (((head_x >= body_x[11]) && (head_x < body_x[11]+BODY)) && ((head_y >= body_y[11]) && (head_y < body_y[11]+BODY)))
          || (((head_x >= body_x[12]) && (head_x < body_x[12]+BODY)) && ((head_y >= body_y[12]) && (head_y < body_y[12]+BODY)))
          || (((head_x >= body_x[13]) && (head_x < body_x[13]+BODY)) && ((head_y >= body_y[13]) && (head_y < body_y[13]+BODY)))
          || (((head_x >= body_x[14]) && (head_x < body_x[14]+BODY)) && ((head_y >= body_y[14]) && (head_y < body_y[14]+BODY)))
          || (((head_x >= body_x[15]) && (head_x < body_x[15]+BODY)) && ((head_y >= body_y[15]) && (head_y < body_y[15]+BODY)))
          || (((head_x >= body_x[16]) && (head_x < body_x[16]+BODY)) && ((head_y >= body_y[16]) && (head_y < body_y[16]+BODY)))
          || (((head_x >= body_x[17]) && (head_x < body_x[17]+BODY)) && ((head_y >= body_y[17]) && (head_y < body_y[17]+BODY)))
          || (((head_x >= body_x[18]) && (head_x < body_x[18]+BODY)) && ((head_y >= body_y[18]) && (head_y < body_y[18]+BODY)))
          || (((head_x >= body_x[19]) && (head_x < body_x[19]+BODY)) && ((head_y >= body_y[19]) && (head_y < body_y[19]+BODY)))
          || (((head_x >= body_x[20]) && (head_x < body_x[20]+BODY)) && ((head_y >= body_y[20]) && (head_y < body_y[20]+BODY)))
          || (((head_x >= body_x[21]) && (head_x < body_x[21]+BODY)) && ((head_y >= body_y[21]) && (head_y < body_y[21]+BODY)))
          || (((head_x >= body_x[22]) && (head_x < body_x[22]+BODY)) && ((head_y >= body_y[22]) && (head_y < body_y[22]+BODY)))
          || (((head_x >= body_x[23]) && (head_x < body_x[23]+BODY)) && ((head_y >= body_y[23]) && (head_y < body_y[23]+BODY)))
		  || (((head_x >= body_x[24]) && (head_x < body_x[24]+BODY)) && ((head_y >= body_y[24]) && (head_y < body_y[24]+BODY)))
		  || (((head_x >= body_x[25]) && (head_x < body_x[25]+BODY)) && ((head_y >= body_y[25]) && (head_y < body_y[25]+BODY)))
		  || (((head_x >= body_x[26]) && (head_x < body_x[26]+BODY)) && ((head_y >= body_y[26]) && (head_y < body_y[26]+BODY)))
          )
            meet_body <= 1'b1; 
        else
            meet_body <= 1'b0;
    end
end


/* ``````PLAY游戏中液晶屏显示部分`````` */

// 动态的在显示屏上刷新界面
always @(posedge vga_clk_25 or negedge rst_n)
begin
    if(!rst_n)
        pixel_data <= 16'd0; 
    else begin
        // 红色边墙
        if( ((pixel_xpos < Border) || (pixel_xpos >= H_DISP-Border)) || ((pixel_ypos < Border) || (pixel_ypos >= V_DISP-Border)) )
            pixel_data <= BROWN;
        // 黄色苹果
        else if( ((pixel_xpos >= apple_x) && (pixel_xpos < apple_x+BODY)) && ((pixel_ypos >= apple_y) && (pixel_ypos < apple_y+BODY)) )
            pixel_data <= YELLOW;
        // 绿色蛇头    
        else if( ((pixel_xpos >= head_x) && (pixel_xpos < head_x+BODY)) && ((pixel_ypos >= head_y) && (pixel_ypos < head_y+BODY)) ) 
            pixel_data <= 16'h0F2F;
        // 蓝色蛇身   
        else if(  (((pixel_xpos >= body_x[0]) && (pixel_xpos < body_x[0]+BODY)) && ((pixel_ypos >= body_y[0]) && (pixel_ypos < body_y[0]+BODY)))
               || (((pixel_xpos >= body_x[1]) && (pixel_xpos < body_x[1]+BODY)) && ((pixel_ypos >= body_y[1]) && (pixel_ypos < body_y[1]+BODY)))
               || (((pixel_xpos >= body_x[2]) && (pixel_xpos < body_x[2]+BODY)) && ((pixel_ypos >= body_y[2]) && (pixel_ypos < body_y[2]+BODY)))
               || (((pixel_xpos >= body_x[3]) && (pixel_xpos < body_x[3]+BODY)) && ((pixel_ypos >= body_y[3]) && (pixel_ypos < body_y[3]+BODY)))
               || (((pixel_xpos >= body_x[4]) && (pixel_xpos < body_x[4]+BODY)) && ((pixel_ypos >= body_y[4]) && (pixel_ypos < body_y[4]+BODY)))
               || (((pixel_xpos >= body_x[5]) && (pixel_xpos < body_x[5]+BODY)) && ((pixel_ypos >= body_y[5]) && (pixel_ypos < body_y[5]+BODY)))
               || (((pixel_xpos >= body_x[6]) && (pixel_xpos < body_x[6]+BODY)) && ((pixel_ypos >= body_y[6]) && (pixel_ypos < body_y[6]+BODY)))
               || (((pixel_xpos >= body_x[7]) && (pixel_xpos < body_x[7]+BODY)) && ((pixel_ypos >= body_y[7]) && (pixel_ypos < body_y[7]+BODY)))
               || (((pixel_xpos >= body_x[8]) && (pixel_xpos < body_x[8]+BODY)) && ((pixel_ypos >= body_y[8]) && (pixel_ypos < body_y[8]+BODY)))
               || (((pixel_xpos >= body_x[9]) && (pixel_xpos < body_x[9]+BODY)) && ((pixel_ypos >= body_y[9]) && (pixel_ypos < body_y[9]+BODY)))
               || (((pixel_xpos >= body_x[10]) && (pixel_xpos < body_x[10]+BODY)) && ((pixel_ypos >= body_y[10]) && (pixel_ypos < body_y[10]+BODY)))
               || (((pixel_xpos >= body_x[11]) && (pixel_xpos < body_x[11]+BODY)) && ((pixel_ypos >= body_y[11]) && (pixel_ypos < body_y[11]+BODY)))
               || (((pixel_xpos >= body_x[12]) && (pixel_xpos < body_x[12]+BODY)) && ((pixel_ypos >= body_y[12]) && (pixel_ypos < body_y[12]+BODY)))
               || (((pixel_xpos >= body_x[13]) && (pixel_xpos < body_x[13]+BODY)) && ((pixel_ypos >= body_y[13]) && (pixel_ypos < body_y[13]+BODY)))
               || (((pixel_xpos >= body_x[14]) && (pixel_xpos < body_x[14]+BODY)) && ((pixel_ypos >= body_y[14]) && (pixel_ypos < body_y[14]+BODY)))
               || (((pixel_xpos >= body_x[15]) && (pixel_xpos < body_x[15]+BODY)) && ((pixel_ypos >= body_y[15]) && (pixel_ypos < body_y[15]+BODY)))
               || (((pixel_xpos >= body_x[16]) && (pixel_xpos < body_x[16]+BODY)) && ((pixel_ypos >= body_y[16]) && (pixel_ypos < body_y[16]+BODY)))
               || (((pixel_xpos >= body_x[17]) && (pixel_xpos < body_x[17]+BODY)) && ((pixel_ypos >= body_y[17]) && (pixel_ypos < body_y[17]+BODY)))
               || (((pixel_xpos >= body_x[18]) && (pixel_xpos < body_x[18]+BODY)) && ((pixel_ypos >= body_y[18]) && (pixel_ypos < body_y[18]+BODY)))
               || (((pixel_xpos >= body_x[19]) && (pixel_xpos < body_x[19]+BODY)) && ((pixel_ypos >= body_y[19]) && (pixel_ypos < body_y[19]+BODY)))
               || (((pixel_xpos >= body_x[20]) && (pixel_xpos < body_x[20]+BODY)) && ((pixel_ypos >= body_y[20]) && (pixel_ypos < body_y[20]+BODY)))
               || (((pixel_xpos >= body_x[21]) && (pixel_xpos < body_x[21]+BODY)) && ((pixel_ypos >= body_y[21]) && (pixel_ypos < body_y[21]+BODY)))
               || (((pixel_xpos >= body_x[22]) && (pixel_xpos < body_x[22]+BODY)) && ((pixel_ypos >= body_y[22]) && (pixel_ypos < body_y[22]+BODY)))
               || (((pixel_xpos >= body_x[23]) && (pixel_xpos < body_x[23]+BODY)) && ((pixel_ypos >= body_y[23]) && (pixel_ypos < body_y[23]+BODY)))
               )
            pixel_data <= BLUE; 
        // 黑色游戏背景
        else    
            pixel_data <= BLANK;  
    end         
end

endmodule 