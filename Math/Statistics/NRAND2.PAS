(*--------------------------------------------------------------------------*)
(*          NRand --- Return normally-distributed random number             *)
(*--------------------------------------------------------------------------*)

FUNCTION NRand( Mean : REAL;  StdDev : REAL ) : REAL;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*       Function:  NRand                                                   *)
(*                                                                          *)
(*       Purpose:   Returns normally distributed random number.             *)
(*                                                                          *)
(*       Calling sequence:                                                  *)
(*                                                                          *)
(*          Ran := NRand( Mean : REAL; StdDev : REAL ) : REAL;              *)
(*                                                                          *)
(*             Mean   --- Mean of normal distribution                       *)
(*             StdDev --- Standard deviation of normal distribution         *)
(*             Ran    --- Resultant random number                           *)
(*                                                                          *)
(*       Method:                                                            *)
(*                                                                          *)
(*          The Box-Muller transformation is used to get two normal(0,1)-   *)
(*          distributed values.  The given mean and standard deviation are  *)
(*          used to scale the results to (Mean, StdDev).  The first random  *)
(*          number is returned by this call, and the second random number   *)
(*          by the next call.                                               *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

(* STATIC VARIABLES *) CONST
   NRand_Available : BOOLEAN = FALSE     (* If number already available -- *);
   Saved_NRand     : REAL    = 0.0       (* saved from last time through.  *);

VAR
   V1 : REAL;
   V2 : REAL;
   R  : REAL;
   Fac: REAL;

BEGIN (* NRand *)
                                   (* Return 2nd random number calculated *)
                                   (* last time through here.             *)
   IF NRand_Available THEN
      BEGIN
         NRand           := Saved_NRand * StdDev + Mean;
         NRand_Available := FALSE;
      END
   ELSE
      BEGIN                        (* Calculate two new random numbers *)
                                   (* using Box-Muller transformation  *)
         REPEAT
            V1 := 2.0 * RANDOM - 1.0;
            V2 := 2.0 * RANDOM - 1.0;
            R  := SQR( V1 ) + SQR( V2 );
         UNTIL ( R < 1.0 );
                                   (* Return 1st number this time, and *)
                                   (* save second one for next time    *)
                                   (* through.                         *)

         Fac             := SQRT( -2.0 * LN( R ) / R );

         NRand           := V1 * Fac * StdDev + Mean;

         Saved_NRand     := V2 * Fac;
         NRand_Available := TRUE;

      END;

END   (* NRand *);
