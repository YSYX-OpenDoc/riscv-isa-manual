    .text
    .balign 4
    .global strcpy
  # char* strcpy(char *dst, const char* src)
strcpy:
      mv a2, a0             # 复制目标地址(dst)
      li t0, -1             # 设置无限AVL（最大向量长度）
loop:
    vsetvli x0, t0, e8, m8, ta, ma  # 设置最大长度的字节向量
    vle8ff.v v8, (a1)        # 从源地址加载字节(src)
      csrr t1, vl           # 获取已加载字节的数量
    vmseq.vi v1, v8, 0      # 标记零字节
    vfirst.m a3, v1         # 是否找到零字节？
      add a1, a1, t1        # 增加源指针
    vmsif.m v0, v1          # 设置掩码，包括零字节
    vse8.v v8, (a2), v0.t    # 将字节写入目标地址(dst)
      add a2, a2, t1        # 增加目标指针
      bltz a3, loop         # 如果没有找到零字节，继续循环

      ret
