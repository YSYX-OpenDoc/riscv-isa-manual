    .text
    .balign 4
    .global saxpy
# void
# saxpy(size_t n, const float a, const float *x, float *y)
# {
#   size_t i;
#   for (i=0; i<n; i++)
#     y[i] = a * x[i] + y[i];
# }
#
# 寄存器参数：
#     a0      n
#     fa0     a
#     a1      x
#     a2      y

saxpy:
    vsetvli a4, a0, e32, m8, ta, ma  # 设置向量长度（32 位浮点数）
    vle32.v v0, (a1)                 # 读取 x 向量
    sub a0, a0, a4                   # 递减计数
    slli a4, a4, 2                    # 计算已处理字节数
    add a1, a1, a4                    # 更新 x 指针
    vle32.v v8, (a2)                   # 读取 y 向量
    vfmacc.vf v8, fa0, v0              # 计算 a*x + y
    vse32.v v8, (a2)                   # 存储结果到 y
    add a2, a2, a4                    # 更新 y 指针
    bnez a0, saxpy                    # 若未完成，则继续循环
    ret                                # 返回
