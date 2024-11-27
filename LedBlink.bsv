// 综合参数: bsvbuild.sh -v LedBlink.bsv top

package LedBlink;

import ConfigReg::*;

// 闪烁计时周期
`define BLINK_COUNT	10_000_000

// 顶层输入输出接口
(* always_enabled *) // 删除 Verilog 多余的 RDY 和 EN 信号
interface ITop;
	// output wire led
	method bit led;
endinterface

// 顶层模块实现
(* synthesize, clock_prefix="clk", reset_prefix="rst_n" *) // 综合成 Verilog
module top(ITop);
	// 32 位计数器, 同步复位值为 0
	Reg#(Bit#(32)) r_counter <- mkConfigReg(0);
	Reg#(bit) r_led <- mkConfigReg(0);

	// update 规则
	// 根据当前的调度规则, 触发条件每周期都成立, 所以每周期都会执行
	rule update;
		// 以 BLINK_COUNT 为周期计数
		if (r_counter < `BLINK_COUNT) begin
			r_counter <= r_counter + 1;
		end
		else begin
			r_counter <= 0;
			// 计时器溢出, 翻转 LED
			r_led <= ~r_led;
		end
	endrule

	// 关联 ITop.led 方法的返回值到 r_led 寄存器 
	method led = r_led;
endmodule

endpackage