    .text
    .balign 4
    .global strcmp
  # int strcmp(const char *src1, const char* src2)
strcmp:
    ## 使用 LMUL=2，但相同的寄存器名称可以适用于更大的 LMUL 值
    li t1, 0                # 初始化指针偏移
loop:
    vsetvli t0, x0, e8, m2, ta, ma  # 设置最大向量长度（按 8 位处理）
    add a0, a0, t1          # 更新 src1 指针
    vle8ff.v v8, (a0)       # 读取 src1 字节数据
    add a1, a1, t1          # 更新 src2 指针
    vle8ff.v v16, (a1)      # 读取 src2 字节数据

    vmseq.vi v0, v8, 0      # 标记 src1 结束符（零字节）
    vmsne.vv v1, v8, v16    # 标记 src1 和 src2 不相等的字节
    vmor.mm v0, v0, v1      # 组合退出条件
    
    vfirst.m a2, v0         # 找到第一个满足条件的位置
    csrr t1, vl             # 读取当前向量长度（VL）
        
    bltz a2, loop           # 如果没有找到零字节且两个字符串相同，则继续循环

    add a0, a0, a2          # 获取 src1 元素地址
    lbu a3, (a0)            # 从内存中获取 src1 字节

    add a1, a1, a2          # 获取 src2 元素地址
    lbu a4, (a1)            # 从内存中获取 src2 字节

    sub a0, a3, a4          # 返回值

    ret
