- 入门教程:
  https://github.com/WangXuan95/BSV_Tutorial_cn
  https://github.com/kcamenzind/BluespecIntroGuide/blob/master/BluespecIntroGuide.md

- 进阶:
  https://github.com/oxidecomputer/quartz/tree/main/hdl/ip/bsv
  https://github.com/csail-csg/recycle-bsv-lib
  github 代码搜索 path:*.bsv

- 官方文档:
  https://github.com/B-Lang-org/bsc/releases/latest/download/bsc_user_guide.pdf
  https://github.com/B-Lang-org/bsc/releases/latest/download/BSV_lang_ref_guide.pdf
  https://github.com/B-Lang-org/bsc/releases/latest/download/bsc_libraries_ref_guide.pdf

- WSL 配置
  - 在 Microsoft Store 里安装 Ubuntu 24.04
  - 把 wsl.exe 加入 Proxifier
  - 更新 WSL:
    wsl --set-default-version 2
    wsl --update --web-download
  - 使用网络镜像模式:
    - 在 %UserProfile%/.wslconfig 内添加
    [wsl2]
    networkingMode=mirrored

- 安装
  - 安装 bsc:
    - https://github.com/B-Lang-org/bsc/releases
    - 下载 bsc-2024.07-ubuntu-22.04.tar.gz
    - 解压: sudo tar -C /opt/ -zxvf bsc-2024.07-ubuntu-24.04.tar.gz
    - 将以下两行追加到 .bashrc 文件的末尾 (目的是把 bsc 和相关 lib 添加到永久环境变量)
      export PATH=/opt/bsc/bin:$PATH
      export LIBRARY_PATH=/opt/bsc/lib:$LIBRARY_PATH
  - 安装 iverilog:
    sudo apt install iverilog tcl-dev
  - 复制 bsvbuild.sh:
    sudo cp bsvbuild.sh /opt/bsc/bin/
  - VSCode 扩展:
    Bluespec (作者: Martin Chan)
  
- bsvbuild.sh 的编译参数 <param> 的取值及其含义
    <param>    生成Verilog    仿真方式    仿真打印    生成仿真波形(.vcd)
    -bs                       BSV         √
    -bw                       BSV                     √
    -bsw                      BSV         √           √
    -v         √
    -vs        √              Verilog     √
    -vw        √              Verilog                 √
    -vsw       √              Verilog     √           √


- 文件结构示例
    package Hello;
    import OtherPackage::*;
    
    module mkTb#(parameter type name) (ifc_name);
        rule hello;
            $display("Hello world!");
            $finish;
        endrule
    endmodule
    
    endpackage


- 接口 interface
    interface DecCounter;
        method UInt#(4) count;
        method Bool overflow;
    endinterface
  - 首字母大写
  - 值方法: 返回一个变量, 不改变被调用模块内的状态, 一般用于输出
    - method ty name;
    - 不能调用有副作用的方法, 例如本模块内的动作/动作值方法
    - 可以有隐式条件
  - 动作方法: 可以接受一组参数, 会改变被调用模块内的状态, 一般用于输入
    - method Action name(ty ...);
    - 可以有隐式条件
  - 动作值方法: 可以接受一组参数, 返回一个变量, 会改变被调用模块内的状态
    - method ActionValue#(ty) name(ty ...);
  - 方法的隐式条件: 参数列表后跟 if
    - method ret_type name if (xxx);
  - 方法简写: 可继承方法及其隐式条件
    - method name = instance.name;
  - 空接口: Empty
    - 无接口的 module 本质上继承自空接口

- 函数 function
    function Bit#(6) test(Bit#(6) value)
    provisos(...);
        return value;
    endfunction
  - 主要用于代码复用
  - 只能被本模块调用, 不能被其他模块调用
  - 函数内可嵌套函数
  - 返回 Action 用于包装一个周期内执行的多条语句
  - 返回 Stmt 用于包装一组状态机语句
  - module 可以视为一个特殊的 function, 可以 return


- 类型派生示例
    typedef struct
    {
        UInt#(48) dst_mac;
        UInt#(48) src_mac;
        UInt#(16) pkt_type;
    } EthHeader deriving(Bits, Eq);
    // 实例化
    EthHeader hdr = EthHeader{ dst_mac: 'h666, src_mac: 'h666, pkt_type: 0 };

- 枚举
    typedef enum {Green, Yellow, Red} Light deriving(Eq, Bits);
  - 编译器会自动分配占用的位宽


- 规则示例
    rule 规则名称(显式条件);
    ...
    endrule
  - 写在规则内的变量都是局部生命周期的组合逻辑
  - 单个规则对应一个 Action, 在一个时钟内满足条件后只执行一次
  - 在一个时钟内, 冲突的规则永远不会同时激活, 紧急的规则激活, 不紧急的不激活
  - 规则激活需要:
    - 满足显式条件成立
    - 规则内的语句具有隐式条件时, 满足隐式条件成立
    - 与其他规则冲突时, 满足紧急程度约束
    - if 语句不参与规则激活判断, 开启 -aggressive-conditions 除外
  - 规则具有
    - 瞬时性: 同周期内多个激活的规则是瞬时执行的
    - 原子性: 如果规则激活, 则规则内所有语句都执行
    - 有序性: 根据每个规则内的代码进行排序, 让执行顺序满足调度注解

- 调度属性
  - descending_urgency: 指定规则的紧急程度. 发生排序冲突时, 紧急的抑制不紧急的
    - 有传递关系
    - 指定的规则如果不冲突, 则可以在同一个周期内执行
    - 用于在多个规则冲突时, 选择第一个规则执行
    - 用于解决编译器分析出的排序冲突的情况
    - 用于解决警告 Rule "A" was treated as more urgent than "B".
    - (* descending_urgency="rule1, rule2, ..." *)
  - mutually_exclusive: 指定规则不会在同一周期激活(没有冲突, 是互斥的)
    - 编译时无警告, 会在运行时插入断言
    - (* mutually_exclusive="rule1, rule2, ..." *)
  - conflict_free: 指定规则可以同时激活, 但潜在的冲突不会同时执行
    - 编译时无警告, 会在运行时插入断言
    - (* conflict_free="rule1, rule2, ..." *)
  - preempts: 给两个规则强制加上冲突, 同时指定紧急程度
    - 没有传递关系
    - 指定的规则在同一个周期内完全互斥, 一个规则执行了, 其他的就不执行
    - 相当于规则激活条件的 else
    - 用于解决警告 Rule `A' shadows the effects of `B' when they execute in the same clock cycle.
    - (* preempts="rule1, rule2" *)
    - (* preempts="(r1, r2), r3" *) 等效于 "r1, r3", "r2, r3"
    - (* preempts="r1, (r2, r3)" *) 等效于 "r1, r2", "r1, r3"
  - execution_order: 重排规则的执行顺序
    - 默认执行顺序是规则的编写顺序, 该属性可重新指定顺序
    - 对 shadows the effects of 的情况有用
  - fire_when_enabled: 断言规则的显式和隐式条件为真时, 必须被执行
    - (* fire_when_enabled *)
  - no_implicit_conditions: 断言规则内如果存在隐式条件, 则都为真
    - (* no_implicit_conditions *)


- 元属性
  - synthesize: 综合成 Verilog 模块
  - always_enabled: 删除不必要的 EN 信号, 可用于标注输入信号, 包含了 always_ready
  - always_ready: 删除不必要的 RDY 信号, 可用于标注输出信号
  
  
- 常量定义
  - 与 Verilog 相同
  - 自适应右值
  - '0: 代表所有位为 0
  - '1: 代表所有位为 1


- 赋值
  - =: 绑定
    - module 内寄存器: 左值绑定到右值, 成为右值的副本. 类似 verilog 的 assign
    - action 内变量: 组合逻辑的临时变量
  - <-: 副作用赋值. 其返回值绑定到变量
    - 右值有副作用, 例如实例化和调用 ActionValue 方法
    - 副作用赋值隐含了调用语义, 所以跟绑定赋值区分开
    - 所以凡是 Module/ActionValue 这类可调用对象, 都需要使用副作用赋值
  - <=: 等价于调用其 _write() 方法
  - Reg#(ty) 类型的变量名称等价于调用其 _read() 方法
  

- 基本派生类型
  - Bits: 可与 Bit#(n) 互相转换
    - pack(): 其他类型转为 Bit#(n)
    - unpack(): Bit#(n) 转为其他类型
  - Eq: 可判断相等
  - Ord: 可比较大小
  - Arith: 可进行算数运算
  - Literal: 可从整数字面量创建
  - RealLiteral: 可从实数字面量创建
  - Bounded: 具有有限范围
  - Bitwise: 可进行按位运算
  - BitReduction: 可逐位进行合并运算
  - BitExtend: 可进行位扩展运算
    - truncate(): 高位截断
    - zeroExtend(): 高位补零扩展
    - signExtend(): 高位符号扩展
    - extend(): 根据参数类型自动选择 zero/signExtend 扩展


- 关系要求
  - Add#(n, m, k): n+m=k
  - Mul#(n, m, k): n*m=k
  - Div#(n, m, k): n/m=k
  - Max#(n, m, k): max(n,m)=k
  - Min#(n, m, k): min(n,m)=k
  - Log#(n, m): ceil(log2(n))=m
  
- 数值函数
  - TAdd#(n, m): n+m
  - TSub#(n, m): n-m
  - TMul#(n, m): n*m
  - TDiv#(n, m): n/m
  - TLog#(n): ceil(log2(n))
  - TExp#(n): 2^n
  - TMax#(n, m): max(n,m)
  - TMin#(n, m): min(n,m)
  
- 伪函数
  - SizeOf#(td): 返回类型位宽, 类型是 numeric type
  - valueOf#(td): 把 numeric type 转换为 Integer

- 基本数据类型(派生自 Bits)
  - Bit#(n): 位向量
    - bit: Bit#(1) 的别名
  - UInt#(n): 无符号整数, 范围 0 ~ 2^n-1
  - Int#(n): 有符号整数, 范围 -2^(n-1) ~ 2^(n-1)-1
    - int: Int#(32) 的别名
  - Bool: 布尔 True/False, 可进行逻辑运算. 所有条件语句的类型


- 特殊数据类型(不派生自 Bits)
  - Integer: 无界整数, 进行算术运算永远不会溢出. 可用于仿真和下标, 不可作为寄存器取值
    - fromInteger(): 转换为 Bit#(ty)
  - String: 字符串，一般用作仿真打印/指定仿真文件名等作用
  - let: 编译器推断


- 元组类型 TupleN#(...)
  - 可组合多个类型. Tuple2#(Bool, Int#(9)) = tuple2(True, -25)
  - tupleN(): 打包 N 个元素
  - tpl_N(): 获取第 N 个元素, 从 1 开始
  - match{}: 承接元素: match { .va, .vb } = t2; 
  - split(): Bit#(n) 转为 TupleN#


- 可选类型 Maybe#(ty)
  - 可选类型, Maybe#(Int#(9)) value
  - tagged Invalid: 无效值
  - tagged Valid 42: 有效值
  - isValid(): 判断值是否有效
  - fromMaybe(默认值, 可选类型): 返回可选类型的值, 无效则返回默认值


- 调度注解
  - CF:  在同一周期内无冲突, 按照编写顺序执行
  - SB:  在同一周期内, 按照后 B 先 A 的顺序执行
  - SA:  在同一周期内, 按照后 A 先 B 的顺序执行
  - SBR: 后 B 先 A, 只能写在不同规则
  - SAR: 后 A 先 B, 只能写在不同规则
  - C:   无法在同一个周期内执行, 只能写在不同规则


- 寄存器 Reg#(ty)
  - mkConfigReg: 无排序寄存器. 需 import ConfigReg::*;
    - 允许以任意顺序进行读取和写入
    - 在同一周期内读取的是旧值, 与 Verilog 的 reg 行为一致
    - 调度注解:
      A\B       _read  _write
      _read     CF     CF
      _write    CF     SBR
  - mkReg: 有排序寄存器, 在同步复位信号下初始化为默认值
  - mkRegU: 没有默认值
  - mkDReg: 数据只保留 1 个周期, 其余时刻读取的是默认值. 需 import DReg::*;
  - mkReg/mkRegU/mkDReg 的调度注解:
      A\B       _read  _write
      _read     CF     SB
      _write    SA     SBR
  - mkCReg: 并发寄存器 (EHR)
    - 存在形式为寄存器数组
    - 同一下标间的操作等同于 mkReg
    - 下标为 0 的接口 _read 可得到上一周期的值
    - _write 下标小的接口, 在同周期内可从下标大的接口 _read 出来, 如果没有则 _read 得到的是上个下标接口的值
    - 对于同一个接口间的 _read 和 _write, mkCReg 呈现出 mkReg 的行为
    - 对于下标小的接口的 _write 和下标大的接口的 _read, mkCReg 呈现出 mkDWire 的行为, _read 会读到本周期 _write 的新值

- 线网 Wire#(ty)
  - 用于在当前周期内传递数据, 不保存数据
  - mkDWire: 如果同周期有写入则读出写入值, 否则读出默认值
  - mkWire: 没有默认值
  - mkBypassWire: 每个周期都必须存在写入
  - mkDWire/mkWire/mkBypassWire 的调度注解:
      A\B       _read  _write
      _read     CF     SAR
      _write    SBR    C
  - mkRWire: 可判断是否存在写入的值. 接口是 RWire, 注意: 不可假定依赖它的分离操作是原子的
  - mkRWire 的调度注解:
      A\B       wget  wset
      wget      CF    SAR
      wset      SBR   C
  - mkPulseWire: 不带数据的 mkRWire. 接口是 PulseWire
  - mkPulseWire 的调度注解:
      A\B       _read  send
      _read     CF     SAR
      send      SBR    C

- FIFO
  - FIFO#(type): 基础队列接口
    - clear: 清空
    - enq: 入列(不满时)
    - deq: 出列(不空时)
    - first: 取首元素(不空时)
  - FIFOF#(type): 额外支持查询功能
    - notEmpty: 是否非空
    - notFull: 是否非满
  - mkFIFO:
    - 容量: 2
    - 同周期可入列/出列/取数据
    - 不空不满时并发
    - mkDFIFOF: 具有默认值的 mkFIFO, deq/first 不含隐式条件
  - mkFIFO1:
    - 容量: 1
    - 同周期可出列/取数据
    - 为空时可入列
    - 无并发
  - mkLFIFO:
    - 容量: 1
    - 同周期可入列/出列/取数据
    - 满时并发
    - 反压信号是组合逻辑, 可能造成时序变差
  - mkBypassFIFO
    - 容量: 1
    - 同周期可入列/出列
    - 空时并发
    - enq 同周期内可以 first, 类似能保存数据的 mkWire
    

- 状态机 FSM
  - import StmtFSM::*;
  - FSM xx <- mkFSMWithPred(Stmt, pred);
    - start(): 开始运行状态机(状态机空闲时)
    - waitTillDone(): 等待状态机运行结束(状态机空闲时)
    - Bool done(): 判断状态机是否空闲
    - abort(): 如果状态机正忙则强制结束
  - Stmt: 状态机语句的类型
  - seq ... endseq: 顺序操作, 每个语句占一个时钟周期
  - action ... endaction: 原子操作, 内部所有语句隐式条件满足时才执行. 整块语句占 1 个时钟周期
  - par ... endpar: 异步并行执行, 内部所有语句完毕后结束. 类似 join
  - await(): 根据一个 Bool 类型创建一个具有隐式条件的动作
        seq
            await(sfsm.done);
        endseq
  - delay(n): 延迟 n 个周期
  - noAction: 什么都不做, 消耗一个周期
  - repeat(n): 重复执行 n 次
  - 所有单周期环境下(例如状态机外部或者 Action), for/while 都会被完全展开
  - mkAutoFSM: 自动运行完毕后执行 $finish, 主要用于写 tb

- 时钟
  - 时钟可包含一个振荡器, 一个门控, 它们实现为线网
  - 所有 rule 和 method 都有时钟
  - rule 和 action 依赖的所有时钟门控必须开启才为 ready
  - 值方法不受时钟门控影响
  - clocked_by: 创建实例时隐式指定时钟
  - reset_by: 创建实例时隐式指定复位
  - exposeCurrentClock: 获取当前默认时钟
  - exposeCurrentReset: 获取当前默认复位
  - clockOf: 获取实例绑定的时钟
  - mkGatedClock(gate): 从当前时钟创建一个时钟, 门控为 gate