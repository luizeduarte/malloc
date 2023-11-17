#include <stdio.h>
#include <unistd.h>
#include "libmalloc.h"

int main (long int argc, char** argv) {
	void *a, *b, *c, *d, *e, *f;

	iniciaAlocador();               // Impressão esperada
	imprimeMapa();                  // <vazio>

	a = (void *)alocaMem(10);
	imprimeMapa();                  // ################**********
	b = (void *)alocaMem(4);
	imprimeMapa();
	c = (void *)alocaMem(15);
	imprimeMapa();
	d = (void *)alocaMem(26);
	imprimeMapa();
	e = (void *)alocaMem(20);
	imprimeMapa();
	f = (void *)alocaMem(10);
	imprimeMapa();

	imprimeMapa();                  // ################**********##############****
	liberaMem(a);
	imprimeMapa();                  // ################----------##############****
	// liberaMem(b);                   // ################----------------------------
	// imprimeMapa();                  // ou
					// <vazio>

	liberaMem(f);
	imprimeMapa();
	liberaMem(d);
	imprimeMapa();
	liberaMem(e);
	imprimeMapa();
	liberaMem(b);
	imprimeMapa();
	b = (void *)alocaMem(4);
	imprimeMapa();
	e = (void *)alocaMem(30);
	imprimeMapa();


	finalizaAlocador();
}