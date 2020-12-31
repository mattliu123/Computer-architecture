.data
	str1: .asciiz "The highest score is: "
	str2: .asciiz "Traceback result:\n"
	nextline: .asciiz "\n"
	
#####################################################

# This part may change on different testing data

	seq1: .asciiz "ACACACTA"
	seq2: .asciiz "AGCACACA"
	score: .word 0:81
	dir: .word 0:81


.text
	main:	
		li $s0, 8		#seq 1 length
		li $s1, 8		#seq 2 length
		
#####################################################	
	#seq1: .asciiz "CAAGAATGTCACAGGTCCAT"
	#seq2: .asciiz "CAGCATCACACTTA"
	#score: .word 0:315	#(len1 + 1) * (len2 + 1)
	#dir: .word 0:315


#.text
	#main:	
		#li $s0, 20		#seq 1 length
		#li $s1, 14		#seq 2 length	
		
# Todo
		la $s5, score
		la $a1, dir
		la $a2, seq1
		la $a3, seq2
		li $s2, 0		#max
		li $s3, 0		#i
		li $s4, 0		#j
	
	addi $sp, $sp, -24
	sw $s5, 20($sp)
	sw $s4, 16($sp)
	sw $s3, 12($sp)
	sw $s2, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)
	for1:
		slt $t0, $s3, $s1
		beq $t0, $zero, exit1
		add $s4, $zero, $zero
	for2:
		slt $t0, $s4, $s0
		beq $t0, $zero, exit2
		move $t0, $s3
		add $t0, $a3, $t0
		move $t1, $s4
		add $t1, $a2, $t1
		lb $t0, 0($t0)		#a3[i]
		lb $t1, 0($t1)		#a2[j]
		bne $t0, $t1, max	#if a2[i]==a2[j]
		addi $t0, $s0, 1	#t0 = 9
		mul $t1, $s3, $t0	#i*9
		add $t2, $t1, $s4	#j+i*9
		addi $t9, $s0, 2
		add $t3, $t2, $t9	#j+i*9+10
		sll $t3, $t3, 2
		add $t4, $t3, $s5	#a0[j+i*9+10]
		sll $t2, $t2, 2
		add $t2, $t2, $s5 	#a0[j+i*9]
		lw $t0, 0($t2)
		addi $t0, $t0, 3
		sw $t0, 0($t4)		#a0[j+i*9+10]=a0[j+i*9]+3
		add $t0, $a1, $t3
		addi $t1, $zero, 3
		sw $t1, 0($t0)
		j max2
		max:
		addi $t0, $s0, 1	#9
		mul $t0, $t0, $s3	#i*9
		add $t0, $t0, $s4	#j+i*9
		sll $t2, $t0, 2
		add $t1, $s5, $t2 	#&a0[j+i*9]
		lw $t1, 0($t1)		#a0[j+i*9]
		addi $t1, $t1, -1	#a0[j+i*9]-1
		addi $t2, $t0, 1
		sll $t2, $t2, 2
		add $t2, $t2, $s5	#&a0[j+i*9+1]
		lw $t2, 0($t2)		#a0[j+i*9+1]
		addi $t2, $t2, -2	#a0[j+i*9+1]-2
		addi $t9, $s0, 1
		add $t3, $t0, $t9
		sll $t3, $t3, 2
		add $t3, $s5, $t3
		lw $t3, 0($t3)		#a0[j+i*9+9]
		addi $t3, $t3, -2	#a0[j+i*9+9]-2
		slt $t4, $t1, $zero
		beq $t4, $zero, el0
		slt $t4, $t2, $zero
		beq $t4, $zero, el0
		slt $t4, $t3, $zero
		beq $t4, $zero, el0
		addi $t9, $s0, 2
		add $t4, $t0, $t9
		sll $t4, $t4, 2
		add $t5, $t4, $s5
		sw $zero, 0($t5)
		j max2
		el0:
		slt $t4, $t1, $t2
		bne $t4, $zero, el1
		slt $t4, $t1, $t3
		bne $t4, $zero, el1
		addi $t9, $s0, 2	#10
		add $t4, $t0, $t9	
		sll $t4, $t4, 2
		add $t5, $t4, $s5
		sw $t1, 0($t5)
		add $t5, $t4, $a1
		addi $t6, $zero, 3
		sw $t6, 0($t5)
		j max2
		el1:
		slt $t4, $t2, $t1
		bne $t4, $zero, el2
		slt $t4, $t2, $t3
		bne $t4, $zero, el2
		addi $t9, $s0, 2
		add $t4, $t0, $t9
		sll $t4, $t4, 2
		add $t5, $t4, $s5
		sw $t2, 0($t5)
		add $t5, $t4, $a1
		addi $t6, $zero, 2
		sw $t6, 0($t5)
		j max2
		el2:
		addi $t9, $s0, 2
		add $t4, $t0, $t9
		sll $t4, $t4, 2
		add $t5, $t4, $s5
		sw $t3, 0($t5)
		add $t5, $t4, $a1
		addi $t6, $zero, 1
		sw $t6, 0($t5)
		max2:
		add $t4, $zero, $s2
		sll $t4, $t4, 2
		add $t4, $t4, $s5
		lw $t4, 0($t4)		#score[max]
		addi $t5, $s0, 2	#10
		addi $t0, $s0, 1
		mul $t0, $t0, $s3
		add $t0, $t0, $s4	#j+i*9
		add $t5, $t5, $t0
		sll $t7, $t5, 2
		add $t7, $t7, $s5
		lw $t7, 0($t7)		#score[j+i*9+10]
		slt $t6, $t7, $t4
		bne $t6, $zero, max3
		move $s2, $t5
		max3:
		addi $s4, $s4, 1
		j for2
		exit2:
		addi $s3, $s3, 1
		j for1
		exit1:
		la $a0, str1
		li $v0, 4
		syscall
		sll $t0, $s2, 2
		add $t0, $s5, $t0
		lw $t0, 0($t0)
		move $a0, $t0
		li $v0, 1
		syscall
		la $a0, nextline
		li $v0, 4
		syscall
		la $a0, nextline
		li $v0, 4
		syscall
		la $a0, str2
		syscall
		trace:
		sll $t0, $s2, 2
		add $t4, $s5, $t0
		lw $t4, 0($t4)
		beq $t4, $zero, finish
		li $t3, 3
		li $t2, 2
		li $t1, 1
		add $t5, $t0, $a1
		lw $t5, 0($t5)
		bne $t5, $t3, els1
		move $a0, $t3
		li $v0, 1
		syscall
		addi $t6, $s0, 2
		sub $s2, $s2, $t6
		j trace
		els1:
		bne $t5, $t2, els2
		move $a0, $t2
		li $v0, 1
		syscall
		addi $t6, $s0, 1
		sub $s2, $s2, $t6
		j trace
		els2:
		move $a0, $t1
		li $v0, 1
		syscall
		addi $t6, $zero, -1
		add $s2, $s2, $t6
		j trace
		finish: 


	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)


		li $v0, 10
		syscall

