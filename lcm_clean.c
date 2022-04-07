#include <stdio.h>
#define N 10

int isDone(unsigned int *a);
int findIndexSmallest(unsigned int *a);

int main()
{
	unsigned int nums[N], scratch[N];
	int i, done, s;
	
	printf("Enter %d numbers: ", N);
	for (i=0; i<N; i++){
		scanf("%ld", &nums[i]);
		scratch[i] = nums[i];
	}
	if (!isDone(scratch)) {
		while(1) {
			s = findIndexSmallest(scratch);
			scratch[s] = scratch[s] + nums[s];
			if (isDone(scratch)) {
				break;
			}
		}
	}
	
	printf("LCM = %ld\n", scratch[0]);
	
	return 0;
}


int isDone(unsigned int *a)
{
	int i;
	
	for (i=1; i<N; i++) {
		if (a[0] != a[i]) {
			return 0;
		}
	}
	return 1;
}


int findIndexSmallest(unsigned int *a)
{
	int i, s;
	s = 0;
	for (i=1; i<N; i++) {
		if (a[i] < a[s]) {
			s = i;
		}
	}
	return s;
}
