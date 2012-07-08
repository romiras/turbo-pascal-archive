// * TPTCMAC.H - Macro Header for use with Turbo Pascal --> C Translator

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <dos.h>
#include <conio.h>
#include <ctype.h>

/* define some simple keyword replacements */
#define pred(v) 	((v)-1)
#define succ(v) 	((v)+1)
#define chr(n)		(n)
#define ord(c)		(c)
#define lo(v)		(v & 0xff)
#define hi(v)		(v >> 8)
#define inc(v)		(v)++
#define dec(v)		(v)--

#define maxint		0x7fff
#define integer 	int
#define word		unsigned
#define longint 	long
#define byte		char
#define real		double
#define boolean 	int
typedef void		*pointer;

#define false		0
#define true		1
#define nil		NULL

#define delete(s,p,num) strcpy(s+p-1,s+p+num)
#define val(s,res,code) code=0, res=atof(s)
typedef char *charptr;
#define STRSIZ 255	/* default string length */
#define paramstr(n)	(argv[n])
#define paramcount	(argc-1)
// File access support
char _CURNAME[64];
int  ioresult = 0;
typedef FILE		*text;
#define kbd		stdin
#define input		stdin
#define con		stdout
#define output		stdout
#define assign(fd,name) strcpy(_CURNAME,name)
void	reset(text  *fd)
{
    *fd = fopen(_CURNAME,"r");
    ioresult = (*fd == NULL);
}
void	rewrite(text *fd)
{
    *fd = fopen(_CURNAME,"w");
    ioresult = (*fd == NULL);
}
void	append(text *fd)
{
    *fd = fopen(_CURNAME,"a");
    ioresult = (*fd == NULL);
}
/*   setrec setof(a,b,...,-1)
 *	construct and return a set of the specified character values
 *
 *   inset(ex,setrec)
 *	predicate returns true if expression ex is a member of
 *	the set parameter
 */
#define __  -2	  /* thru .. */
#define _E  -1	  /* end of set marker */

typedef struct {
      char setstub[16];
} setrec;
// * copy len bytes from the dynamic string dstr starting at position from
charptr copy(charptr str,
	     int    from,
	     int    len)
{
   static char buf[STRSIZ];
   buf[0]=0;
   if (from>strlen(str))     /* copy past end gives null string */
      return buf;

   strcpy(buf,str+from-1);  /* skip over first part of string */
   buf[len] = 0;	    /* truncate after len characters */
   return buf;
}
/* String/character concatenation function
 *
 * This function takes a sprintf-like control string, a variable number of
 * parameters, and returns a pointer a static location where the processed
 * string is to be stored.
 */
charptr scat(charptr control, ...)
{
   static char buf[STRSIZ];
   char buf2[STRSIZ];
   va_list args;
   va_start(args, control);	/* get variable arg pointer */
   vsprintf(buf2,control,args); /* format into buf with variable args */
   va_end(args);		/* finish the arglist */
   strcpy(buf,buf2);
   return buf;			/* return a pointer to the string */
}
#define ctos(ch) scat("%c",ch)	/* character to string conversion */
/* string build - like scat, sprintf, but will not over-write any
 *		  input parameters
 */
void sbld(charptr dest,
	  charptr control, ...)
{
   char buf[STRSIZ];
   va_list args;
   va_start(args, control);	/* get variable arg pointer */
   vsprintf(buf,control,args);	/* format into buf with variable args */
   va_end(args);		/* finish the arglist */
   strcpy(dest,buf);		/* copy result */
}
/* spos(str1,str2) - returns index of first occurence of str1 within str2;
 *    1=first char of str2
 *    0=nomatch
 */
int spos(charptr str1,
	 charptr str2)
{
   charptr res;
   res = strstr(str2,str1);
   if (res == NULL)
      return 0;
   else
      return res - str2 + 1;
}
/* cpos(str1,str2) - returns index of first occurence of c within str2;
 *    1=first char of str2
 *    0=nomatch
 */
int cpos(char c,
	 charptr str2)
{
   charptr res;
   res = strchr(str2,c);
   if (res == NULL)
      return 0;
   else
      return res - str2 + 1;
}
/* Scanf/Fscanf support
 *
 * These functions operate like scanf and fscanf except for an added control
 * code used for full-line reads.
 *
 */
int fscanv(text fd,
	   charptr control, ...)
{
   va_list args;
   charptr arg1;
   int	   i;
   va_start(args, control);	/* get variable arg pointer */
   /* process special case for full-line reads (why doesn't scanf allow
      full-line string reads?  why don't gets and fgets work the same?) */
   if (*control == '#') {
      arg1 = va_arg(args,charptr);
      fgets(arg1,STRSIZ,fd);
      arg1[strlen(arg1)-1] = 0;
      return 1;
   }
   /* pass the request on to fscanf */
   i = vfscanf(fd,control,args);    /* scan with variable args */
   va_end(args);		    /* finish the arglist */
   return i;			    /* return a pointer to the string */
}
#undef atoi	    /* in case of user ident clash */
#undef getchar
/* rename some tp4 calls that conflict with tc1.0 functions
 *
 */
#define intr	Pintr
#define getdate Pgetdate
#define gettime Pgettime
#define setdate Psetdate
#define settime Psettime
#define keep    Pkeep