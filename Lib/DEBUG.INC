 {.$DEFINE DEBUG.}
 {$DEFINE Error_Checking}
   {$IFDEF Error_Checking}
     {$I+}  {L I/O Checking	       }
     {$Q+}  {L Overflow Checking       }
     {$R+}  {L Range Checking	       }
     {$S+}  {L Stack Overflow Checking }
   {$ELSE}
     {$I-}  {L I/O Checking	       }
     {$Q-}  {L Overflow Checking       }
     {$R-}  {L Range Checking	       }
     {$S-}  {L Stack Overflow Checking }
   {$ENDIF}
 {$UNDEF Error_Checking}

   {$IFDEF DEBUG}
     {$D+}  {G Debug Information	      }
     {$L+}  {G Local Symbol Information       }
     {$Y+}  {G Symbolic Reference Information }
   {$ELSE}
     {$D-}  {G Debug Information	      }
     {$L-}  {G Local Symbol Information       }
     {$Y-}  {G Symbolic Reference Information }
   {$ENDIF}

 {$A+}	{G Align Data}
 {$B-}	{L Short Circuit Boolean Evaluation   }
 {$E+}	{G Enable Emulation		      }
 {$G+}	{G Generate 80286 Code		      }
 {$N-}	{G Disable Numeric Processing	      }
 {$P+}	{G Enable Open Parameters	      }
 {$T+}	{G Type @ Operator		      }
 {$V+}	{L Var String Checking		      }
 {$X+}	{G Extended Syntax Enabled	      }
{=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=}