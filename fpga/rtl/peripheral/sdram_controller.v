module sdram_controller #(
	/*clk=100MHZ*/
	parameter T_PowerUp=32'd20000,/*上电时间*/
						T_RP=32'd2,					/*预充电时间*/
						T_RFC=32'd7,				/*自动刷新时间*/
						T_MRD=32'd2,				/*设置模式寄存器时间*/
						T_CL=32'd3,					/*潜伏期*/
						T_RCD=32'd2,				/*行激活到列读写延迟*/
						T_ReadNum=32'd2,		/*读出数据的数量*/
						T_WR=32'd2,					/*写完后等待的时间*/
						T_REFPERIOD=750			/*刷新周期*/
	)(
	clk,
	rest,
	avalon_address,
	avalon_writeEn,
	avalon_writeData,
	avalon_readEn,
	avalon_readData,
	avalon_byteEnable,
	avalon_writeQuest,
	/*SDRAM 芯片接口*/
	sdram_clk,
	sdram_cke,
	sdram_cs_n,
	sdram_ras_n,
	sdram_cas_n,
	sdram_we_n,
	sdram_bank,
	sdram_addr,
	sdram_data,
	sdram_dqm
);
/********************************************************************************************************
端口申明
********************************************************************************************************/
/*avalon接口信号*/
input clk,rest;
input[22:0] avalon_address;
input avalon_writeEn;
input[31:0] avalon_writeData;
input	avalon_readEn;
output reg[31:0] avalon_readData;
input[3:0] avalon_byteEnable;
output reg avalon_writeQuest;
/*SDRAM 芯片接口*/
output sdram_clk;            /*SDRAM 芯片时钟  */
output sdram_cke;            /*SDRAM 时钟有效  */
output sdram_cs_n;           /*SDRAM 片选 		  */
output sdram_ras_n;          /*SDRAM 行有效 	  */
output sdram_cas_n;          /*SDRAM 列有效 	  */
output sdram_we_n;           /*SDRAM 写有效 	  */
output reg[ 1:0] sdram_bank; /*SDRAM Bank地址 */	
output reg[12:0] sdram_addr; /*SDRAM 行/列地址 */
inout[15:0] sdram_data;      /*SDRAM 数据 		  */
output reg[ 1:0] sdram_dqm;  /*SDRAM 数据掩码  */
/********************************************************************************************************
宏定义
********************************************************************************************************/
/*SDRAM控制信号命令*/
`define		CMD_INIT 	    5'b01111		/* INITIATE*/					
`define		CMD_NOP		    5'b10111		/* NOP COMMAND*/			
`define		CMD_ACTIVE	  5'b10011		/* ACTIVE COMMAND*/						
`define		CMD_READ	    5'b10101		/* READ COMMADN*/					
`define		CMD_WRITE	    5'b10100		/* WRITE COMMAND*/	
`define		CMD_B_STOP	  5'b10110		/* BURST STOP*/					
`define		CMD_PRGE	    5'b10010		/* PRECHARGE*/					
`define		CMD_A_REF	    5'b10001		/* AOTO REFRESH*/					
`define		CMD_LMR		    5'b10000		/* LODE MODE REGISTER*/					

`define end_i_powerUp									(count>=T_PowerUp-32'd1)
`define end_i_prechargeAllBanks				(count>=T_RP-32'd1)
`define end_i_autoRef									(count>=2*T_RFC-32'd1)
`define end_i_setModeReg							(count>=T_MRD-32'd1)
`define end_w_autoRef									(count>=T_RFC-32'd1)
`define end_w_activeRow								(count>=T_RCD-32'd1)
`define end_w_readCmd									(count>=T_CL-32'd1)
`define end_w_readData								(count>=T_ReadNum-32'd1)
`define end_w_writeData								(count>=(T_WR+T_RP+32'd2-32'd1))/*写完后等两个时钟周期*/
localparam ModeRegValue={
	2'b00,/*保留*/
	3'b000,/*保留*/
	1'b0,/*突发读/写*/
	2'b00,/*保留*/
	3'b010,/*潜伏期为2*/
	1'b0,/*顺序模式*/
	3'b001/*突发长度为2*/
};

/********************************************************************************************************
寄存器
********************************************************************************************************/
reg[15:0] sdram_outputData;
reg[4:0] sdram_cmd=`CMD_INIT;
reg[31:0] count=0;
reg startRef=0;
reg[15:0] sdram_dataBuff=16'd0;
wire isNeedRef;

initial begin
	avalon_writeQuest=1'd1;
end

/********************************************************************************************************
端口数据
********************************************************************************************************/
assign sdram_data=avalon_writeEn?sdram_outputData:16'hzzzz;
assign sdram_clk=~clk;
assign {sdram_cke,sdram_cs_n,sdram_ras_n,sdram_cas_n,sdram_we_n}=sdram_cmd;

/********************************************************************************************************
状态机
********************************************************************************************************/
localparam i_powerUp										=8'd0,/*等待上电稳定*/
					 i_prechargeAllBanks					=8'd1,/*给所有的Bank预充电*/
					 i_autoRef                    =8'd2,/*自动刷新2次*/
					 i_setModeReg                 =8'd3,/*设置模式寄存器*/
					 w_idle												=8'd4,/*空闲状态*/
					 w_autoRef										=8'd5,/*定时自动刷新*/
					 w_activeRow									=8'd6,/*激活行*/
					 w_readCmd										=8'd7,/*发出读命令,同时给出数据的列地址*/
					 w_readData										=8'd8,/*读出数据*/
					 w_writeData									=8'd9,/*写入数据并等待数据写完*/
					 w_percharge									=8'd10;/*预充电(不使用自动预充电)*/

reg[7:0] state=i_powerUp;
/*第一段:计算下一个clock的状态*/
always @(posedge clk or negedge rest) begin
	if(!rest) begin
		state=i_powerUp;
	end
	else begin
		case(state)
			i_powerUp:begin
					state<=`end_i_powerUp?i_prechargeAllBanks:i_powerUp;/*等一段时间后进入下一个状态*/
				end
			i_prechargeAllBanks:begin
					state<=`end_i_prechargeAllBanks?i_autoRef:i_prechargeAllBanks;
				end
			i_autoRef:begin
					state<=`end_i_autoRef?i_setModeReg:i_autoRef;
				end
			i_setModeReg:begin
					state<=`end_i_setModeReg?w_idle:i_setModeReg;
				end
			w_idle:begin
					if(isNeedRef) begin
						state<=w_autoRef;
					end
					else begin
						state<=(avalon_readEn|avalon_writeEn)&&avalon_writeQuest?w_activeRow:w_idle;
					end
				end
			w_autoRef:begin
					state<=`end_w_autoRef?w_idle:w_autoRef;
				end
			w_activeRow:begin
					if(`end_w_activeRow) begin
						case({avalon_readEn,avalon_writeEn})
							2'b01:state<=w_writeData;
							2'b10:state<=w_readCmd;
							default:begin
								state<=w_idle;
							end
						endcase
					end
					else begin
						state<=w_activeRow;
					end
				end
			w_readCmd:begin
					state<=`end_w_readCmd?w_readData:w_readCmd;
				end
			w_readData:begin
					state<=`end_w_readData?w_idle:w_readData;
				end
			w_writeData:begin
					state<=`end_w_writeData?w_idle:w_writeData;
				end
			default:begin
					state<=i_powerUp;
				end
		endcase
	end
end
/*第二段:信号输出*/
always @(posedge clk) begin
	case(state)
		i_powerUp:begin
				sdram_cmd<=`end_i_powerUp?`CMD_NOP:`CMD_INIT;
				/*count自加1*/
				count<=`end_i_powerUp?32'd0:(count+32'd1);
			end
		i_prechargeAllBanks:begin
				sdram_cmd<=(count==0)?`CMD_PRGE:`CMD_NOP;
				sdram_addr[10]<=1'd1;/*所有Bank预充电*/
				/*count自加1*/
				count<=`end_i_prechargeAllBanks?32'd0:(count+32'd1);
			end
		i_autoRef:begin
				sdram_cmd<=((count==32'd0)||(count==T_RFC))?`CMD_A_REF:`CMD_NOP;
				/*count自加1*/
				count<=`end_i_autoRef?32'd0:(count+32'd1);
			end
		i_setModeReg:begin
				sdram_cmd<=(count==32'd0)?`CMD_LMR:`CMD_NOP;
				{sdram_bank,sdram_addr}=ModeRegValue;
				/*count自加1*/
				count<=`end_i_setModeReg?32'd0:(count+32'd1);
			end
		w_idle:begin
				sdram_cmd<=`CMD_NOP;
				count<=32'd0;
				startRef<=1'd0;
				avalon_writeQuest<=1'd1;
			end
		w_autoRef:begin
				startRef<=(count==32'd0)?1'd1:1'd0;
				sdram_cmd<=(count==32'd0)?`CMD_A_REF:`CMD_NOP;
				/*count自加1*/
				count<=`end_w_autoRef?32'd0:(count+32'd1);
			end
		w_activeRow:begin
				sdram_cmd<=(count==32'd0)?`CMD_ACTIVE:`CMD_NOP;
				sdram_bank<=avalon_address[22:21];
				sdram_addr<=avalon_address[20:8];
				/*count自加1*/
				count<=`end_w_activeRow?32'd0:(count+32'd1);
			end
		w_readCmd:begin
				sdram_cmd<=(count==32'd0)?`CMD_READ:`CMD_NOP;
				sdram_bank<=avalon_address[22:21];
				sdram_addr<={2'd0,1'b1,1'b0,avalon_address[7:0],1'b0};/*使能自动预充电*/
				sdram_dqm<=2'b00;
				/*count自加1*/
				count<=`end_w_readCmd?32'd0:(count+32'd1);
			end
		w_readData:begin
				avalon_readData<=(avalon_readData<<32'd16)|sdram_dataBuff;
				avalon_writeQuest<=`end_w_readData?1'd0:1'd1;				
				sdram_dqm<=2'b00;
				/*count自加1*/
				count<=`end_w_readData?32'd0:(count+32'd1);
			end
		w_writeData:begin
				sdram_cmd<=(count==32'd0)?`CMD_WRITE:`CMD_NOP;
				sdram_bank<=avalon_address[22:21];
				sdram_addr<={2'd0,1'b1,1'b0,avalon_address[7:0],1'b0};/*使能自动预充电*/
				case(count[3:0])
					32'd0:begin
							sdram_outputData<=avalon_writeData[31:16];
							sdram_dqm<=~avalon_byteEnable[3:2];
						end
					32'd1:begin
							sdram_outputData<=avalon_writeData[15:0];
							sdram_dqm<=~avalon_byteEnable[1:0];
						end
					default:begin
							sdram_outputData<=16'd0;
							sdram_dqm<=2'd0;
						end
				endcase
				avalon_writeQuest<=(count[3:0]==32'd1)?1'd0:1'd1;			
				/*count自加1*/
				count<=`end_w_writeData?32'd0:(count+32'd1);
			end
		default:begin
			end
	endcase
end

reg[31:0] refCount=32'd0;
assign isNeedRef=refCount==32'd0;
always @(posedge clk or negedge rest) begin
	if(!rest) begin
		refCount<=32'd0;
	end
	else begin
		if(startRef) begin
			refCount<=T_REFPERIOD;
		end
		else begin
			refCount<=isNeedRef?refCount:(refCount-32'd1);
		end
	end
end

always @(negedge clk) begin
	sdram_dataBuff<=sdram_data;
end

endmodule
