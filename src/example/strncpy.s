    .text
    .balign 4
    .global strncpy
  # char* strncpy(char *dst, const char* src, size_t n)
strncpy:
      mv a3, a0             # 复制目标地址
loop:
    vsetvli x0, a2, e8, m8, ta, ma   # 设置向量为字节（8位）的向量.
    vle8ff.v v8, (a1)        # 加载源地址的字节数据
    vmseq.vi v1, v8, 0      # 标记零字节
      csrr t1, vl           # 获取已取字节的数量
    vfirst.m a4, v1         # 是否找到零字节？
    vmsbf.m v0, v1          # 设置掩码，标记零字节之前的部分
    vse8.v v8, (a3), v0.t    # 写入非零字节到目标地址
      bgez a4, zero_tail    # 如果有剩余零字节，则跳到零字节处理
      sub a2, a2, t1        # 减少字节计数
      add a3, a3, t1        # 增加目标指针
      add a1, a1, t1        # 增加源指针
      bnez a2, loop         # 是否还有字节需要处理？

      ret

zero_tail:
    sub a2, a2, a4          # 从字节计数中减去已处理的非零字节数量
    add a3, a3, a4          # 跳过已处理的非零字节
    vsetvli t1, a2, e8, m8, ta, ma   # 设置向量为字节（8位）的向量
    vmv.v.i v0, 0           # 填充零

zero_loop:
    vse8.v v0, (a3)          # 存储零字节
      sub a2, a2, t1        # 减少字节计数
      add a3, a3, t1        # 增加指针
      vsetvli t1, a2, e8, m8, ta, ma   # 设置向量为字节（8位）的向量
      bnez a2, zero_loop    # 是否还有字节需要处理？

      ret
