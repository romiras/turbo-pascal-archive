Function IsbitOn   (n: word; b : BYTE): BOOLEAN;
BEGIN isBitOn:=((n SHR b) AND 1) = 1 END;

Procedure SetBitOn (VAR n: Word; b: BYTE);
BEGIN N:= N OR (1 SHL b) END;

Procedure XORBit   (VAR n: Word; b: BYTE);
BEGIN N:= N XOR (1 SHL b) END;
