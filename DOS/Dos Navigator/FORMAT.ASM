	TITLE	FORMAT

	LOCALS	@@

FORMAT_TEXT	SEGMENT	BYTE PUBLIC 'CODE'

	ASSUME	CS:FORMAT_TEXT,DS:NOTHING

	PUBLIC	Format_Str

; function FormatStr(var Result: String; Format: String; var Params)

Format_Str:

Result		EQU	(DWORD PTR [BP+14])
Format		EQU	(DWORD PTR [BP+10])
Params		EQU	(DWORD PTR [BP+6])
ParOfs		EQU	(WORD PTR [BP-2])
Buffer		EQU	(BYTE PTR [BP-14])

	PUSH	BP
	MOV	BP,SP
	PUSH	WORD PTR Params
	SUB	SP,12
	PUSH	DS
	LDS	SI,Format
	LES	DI,Result
	INC	DI
	CLD
	LODSB
	XOR	AH,AH
	XCHG	AX,CX
@@1:	JCXZ	@@9
	LODSB
	DEC	CX
	CMP	AL,'%'
	JE	@@3
@@2:	STOSB
	JMP	@@1
@@3:	JCXZ	@@9
	LODSB
	DEC	CX
	CMP	AL,'%'
	JE	@@2
	MOV	BX,' '
	XOR	DX,DX
	CMP	AL,'0'
	JNE	@@4
	MOV	BL,AL
@@4:	CMP	AL,'-'
	JNE	@@5
	INC	BH
	JCXZ	@@9
	LODSB
	DEC	CX
@@5:	CMP	AL,'0'
	JB	@@6
	CMP	AL,'9'
	JA	@@6
	SUB	AL,'0'
	XCHG	AX,DX
	MOV	AH,10
	MUL	AH
	ADD	AL,DL
	XCHG	AX,DX
	JCXZ	@@9
	LODSB
	DEC	CX
	JMP	@@5
@@6:	CMP	AL,'#'
	JNE	@@10
	SHL	DX,1
	SHL	DX,1
	ADD	DX,ParOfs
	MOV	WORD PTR Params,DX
	JMP	@@1
@@9:	XCHG	AX,DI
	LES	DI,Result
	SUB	AX,DI
	DEC	AX
	STOSB
	POP	DS
	MOV	SP,BP
	POP	BP
	RETF	12
@@10:	PUSH	DS
	PUSH	SI
	PUSH	CX
	PUSH	DX
	PUSH	BX
	CALL	Convert
	POP	BX
	POP	DX
	OR	DX,DX
	JE	@@12
	SUB	DX,CX
	JAE	@@12
	OR	BH,BH
	JNE	@@11
	SUB	SI,DX
@@11:	ADD	CX,DX
	XOR	DX,DX
@@12:	OR	BH,BH
	JE	@@13
	REP	MOVSB
@@13:	XCHG	CX,DX
	MOV	AL,BL
	REP	STOSB
	XCHG	CX,DX
	REP	MOVSB
	POP	CX
	POP	SI
	POP	DS
	JMP	@@1

; Convert next parameter to string
; In	AL    = Conversion character
; Out	DS:SI = Pointer to string
;	CX    = String length

Convert:

	XCHG	AX,DX
	LDS	SI,Params
	LODSW
	XCHG	AX,BX
	LODSW
	XCHG	AX,BX
	MOV	WORD PTR Params,SI
	XOR	CX,CX
	LEA	SI,Buffer[12]
	PUSH	SS
	POP	DS
	AND	DL,0DFH
	CMP	DL,'C'
	JE	ConvertChar
	CMP	DL,'S'
	JE	ConvertStr
	CMP	DL,'D'
	JE	ConvertDec
	CMP	DL,'X'
	JE	ConvertHex
	RET

ConvertStr:

	MOV	DX,AX
	OR	DX,BX
	JE	@@1
	MOV	SI,AX
	MOV	DS,BX
	LODSB
	MOV	CL,AL
@@1:	RET

ConvertHex:

	MOV	CL,16
	JMP	SHORT ConvertNum

ConvertDec:

	MOV	CL,10
	OR	BX,BX
	JNS	ConvertNum
	NEG	BX
	NEG	AX
	SBB	BX,0
	CALL	ConvertNum
	MOV	AL,'-'

ConvertChar:

	INC	CX
	DEC	SI
	MOV	[SI],AL
	RET

ConvertNum:

	PUSH	SI
@@1:	XOR	DX,DX
	XCHG	AX,BX
	DIV	CX
	XCHG	AX,BX
	DIV	CX
	ADD	DL,'0'
	CMP	DL,'0'+10
	JB	@@2
	ADD	DL,'A'-'0'-10
@@2:	DEC	SI
	MOV	[SI],DL
	MOV	DX,AX
	OR	DX,BX
	JNE	@@1
	POP	CX
	SUB	CX,SI
	RET

FORMAT_TEXT	ENDS

	END
