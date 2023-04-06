#include <cstdlib>
#include <chrono>
#include "thepi.h"

int main(int argc, char **argv) {
    thepiHandle_t handle;
    int steps = atoi(argv[1]);
    double * __restrict__ mypi = (double*) calloc(2, sizeof(double));


    handle = __dace_init_thepi(steps);
    auto start = std::chrono::high_resolution_clock::now();
    __program_thepi(handle, mypi, steps);
    auto end = std::chrono::high_resolution_clock::now();
    printf("Time %d [ms]\n", std::chrono::duration_cast<std::chrono::milliseconds>(end-start).count());
    __dace_exit_thepi(handle);

    free(mypi);


    return 0;
}
