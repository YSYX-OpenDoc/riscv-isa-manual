    .text
    .balign 4
    .global memcpy
    # void *memcpy(void* dest, const void* src, size_t n)
    # a0=dest, a1=src, a2=n
    #
  memcpy:
      mv a3, a0 # 复制目标地址
  loop:
    vsetvli t0, a2, e8, m8, ta, ma   # 设置向量长度（8 位元素）
    vle8.v v0, (a1)               # 读取源数据
      add a1, a1, t0              # 更新源地址指针
      sub a2, a2, t0              # 递减剩余字节数
    vse8.v v0, (a3)               # 存储数据到目标地址
      add a3, a3, t0              # 更新目标地址指针
      bnez a2, loop               # 若未完成，则继续循环
      ret                         # 返回
