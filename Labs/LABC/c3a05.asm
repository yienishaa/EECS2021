str1:	DC	"samples text\0"
	addi	x6, x0, str1
	ecall	x0, x6,	4
	ebreak	x0, x0, 0