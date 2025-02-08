    .text
    .balign 4
    .global sgemm_nn
# RV64IDV 系统
#
# void
# sgemm_nn(size_t n,
#          size_t m,
#          size_t k,
#          const float*a,   // m * k 矩阵
#          size_t lda,
#          const float*b,   // k * n 矩阵
#          size_t ldb,
#          float*c,         // m * n 矩阵
#          size_t ldc)
#
#  计算 C += A * B（α=1，输入矩阵不进行转置）
#  矩阵存储采用 C 语言的行优先（row-major）顺序

#define n a0
#define m a1
#define k a2
#define ap a3
#define astride a4
#define bp a5
#define bstride a6
#define cp a7
#define cstride t0
#define kt t1
#define nt t2
#define bnp t3
#define cnp t4
#define akp t5
#define bkp s0
#define nvl s1
#define ccp s2
#define amp s3

# 使用参数作为额外的临时变量
#define ft12 fa0
#define ft13 fa1
#define ft14 fa2
#define ft15 fa3

# 该版本在内部循环中使用 16*VLMAX 大小的 C 子矩阵块存储到向量寄存器，
# 但除此之外不进行缓存或 TLB 切片优化。

sgemm_nn:
    addi sp, sp, -FRAMESIZE
    sd s0, OFFSET(sp)
    sd s1, OFFSET(sp)
    sd s2, OFFSET(sp)

    # 检查矩阵尺寸是否为零        
    beqz n, exit
    beqz m, exit
    beqz k, exit

    # 将元素步长转换为字节步长
    ld cstride, OFFSET(sp)   # 从栈帧获取参数
    slli astride, astride, 2
    slli bstride, bstride, 2
    slli cstride, cstride, 2

    slti t6, m, 16
    bnez t6, end_rows

c_row_loop: # 遍历 C 块的行

    mv nt, n  # 初始化 C 块行的列计数器

    mv bnp, bp # 初始化 B 矩阵列指针
    mv cnp, cp # 初始化 C 矩阵列指针

c_col_loop: # 遍历 C 块的列
    vsetvli nvl, nt, e32, ta, ma  # 设置 32 位向量，LMUL=1

    mv akp, ap   # 重置 A 指针到起始位置
    mv bkp, bnp  # 指向 B 矩阵的当前列

    # 从内存初始化当前 C 子矩阵块
    vle32.v  v0, (cnp); add ccp, cnp, cstride;
    vle32.v  v1, (ccp); add ccp, ccp, cstride;
    vle32.v  v2, (ccp); add ccp, ccp, cstride;
    vle32.v  v3, (ccp); add ccp, ccp, cstride;
    vle32.v  v4, (ccp); add ccp, ccp, cstride;
    vle32.v  v5, (ccp); add ccp, ccp, cstride;
    vle32.v  v6, (ccp); add ccp, ccp, cstride;
    vle32.v  v7, (ccp); add ccp, ccp, cstride;
    vle32.v  v8, (ccp); add ccp, ccp, cstride;
    vle32.v  v9, (ccp); add ccp, ccp, cstride;
    vle32.v v10, (ccp); add ccp, ccp, cstride;
    vle32.v v11, (ccp); add ccp, ccp, cstride;
    vle32.v v12, (ccp); add ccp, ccp, cstride;
    vle32.v v13, (ccp); add ccp, ccp, cstride;
    vle32.v v14, (ccp); add ccp, ccp, cstride;
    vle32.v v15, (ccp)


    mv kt, k # 初始化内层循环计数器

    # 内循环调度假设 vfmacc 指令有 4 个时钟周期的占用，并且采用单发射流水线
    # 预取数据
    flw ft0, (akp); add amp, akp, astride;
    flw ft1, (amp); add amp, amp, astride;
    flw ft2, (amp); add amp, amp, astride;
    flw ft3, (amp); add amp, amp, astride;
    # 读取 B 矩阵的向量数据
    vle32.v v16, (bkp)

    # 当前 C 块的内循环
k_loop:
    vfmacc.vf v0, ft0, v16
    add bkp, bkp, bstride
    flw ft4, (amp)
    add amp, amp, astride
    vfmacc.vf v1, ft1, v16
    addi kt, kt, -1    # 递减 k 计数器
    flw ft5, (amp)
    add amp, amp, astride
    vfmacc.vf v2, ft2, v16
    flw ft6, (amp)
    add amp, amp, astride
    flw ft7, (amp)
    vfmacc.vf v3, ft3, v16
    add amp, amp, astride
    flw ft8, (amp)
    add amp, amp, astride
    vfmacc.vf v4, ft4, v16
    flw ft9, (amp)
    add amp, amp, astride
    vfmacc.vf v5, ft5, v16
    flw ft10, (amp)
    add amp, amp, astride
    vfmacc.vf v6, ft6, v16
    flw ft11, (amp)
    add amp, amp, astride
    vfmacc.vf v7, ft7, v16
    flw ft12, (amp)
    add amp, amp, astride
    vfmacc.vf v8, ft8, v16
    flw ft13, (amp)
    add amp, amp, astride
    vfmacc.vf v9, ft9, v16
    flw ft14, (amp)
    add amp, amp, astride
    vfmacc.vf v10, ft10, v16
    flw ft15, (amp)
    add amp, amp, astride
    addi akp, akp, 4            # 移动到 A 的下一列
    vfmacc.vf v11, ft11, v16
    beqz kt, 1f                 # 无需加载超出矩阵范围的数据
    flw ft0, (akp)
    add amp, akp, astride
1:  vfmacc.vf v12, ft12, v16
    beqz kt, 1f
    flw ft1, (amp)
    add amp, amp, astride
1:  vfmacc.vf v13, ft13, v16
    beqz kt, 1f
    flw ft2, (amp)
    add amp, amp, astride
1:  vfmacc.vf v14, ft14, v16
    beqz kt, 1f                 # 退出循环
    flw ft3, (amp)
    add amp, amp, astride
    vfmacc.vf v15, ft15, v16
    vle32.v v16, (bkp)            # 预取 B 矩阵的下一个向量
    j k_loop

1:  vfmacc.vf v15, ft15, v16
    
    # 将 C 矩阵块写回内存
    vse32.v  v0, (cnp); add ccp, cnp, cstride;
    vse32.v  v1, (ccp); add ccp, ccp, cstride;
    vse32.v  v2, (ccp); add ccp, ccp, cstride;
    vse32.v  v3, (ccp); add ccp, ccp, cstride;
    vse32.v  v4, (ccp); add ccp, ccp, cstride;
    vse32.v  v5, (ccp); add ccp, ccp, cstride;
    vse32.v  v6, (ccp); add ccp, ccp, cstride;
    vse32.v  v7, (ccp); add ccp, ccp, cstride;
    vse32.v  v8, (ccp); add ccp, ccp, cstride;
    vse32.v  v9, (ccp); add ccp, ccp, cstride;
    vse32.v v10, (ccp); add ccp, ccp, cstride;
    vse32.v v11, (ccp); add ccp, ccp, cstride;
    vse32.v v12, (ccp); add ccp, ccp, cstride;
    vse32.v v13, (ccp); add ccp, ccp, cstride;
    vse32.v v14, (ccp); add ccp, ccp, cstride;
    vse32.v v15, (ccp)

    # 以下的尾部指令应该在 C 块保存期间，在空闲槽位中尽早调度。
    # 留在这里是为了清晰起见。

    # 增量指针以遍历 C 矩阵的块
    slli t6, nvl, 2
    add cnp, cnp, t6  # 移动 C 块指针
    add bnp, bnp, t6  # 移动 B 块指针
    sub nt, nt, nvl   # 递减 n 方向的元素计数
    bnez nt, c_col_loop # 是否还有剩余列？

    # 移动到下一组行
    addi m, m, -16  # 处理 16 行
    slli t6, astride, 4  # astride 乘 16
    add ap, ap, t6  # A 矩阵指针向下移动 16 行
    slli t6, cstride, 4  # cstride 乘 16
    add cp, cp, t6  # C 矩阵指针向下移动 16 行
    
    slti t6, m, 16
    beqz t6, c_row_loop

    # 处理剩余不足 16 行的情况（可以使用较小的版本）
end_rows:
    # 尚未完成

exit:
    ld s0, OFFSET(sp)
    ld s1, OFFSET(sp)
    ld s2, OFFSET(sp)
    addi sp, sp, FRAMESIZE
    ret
