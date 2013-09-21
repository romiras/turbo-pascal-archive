
This archive contains a revised implementation of James Storer LRU
data compression method.
Originally, I downloaded PASLRU.ARC, which contained the same source
code, but with some bugs in it.  I did 3 things to the source code:

1. Removed the bugs
2. Altered some type definitions so that dictionnary sizes of >4096
could be tolerated
3. Moved some definitions in other places, and rewrote some things so that
the code compiles even when run time checking is on

You can compile the source code with turbo pascal.  I found the LRU
algorithm not superior to LHARC 1.13c, but slightly faster.
This is not industrial strength code, but the bugs have been eliminated.


I can be reached by the original uploader. (Johnny Penet)


Enjoy.

Vincent Van Den Berghe
Jordaenstraat 3
8510 Kortrijk-Marke
BELGIUM
