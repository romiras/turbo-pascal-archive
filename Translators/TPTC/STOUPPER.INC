
(*--------------------------------------------------------
 *   map string to upper case (tpas 4.0)
 *)

{$F+} procedure stoupper(var st: string); {$F-}
begin

   Inline(
     $C4/$7E/$06/           {   les di,[bp]6         ;es:di -> st[0]}
     $26/                   {   es:}
     $8A/$0D/               {   mov cl,[di]          ;cl = length}
     $FE/$C1/               {   inc cl}

                            {next:}
     $47/                   {   inc di}
     $FE/$C9/               {   dec cl}
     $74/$12/               {   jz ends}

     $26/                   {   es:}
     $8A/$05/               {   mov al,[di]}
     $3C/$61/               {   cmp al,'a'}
     $72/$F4/               {   jb next}
     $3C/$7A/               {   cmp al,'z'}
     $77/$F0/               {   ja next}

     $2C/$20/               {   sub al,' '}
     $26/                   {   es:}
     $88/$05/               {   mov [di],al}
     $EB/$E9);              {   jmp next}

                            {ends:}
end;

