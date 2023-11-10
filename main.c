#include "libmalloc.s"

int main(){
	char *string1, *string2;

	//aloca memoria de 5 bytes para a string
	string1 = alocaMem(5);
	string1 = "Hello";

	string2 = alocaMem(5);
	string2 = "World";

	
}