    .text
    .balign 4
    .global strlen
# size_t strlen(const char *str)
# a0 保存 *str

strlen:
    mv a3, a0             # 保存起始地址
loop:
    vsetvli a1, x0, e8, m8, ta, ma  # 设置最大长度的字节向量
    vle8ff.v v8, (a3)      # 加载字节
    csrr a1, vl           # 获取读取的字节数
    vmseq.vi v0, v8, 0    # 设置 v0[i]，当 v8[i] = 0 时
    vfirst.m a2, v0       # 找到第一个设置的位
    add a3, a3, a1        # 增加指针
    bltz a2, loop         # 没找到？

    add a0, a0, a1        # 起始地址 + 增量
    add a3, a3, a2        # 增加索引
    sub a0, a3, a0        # 减去起始地址 + 增量

    ret