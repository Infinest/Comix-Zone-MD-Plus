; Constants: ---------------------------------------------------------------------------------
	MD_PLUS_OVERLAY_PORT:	equ $0003F7FA
	MD_PLUS_CMD_PORT:		equ $0003F7FE
	REGISTER_BACKUP:		equ $FFFFFF80

; Overrides: ---------------------------------------------------------------------------------
	org $2608
	jmp PLAY_DETOUR
	nop
	nop
RETURN_FROM_PLAY_DETOUR

	org $261A
	jmp STOP_DETOUR
	nop
	nop
RETURN_FROM_STOP_DETOUR

	org $1E4944
	jmp PAUSE_DETOUR
	nop
	nop
RETURN_FROM_PAUSE_DETOUR

	org $1E499C
	jmp RESUME_DETOUR
	nop
	nop
RETURN_FROM_RESUME_DETOUR

; Detours: ------------------------------------------------------------------------------------
	org $1FD200
PAUSE_DETOUR
	movem	D1,(REGISTER_BACKUP)
	move.w	#$1300,D1
	jsr		WRITE_MD_PLUS_FUNCTION
	movem	(REGISTER_BACKUP),D1
	st		$FFFFBFD6						; Original game code
	jsr		$0001CB632
	jmp		RETURN_FROM_PAUSE_DETOUR

RESUME_DETOUR
	movem	D1,(REGISTER_BACKUP)
	move.w	#$1400,D1
	jsr		WRITE_MD_PLUS_FUNCTION
	movem	(REGISTER_BACKUP),D1
	sf		$FFFFBFD6						; Original game code
	jsr		$0001CB632
	jmp		RETURN_FROM_RESUME_DETOUR

STOP_DETOUR
	cmpi.l	#$FFFFFFFF,D0
	bne		DONT_STOP_MUSIC
	movem	D1,(REGISTER_BACKUP)
	move.w	#$1300,D1
	bsr		WRITE_MD_PLUS_FUNCTION
	movem	(REGISTER_BACKUP),D1
DONT_STOP_MUSIC
	movem.l D0/A0,-(A7)						; Original game code
	jsr		$0001CB622
	jmp		RETURN_FROM_STOP_DETOUR

PLAY_DETOUR
	cmpi.b	#$22,D0
	bhi		NOT_MUSIC						; Branch if higher than $22
	movem	D1-D2,(REGISTER_BACKUP)
	move.w	#$1200,D1
	move.b	D0,D1
	addi.b	#$1,D1
	move.b	#$0,D2
	cmpi.b	#$D,D0							; Beginning from #$D, there is a set of 3 empty track ids
	bcs		DO_NOT_DECREMENT_FURTHER
	addi.b	#$3,D2

	cmpi.b	#$13,D0
	bcs		DO_NOT_DECREMENT_FURTHER		; On #$13, there is one empty track id
	addi.b	#$1,D2

	cmpi.b	#$15,D0
	bcs		DO_NOT_DECREMENT_FURTHER		; On #$15, there is one empty track id
	addi.b	#$1,D2

	cmpi.b	#$19,D0
	bcs		DO_NOT_DECREMENT_FURTHER		; On #$19, there is one empty track id
	addi.b	#$1,D2

	cmpi	#$1D,D0
	bcs		DO_NOT_DECREMENT_FURTHER		; Beginning from #$1D, there is a set of 3 empty track ids
	addi.b	#$3,D2

DO_NOT_DECREMENT_FURTHER
	sub.b	D2,D1							; Subtract D2 from D1 to get rid of holes in the track index sequence
	bsr		WRITE_MD_PLUS_FUNCTION
	movem	(REGISTER_BACKUP),D1-D2
	rts
NOT_MUSIC
	movem.l D0/A0/A6,-(A7)					; Original game code
	jsr $0001CB60C
	jmp RETURN_FROM_PLAY_DETOUR

WRITE_MD_PLUS_FUNCTION:
	move.w  #$CD54,(MD_PLUS_OVERLAY_PORT)	; Open interface
	move.w  D1,(MD_PLUS_CMD_PORT)			; Send command to interface
	move.w  #$0000,(MD_PLUS_OVERLAY_PORT)	; Close interface
	rts