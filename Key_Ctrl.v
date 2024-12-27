/* -----按键控制模块，负责在START->SPEED->PLAY->END模式下判断按下按键之后的动作状态----- */

module Key_Ctrl(   
    input        clk,         
    input        rst_n,         
    input  [3:0] key,           // 上-下-左-右<--->key[0]-key[1]-key[2]-key[3]
    input        game_over,     // 游戏结束信号，撞到墙壁或者撞到蛇身，置1

    output [3:0] state_m,       // 输出当前状态模式
    output [3:0] move_d,        // 输出控制移动方向
    output  reg  [1:0] speed_m        // 游戏速度，0->快速，1->慢速 
);

// 参数定义四种游戏状态
//localparam WAIT	 = 4'b0000;
localparam START = 4'b0001;
localparam SPEED = 4'b0010;
localparam PLAY  = 4'b0100;
localparam END   = 4'b1000;
// 参数定义贪吃蛇四种移动方向
localparam RIGHT = 4'b0001;  // 右移
localparam LEFT  = 4'b0010;  // 左移
localparam DOWN  = 4'b0100;  // 下移
localparam UP    = 4'b1000;  // 上移

// 内部变量定义
reg [ 3:0] state_c;     
reg [ 3:0] state_n;      
reg [ 1:0] change_cond;  // 状态转换条件
reg [ 3:0] move_dirt;    // 贪吃蛇移动方向
// 刚进入游戏模式，延时500ms后按键才起控制方向作用
reg [31:0] play_cnt; 
reg        play_key;    
// 寄存按键的状态 
//reg [ 3:0] key_reg;
reg [31:0] delay_cnt;
reg [ 3:0] key_delay;
/* -----main code----- */

// 输出当前状态模式--输出控制移动方向
assign state_m = state_c; 
assign move_d  = move_dirt; 

/* 状态跳转 */
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        state_c <= START;
    else 
        state_c <= state_n;
end
/*按键延时*/
always@(posedge clk or negedge rst_n) begin
	if(~rst_n)begin
		key_delay <= 4'b1111;
		delay_cnt <= 32'd0;
		end
	else if(delay_cnt == 32'd100_0000)begin
		key_delay <= key;
		delay_cnt <= delay_cnt;
		end
	else begin 
		key_delay <= 4'b1111;
		delay_cnt <= delay_cnt + 32'd1;
		end
end
/* 下一个状态的判断 */
always @(*) begin
    case(state_c)
        START:  begin                 // START开始界面
            if(change_cond == 2'b01)   // START界面中，判断有任意按键按下，进入游戏速度选择
                state_n = SPEED;
            else 
                state_n = START;
        end 
        
        SPEED:  begin                 // SPEED速度选择界面
            if(change_cond == 2'b10)   // SPEED状态下，按下key[0]--上键 或key[1]--下键切换至PLAY
                state_n = PLAY;       
            else 
                state_n = SPEED;
        end
        
        PLAY:  begin                  // PLAY游戏界面
           if(game_over)
                state_n = END;
            else 
                state_n = PLAY;
        end
        
        END:    begin                 // END游戏结束页面
            if(change_cond == 2'd0)   // END界面中，按下key[0]--上键，重新开始游戏
                state_n =  START;  
            else
                state_n =  END;
        end
        
        default: 
                state_n = START; 
    endcase
end

/* 各个状态下的动作 */ 
// SPEED状态下，根据不同按键的输入选择--快速或者慢速
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        speed_m <= 1'b1;   
    else begin
        if(state_c == SPEED) 
            if(!key_delay[0]) 
                speed_m <= 2'b11;    
            else if(!key_delay[1])
                speed_m <= 2'b10;    
            else if(!key_delay[2])
				speed_m <= 2'b01;    
            else if(!key_delay[3])
                speed_m <= 2'b00;    
            else 
                speed_m <= 2'b00;    
    end   
end

// 刚进入PLAY游戏模式，延时500ms后按键使能信号置高
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) begin
        play_cnt <= 32'd0;
        play_key <= 1'b0;
    end
    else if(state_c == START) begin     // 重新进入游戏时，拉低按键使能信号，等待PLAY中延时500ms后再拉高
        play_cnt <= 32'd0; 
        play_key <= 1'b0;
    end
    else if(state_c == PLAY) begin
        if(play_cnt == 32'd12_500_000) begin
            play_key <= 1'b1;
            play_cnt <= 32'd0;
        end
        else
            play_cnt <= play_cnt + 1'b1;
    end
end

// PLAY状态下，根据不同按键的输入选择--上、下、左、右控制方向信号
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        move_dirt <= RIGHT;         // 默认右移
    else if(state_c == START)
        move_dirt <= RIGHT;         // 重新进入游戏时右移
    else if(play_key == 1'b1) begin
        case(key_delay)
            4'b1110: begin          // key[0]--上移,当前为左-右行进时，上键有效  
                if(move_dirt == LEFT || move_dirt == RIGHT)
                    move_dirt <= UP;         
                else
                    move_dirt <= move_dirt;
            end
            4'b1101: begin          // key[1]--下移,当前为左-右行进时，下键有效  
                if(move_dirt == LEFT || move_dirt == RIGHT)
                    move_dirt <= DOWN;         
                else
                    move_dirt <= move_dirt;       
            end
            4'b1011: begin          // key[2]--左移,当前为上-下行进时，左键有效  
                if(move_dirt == UP || move_dirt == DOWN)
                    move_dirt <= LEFT;         
                else
                    move_dirt <= move_dirt;             
            end
            4'b0111: begin          // key[3]--右移,当前为上-下行进时，右键有效
                if(move_dirt == UP || move_dirt == DOWN)
                    move_dirt <= RIGHT;         
                else
                    move_dirt <= move_dirt;       
            end
            default: move_dirt <= move_dirt;  // 其他情况保持默认方向
        endcase
    end   
    else move_dirt <= move_dirt;  // 其他情况保持默认方向
end


// 在START、SPEED、END模式下，由按键控制状态跳转条件，PLAY状态中由外界输入的死亡信号判断跳转
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)  begin
        change_cond <= 2'b0;
 //       key_reg     <= 4'b1111;   
    end   
    else begin
   //     key_reg <= key_delay;
        if(key_delay != 4'b1111)  begin    
            if(state_c == START && (key_delay == 4'b0111))                               // START状态下，按下KEY4切换至SPEED
                change_cond <= 2'b01;     
            else if(state_c == SPEED )  // SPEED状态下，按下key[0]--上键 或key[1]--下键切换至PLAY
                case(key_delay) 	
					4'b1110:change_cond <= 2'b10;
					4'b1101:change_cond <= 2'b10;
					4'b1011:change_cond <= 2'b10;
					//4'b0111:change_cond <= 2'b10;
					default:change_cond <= change_cond;
				endcase
            else if(state_c == END && key_delay[0])                 // END状态下，按下key[0]--上键切换至START
                change_cond <= 2'b0;
            else    
                change_cond <= change_cond;
        end
        else
            change_cond <= change_cond; 
    end   
end

endmodule 