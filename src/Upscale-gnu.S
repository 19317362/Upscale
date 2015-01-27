
entry:
.syntax unified
	.arch armv7-a
	.eabi_attribute 27, 3
	.eabi_attribute 28, 1
	.fpu neon
	.eabi_attribute 20, 1
	.eabi_attribute 21, 1
	.eabi_attribute 23, 3
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 2
	.eabi_attribute 30, 6
	.eabi_attribute 34, 1
	.eabi_attribute 18, 4
	.globl upscale
	.arm
	.align	4
	.type	upscale, %function
upscale:


inp_image		.req r0
out_image	 	.req r1
inp_width	 	.req r2
inp_height      .req r3
out_width	 	.req r4		@	offset + 1*4
out_height 	  	.req r5		@ 	offset + 2*4
row1_image      .req r6
row2_image      .req r7
row3_image      .req r8
row4_image      .req r9
row_outimage    .req r14
rem_height      .req r11
rem_width       .req r12
.equ offset          ,  10*4

@ args -	inp_image,out_image,inp_width,inp_height
@			out_width,out_height

start:

	stmfd			sp!,						{r4-r12,lr}				@ backing up all registers

	ldr				out_width,					[sp,#(offset + 1*4)]
    ldr				out_height,					[sp,#(offset + 2*4)]

	@Input kernel is 4x4
    lsr             rem_height,                 inp_height,#2
    mov             rem_height,                 inp_height


outer_loop:
	@ Input kernel is 4x4
    lsr             rem_width,                  inp_width,#2
    mov             rem_width,                  inp_width

inner_loop:

  mov				row1_image,					inp_image
  add				row2_image,					row1_image,inp_width
  add				row3_image,					row2_image,inp_width
  add				row4_image,					row3_image,inp_width
  mov             row_outimage,              out_image

@ # load 0 1 1 3
 mov             r10,                        #1
 lsl             r10,                        #8
 add             r10,                        #1
 lsl             r10,                        #8
 add             r10,                        #3
 vdup.32         d7,                         r10

 # load 0 3 1 1
 mov             r10,                        #3
 lsl             r10,                        #8
 add             r10,                        #1
 lsl             r10,                        #8
 add             r10,                        #1
 vdup.32         d8,                         r10

  # load 0 1 1 1
  mov             r10,                        #1
  lsl             r10,                        #8
  add             r10,                        #1
  lsl             r10,                        #8
  add             r10,                        #1
  vmov.i32		  d9,						  #0
  vmov.u32         d9[0],                      r10

@ # load 0 2 1 2
 mov             r10,                        #2
 lsl             r10,                        #8
 add             r10,                        #1
 lsl             r10,                        #8
 add             r10,                        #2
 vdup.32         d12,                         r10
 vdup.32         d13,                         r10


  vld1.u8         d1,                         [row1_image]
  vld1.u8         d2,                         [row2_image]
  vld1.u8         d3,                         [row3_image]
  vld1.u8         d4,                         [row4_image]


  # 1     2       3    4
  # 3     1       1    0
  # 2     3       4    0
  # 1     1       3    0

  #for first row
vshr.u64			d10,						d1,#8
vmull.u8        q12,                        d1,d8
vmull.u8        q13,                        d10,d7

vadd.u16        q12,                        q12,q13
vshl.u16		  q12,						q12,q6
vmovn.u16       d10,                        q12

  vmull.u8        q12,                        d1,d9
  vmovn.u16       d1,                         q12
  vmov.u8		  d22,						  d1
  #0       0     2       0
  #0.66   1.33    2.66    3.33
  #0      0.66    1.33   2   2.66    3.33   0     0
  vzip.8          d1,                         d22

  #for second row
vshr.u64			d10,						d2,#8
vmull.u8        q12,                        d2,d8
vmull.u8        q13,                        d10,d7

vadd.u16        q12,                        q12,q13
vshl.u16		q12,						q12,q6
vmovn.u16       d10,                         q12

  vmull.u8        q12,                        d2,d9
  vmovn.u16       d2,                         q12
  vmov.u8		  d22,						  d2

  #0       0     2       0
  #0.66   1.33    2.66    3.33
  #0      0.66    1.33   2   2.66    3.33   0     0
  vzip.8          d2,                         d22


  #for third row
 vshr.u64			d10,						d3,#8
 vmull.u8        q12,                        d3,d8
 vmull.u8        q13,                        d10,d7

 vadd.u16        q12,                        q12,q13
 vshl.u16		q12,						q12,q6
 vmovn.u16       d10,                         q12

  vmull.u8        q12,                        d3,d9
  vmovn.u16       d3,                         q12
  vmov.u8		  d22,						  d3

  #0       0     2       0
  #0.66   1.33    2.66    3.33
  #0      0.66    1.33   2   2.66    3.33   0     0
  vzip.8          d3,                         d22

  #for fourth row
 vshr.u64			d10,						d4,#8
 vmull.u8        q12,                        d4,d8
 vmull.u8        q13,                        d10,d7

 vadd.u16        q12,                        q12,q13
 vshl.u16		q12,						q12,q6
 vmovn.u16       d10,                         q12

 vmull.u8        q12,                        d4,d9
 vmovn.u16       d4,                         q12
 vmov.u8		  d22,						  d4

@ #0       0     2       0
@ #0.66   1.33    2.66    3.33
@ #0      0.66    1.33   2   2.66    3.33   0     0
 vzip.8          d4,                         d22


 #vertical upscaling
 #0.66
 vmovl.u8		q10,						 d1
 vmovl.u8		q14,						 d2
 vmovl.u8		q11,						 d7
 vmov.u16		d0,							d22
 vmull.u16        q12,                       d20,d0[1]
 vmull.u16        q13,                       d21,d0[1]
 vmlal.u16        q12,                       d28,d0[0]
 vmlal.u16       q13,                        d29,d0[0]
 vshl.u32		q12,						q12,#2
 vmovn.u32		d24,						q12
 vshl.u32		q13,						q13,#2
 vmovn.u32		d25,						q13
 vmovn.u16       d30,                        q12

@
@ #1.33
 vmull.u16        q12,                       d20,d0[1]
 vmull.u16        q13,                       d21,d0[1]
 vmlal.u16        q12,                       d28,d0[1]
 vmlal.u16       q13,                        d29,d0[1]
 vshl.u32		q12,						q12,#1
 vmovn.u32		d24,						q12
 vshl.u32		q13,						q13,#1
 vmovn.u32		d25,						q13
 vmovn.u16       d31,                        q12

@ #2.66
 vmull.u16        q12,                       d20,d0[1]
 vmull.u16        q13,                       d21,d0[1]
 vmlal.u16        q12,                       d28,d0[1]
 vmlal.u16       q13,                        d29,d0[1]
 vshl.u32		q12,						q12,#2
 vmovn.u32		d24,						q12
 vshl.u32		q13,						q13,#2
 vmovn.u32		d25,						q13
 vmovn.u16       d29,                        q12

@ #3.33
 vmull.u16        q12,                       d20,d0[0]
 vmull.u16        q13,                       d21,d0[1]
 vmlal.u16        q12,                       d28,d0[0]
 vmlal.u16       q13,                        d29,d0[1]
 vshl.u32		q12,						q12,#2
 vmovn.u32		d24,						q12
 vshl.u32		q13,						q13,#2
 vmovn.u32		d25,						q13
 vmovn.u16       d29,                        q12

  # final 6x6 - d1,d30,d2,d31,d3,d29

  vst1.u8         d1,                         [row_outimage]
  add             row_outimage,                out_width
  vst1.u8         d1,                        [row_outimage]
  add             row_outimage,                out_width
  vst1.u8         d2,                        [row_outimage]
  add             row_outimage,                out_width
  vst1.u8         d2,                        [row_outimage]
  add             row_outimage,                out_width
  vst1.u8         d3,                        [row_outimage]
  add             row_outimage,                out_width
  vst1.u8         d3,                        [row_outimage]
  add             row_outimage,                out_width

  add             out_image,                   out_image,#6
  add             inp_image,                   inp_image,#4

  subs			    rem_width,                   #4
	bgt				inner_loop

  @add				out_image,					out_image,out_width,lsl#2
  add				out_image,					out_width
    add				out_image,					out_width
    add				out_image,					out_width
    add				out_image,					out_width
    add				out_image,					out_width


  @add             inp_image,                  inp_image,inp_width,lsl#1
  add				inp_image,					inp_width
  add				inp_image,					inp_width
  add				inp_image,					inp_width


  subs			rem_height,					#4
  bgt             outer_loop


    ldmfd	sp!,			{r4-r12,lr}
	mov		pc,				lr
func_end:
	















@TODO: Variable shifts problem
@TODO: 16-bit multiplication problem


@	.section	.note.gnu-stack,"",%progbits
