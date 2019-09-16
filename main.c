#include <stdio.h>

double power(double base, double n) {
	if (n > 0) {
		return base * power(base, n - 1);
	}
	else {
		return 1;
	}
}

int main() {
	double i;
	for (i = 1; i <= 10; i++) {
		printf("2 to the power of %f is %f. \n", i, power(2, i));
	}
	return 0;
}
