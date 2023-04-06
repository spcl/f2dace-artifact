#include <dace/dace.h>
typedef void * thepiHandle_t;
extern "C" thepiHandle_t __dace_init_thepi(int steps);
extern "C" void __dace_exit_thepi(thepiHandle_t handle);
extern "C" void __program_thepi(thepiHandle_t handle, double * __restrict__ mypi, int steps);
