    .text
    .balign 4
    .global vvaddint32
    # 32 位整数的向量加法函数
    # void vvaddint32(size_t n, const int*x, const int*y, int*z)
    # { for (size_t i=0; i<n; i++) { z[i]=x[i]+y[i]; } }
    #
    # a0 = n, a1 = x, a2 = y, a3 = z
    # 非向量指令缩进对齐
vvaddint32:
    vsetvli t0, a0, e32, ta, ma  # 根据 32 位向量设置向量长度
    vle32.v v0, (a1)         # 读取第一个向量
      sub a0, a0, t0         # 减少剩余元素计数
      slli t0, t0, 2         # 计算已处理字节数
      add a1, a1, t0         # 更新指针
    vle32.v v1, (a2)         # 读取第二个向量
      add a2, a2, t0         # 更新指针
    vadd.vv v2, v0, v1       # 计算向量加法
    vse32.v v2, (a3)         # 存储结果
      add a3, a3, t0         # 更新指针
      bnez a0, vvaddint32    # 若未完成，则继续循环
      ret                    # 结束
