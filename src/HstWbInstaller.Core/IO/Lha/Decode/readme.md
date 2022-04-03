
Data types:

`uint64_t` = `ulong`

In C++ integers are used as boolean:
- An integer value of 0 is evaluated as false: `false = (i == 0)`
- An integer value other than 0 is evaluated as true: `true = (i != 0)`


https://github.com/libarchive/libarchive/blob/master/libarchive/archive_read_support_format_lha.c


https://github.com/jpoikela/jslha



c++ increase array of pointers:
int arr[] // array iof int
int *p = arr; // pointer to array of pointers

return *( arr + i ) // gets value
*( arr + i ) = 1 // sets value



short a[100], sum = 0; // array & sum used for all of the following examples
short i;

// version 2: uses a counter and also steps a pointer through the array
short *pa = a; // a is the address of a[0]
for(i = 0; i != 100; i++) { // use counter to determine when done
  sum += *pa;
  pa++; // increment pointer to next element
}


short arr[100]; // array with 100 elements
short *p = arr; // pointer to first element in array
*p = 1; // set value of first element
sum += *p; // get value of first element
p++; // increase pointer to next element