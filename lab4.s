#---------------------------------------------------------------
# Assignment:           4
# Due Date:             March 18, 2022
# Name:                 Othman Sebti
# Unix ID:              osebti
# Lecture Section:      B1
# Instructor:           Karim Ali
# Lab Section:          (Tuesday, Thursday)
# Teaching Assistant:   Danil Tiganov
#---------------------------------------------------------------


#---------------------------------------------------------------




	.kdata
__m1_:	.asciiz "  Exception "
__m2_:	.asciiz " occurred and ignored\n"
__e0_:	.asciiz "  [Interrupt] "
__e1_:	.asciiz	"  [TLB]"
__e2_:	.asciiz	"  [TLB]"
__e3_:	.asciiz	"  [TLB]"
__e4_:	.asciiz	"  [Address error in inst/data fetch] "
__e5_:	.asciiz	"  [Address error in store] "
__e6_:	.asciiz	"  [Bad instruction address] "
__e7_:	.asciiz	"  [Bad data address] "
__e8_:	.asciiz	"  [Error in syscall] "
__e9_:	.asciiz	"  [Breakpoint] "
__e10_:	.asciiz	"  [Reserved instruction] "
__e11_:	.asciiz	""
__e12_:	.asciiz	"  [Arithmetic overflow] "
__e13_:	.asciiz	"  [Trap] "
__e14_:	.asciiz	""
__e15_:	.asciiz	"  [Floating point] "
__e16_:	.asciiz	""
__e17_:	.asciiz	""
__e18_:	.asciiz	"  [Coproc 2]"
__e19_:	.asciiz	""
__e20_:	.asciiz	""
__e21_:	.asciiz	""
__e22_:	.asciiz	"  [MDMX]"
__e23_:	.asciiz	"  [Watch]"
__e24_:	.asciiz	"  [Machine check]"
__e25_:	.asciiz	""
__e26_:	.asciiz	""
__e27_:	.asciiz	""
__e28_:	.asciiz	""
__e29_:	.asciiz	""
__e30_:	.asciiz	"  [Cache]"
__e31_:	.asciiz	""
__excp:	.word __e0_, __e1_, __e2_, __e3_, __e4_, __e5_, __e6_, __e7_, __e8_, __e9_
	.word __e10_, __e11_, __e12_, __e13_, __e14_, __e15_, __e16_, __e17_, __e18_,
	.word __e19_, __e20_, __e21_, __e22_, __e23_, __e24_, __e25_, __e26_, __e27_,
	.word __e28_, __e29_, __e30_, __e31_
	
	


s1:	.word 0
s2:	.word 0

# This is the exception handler code that the processor runs when
# an exception occurs. It only prints some information about the
# exception, but can serve as a model of how to write a handler.
#
# Because we are running in the kernel, we can use $k0/$k1 without
# saving their old values.

# This is the exception vector address for MIPS-1 (R2000):
#	.ktext 0x80000080


# This is the exception vector address for MIPS32:
	.ktext 0x80000180
# Select the appropriate one for the mode in which SPIM is compiled.


	.set noat
	move $k1 $at		# Save $at
	.set at
	
	
	sw $v0 s1		# Not re-entrant and we can't trust $sp
	sw $a0 s2		# But we need to use these registers

	mfc0 $k0 $13		# Cause register
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f
	bne $a0 0 Interrupt		# 0 means exception was an interrupt
	



# Interrupt-specific code goes here!
# Don't skip instruction at EPC since it has not executed.

Interrupt:


        beq $s5,1,ret
        

        lw $k0,0xffff0000 # check if interrupt happened because of keyboard press
        andi $k0,$k0,1
        beq $k0,1,KeyCode # if keyboard press happened and exception handler code is 0, check whether q was pressed
        #j KeyCode # otherwise interrupt happened because of the elapsed 1 second; go to time decrement block
         
         
        TimeCode:
        li $s4,2
        j ret
        
        KeyCode:
        li $s4,1
        j ret
        
        
        
        ret:


	lw $v0 s1		# Restore other registers
	lw $a0 s2

	.set noat
	move $at $k1		# Restore $at
	.set at

	mtc0 $0 $13		# Clear Cause register

	mfc0 $k0 $12		# Set Status register
	ori  $k0 0x1		# Interrupts enabled
	mtc0 $k0 $12

# Return from exception
	eret
	
        
     
 



.data 
	
Format1:	    .asciiz "00:00"
Intro:	    .asciiz "Seconds = "
DeleteKey:  .byte 0x7f
Q1:	    .byte 0x71
EnterKey:   .byte 0xd
KC:         .word 0xffff0000
KD:	     .word 0xffff0004
DC:         .word 0xffff0008
DD:         .word 0xffff000c
Format:	.ascii "00:00"
S_offset:  .byte '0' # used to convert integers to chars 
Seconds: .byte '0','0','0','0' # this stores the numbers entered by user (max 4 because max is 99m, 99s)
colon: .byte ':'
newline: .asciiz "\n"
Q: .byte 'q'


	
	
	
# Program Description: 
# The following program asks the user to input a number of seconds, which it displays 
# On the screen and then proceeds to also display it with an mm:ss format. Lastly, 
# The program initiates a countdown which ends the program once 00:00 has been reached
# or the user presses the key ´q´


#################################################################################################################
# Register Usage:
# $t0 - $t7 = Temporary Values for computations 
# $s3 = Seconds
# $s4 = Interrupt flag  
# $s5 = Intro Flag
##################################################################################################################

	
	
.text
.globl __start

__start:


main:	

li $s5,1 # set exception handler code to 1

	
StoreFormat:
la $s2, Format # store format address for interrupt handler
	

PrintIntroPrompt:
move $t0,$zero # Print the prompt using memory mapped IO and polling 
	
lw $t1,0xffff0008 # loading value in dislay control reg. to poll
lbu $t2,Intro($t0) # loading first character of prompt
	
Loop1:
beq $t2,0,SetKeyboard # checking for null terminator
	
Poll:
lw $t1,0xffff0008 # loading value in dislay control reg. to poll
andi $t3,$t1,1 # masking bits
beqz $t3,Poll
sb $t2,0xffff000c # storing character in display data reg. for it to be printed
addi $t0,$t0,1 # increment by 1 to get next character
lbu $t2,Intro($t0) # load the next character in t2
j Loop1
	
	
	
SetKeyboard:
#setting bit 1 to enable interrupts
lw $t0,0xffff0000
ori $t0,$t0,2
sw $t0,0xffff0000 # updating the value of KC 
sb $zero,0xffff0004 # clearing previous value saved in keyboard register
	
move  $t0, $zero
PollKeyboard:
lbu $t1,0xffff0000 # loading value in keyboard control reg. to poll
andi $t3,$t1,1 # masking bits to check if KC bit is set
beqz $t3,PollKeyboard
lbu $t2,0xffff0004 # loading the byte from the KD register 
beq $t2,10,EnableInterrupts # checking if enter has been pressed
	
sb $t2,0xffff000c # storing character in display data reg. for it to be printed
sb $t2,Seconds($t0) # store number in memory location
addi $t0,$t0,1 # add 1 to the counter 
j PollKeyboard

EnableInterrupts:


SetTimer:
li $s2,100  # time count 
mtc0 $s2,$11 # setting timer exception at 1 second (1000 ms = 1s)


mfc0 $t1,$12 # setting bits to 1,11,15 to 1  # immediate to set bits 0,11,15 of $12 (c0)
ori $t1,$t1,1024
ori $t1,$t1,16384
ori $t1,$t1,1
mtc0 $t1,$12 # setting bits to 1,11,15 to 1 



	

Begin:
        mfc0,$k0,$11
        mfc0,$k1,$9
        move $s3,$zero  # seconds = 0 
        
        
	
	
	
	
	PrintCountdown:
	li $t4,10 # t4 stores the multiplier for integer computation of seconds inputted
	# set secondary counter (to be used as multiplier)
	li $t1,-1
	
	
	
	
	
	SecLoop: # compute the number of seconds as an integer in this loop
	addi $t0,$t0,-1 # decrement counter to get index of last typed number by user
	addi $t1,$t1,1 # decrement counter to get index of last typed number by user
	move $s1,$zero # seconds in integer format will be stored in register $s0
	bltz $t0,PrintFormat1 # finish loop here, jump to seconds computation block 
	lbu $t2,Seconds($t0) # loading byte 
	sub $t2,$t2,48 # calculating difference and storing in $t2 (it is now an integer) 
	
	
	
	
	
	ComputeSeconds:
	lbu $t7, S_offset
	
	beq $t1,0,Mul0 # determining by what power of 10 to multiply each integer 
	beq $t1,1,Mul1
	beq $t1,2,Mul2
	beq $t1,3,Mul3
	
	Mul0:
	
	add $s3,$s3,$t2
	j SecLoop
	
	Mul1:
	
	mul $t2,$t4,$t2 # multiply by 10^1
	add $s3,$s3,$t2
	j SecLoop
	
	Mul2:
	
	mul $t2,$t4,$t2 # multiply by 10^2
	mul $t2,$t4,$t2 
	add $s3,$s3,$t2
	j SecLoop
	
	Mul3:
	
	mul $t2,$t4,$t2 # multiply by 10^3
	mul $t2,$t4,$t2 
	mul $t2,$t4,$t2 
	add $s3,$s3,$t2
	j SecLoop
	
	
	
	PrintFormat1:
	la $t6,newline
	lbu $t0,0($t6) # print newline
	sb $t0,0xffff000c
	
	lbu $t0,1($t6) # print newline
	sb $t0,0xffff000c
	
	
	PrintFormat:

	
	# t0 = number of minutes, # t1 = number of seconds (integer-format)
	div $t0,$s3,60 # divide by 60 to get num. minutes 
	mfhi $t1 # remainder = number of seconds, $t1 = num seconds
	
	# t2 = a where format = ab:cd (in ascii)
	# t3 = b where format = ab:cd (in ascii)
	
	div $t2,$t0,10 # divide by 10 
	mfhi $t3 # remainder = number of seconds, $t1 = num seconds
	add $t2,$t2,48
	add $t3,$t3,48
	
	# t4 = c where format = ab:cd (in ascii)
	# t5 = d where format = ab:cd (in ascii)
	
	div $t4,$t1,10 # divide by 10 
	add $t4,$t4,48
	mfhi $t5 # remainder = number of seconds, $t1 = num seconds
	add $t5,$t5,48
	
	
       p12:
	lw $k0,0xffff0008 # load byte data control reg.
	andi $k0,1
	beqz $k0,p12
	
	
	sb $t2,0xffff000c # print mm
	
	
p13:
	lw $k0,0xffff0008 # load byte data control reg.
	andi $k0,1
	beqz $k0,p13
	
	
	
	sb $t3,0xffff000c

	
	
p14:
	lw $k0,0xffff0008 # load byte data control reg.
	andi $k0,1
	beqz $k0,p14
	
	
	
	addi $t0,$zero,58 # loading colon character to print it on display	
	sb $t0,0xffff000c
	
	
	
	p15:
	lw $k0,0xffff0008 # load byte data control reg.
	andi $k0,1
	beqz $k0,p15
	

	
	sb $t4,0xffff000c # print ss
	
	
	p16:
	lw $k0,0xffff0008 # load byte data control reg.
	andi $k0,1
	beqz $k0,p16
	
	sb $t5,0xffff000c
	
	beqz $s3,Terminate # if seconds = 00:00 return and exit 
	move $s5,$zero
	li $s5,0
	
	mtc0 $zero,$9 # reset time counter register 
	
	
	
	mfc0 $t1,$12 # setting bits to 1,11,15 to 1  # immediate to set bits 0,11,15 of $12 (c0)
	ori $t1,$t1,1024
	ori $t1,$t1,16384
	ori $t1,$t1,1
	mtc0 $t1,$12 # setting bits to 1,11,15 to 1 

	j wait2
	
	
	
	PollDisplay:
	lw $k0,0xffff0008 # load byte data control reg.
	andi $k0,1
	beqz $k0,PollDisplay
	jr $ra # return to print char since display data reg. is now accepting input
	
	
	
	
	PollQ:
	lbu $k0,0xffff0004 # load the character pressed by user 
	lbu $k1,Q # load q ascii code in reg k1
	beq $k0,$k1,Terminate # quit application since q has been pressed
	move $s4,$zero
	j wait2
	 
	

	
	DecrementTime:
	addi $s3,$s3,-1
	li $t1,0x08 
	sb $t1,0xffff000c # move back the cursor by 5 spaces
	
	p1:
	lw $k0,0xffff0008 # load byte data control reg.
	andi $k0,1
	beqz $k0,p1
	
	sb $t1,0xffff000c
	
	p2:
	lw $k0,0xffff0008 # load byte data control reg.
	andi $k0,1
	beqz $k0,p2
	
	sb $t1,0xffff000c
	
	p3:
	lw $k0,0xffff0008 # load byte data control reg.
	andi $k0,1
	beqz $k0,p3
	
	sb $t1,0xffff000c
	
	p4:
	lw $k0,0xffff0008 # load byte data control reg.
	andi $k0,1
	beqz $k0,p4
	 
	sb $t1,0xffff000c
	
	
	j PrintFormat
	
	
	
TimeUpdate:
	
        mfc0 $t0,$12 # disabling interrupts during time update
        andi $t0,$t0,0xf0
        
	move $s4,$zero
	j DecrementTime 
	




wait2:

blez $s4,wait2 # waiting for resumption code
beq $s4,1,PollQ # key has been pressed, check it 
beq $s4,2,TimeUpdate
beqz $s3,Terminate # exit code 0 means that countdown has finished


	
Terminate:
li $v0,10 # End Program
syscall
	
	
	
.globl __eoth

__eoth:
	
	
		
