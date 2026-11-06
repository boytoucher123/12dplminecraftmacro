#ifndef COMMON_H_INCLUDED
#define COMMON_H_INCLUDED

// ----------------------------------------------------------------
// Generic return codes and constants shared by every module
// ----------------------------------------------------------------

#define SUCCESS        0
#define FAILURE        (-1)

#define TRUE           1
#define FALSE          0

// Returned up the call chain when 12d asks the macro to stop
// ("CodeShutdown"), so every panel closes at once
#define SHUTDOWN_CODE  424242

#define MACRO_TITLE    "Change me"   // TODO: name of the macro
#define MACRO_VERSION  "1.0"

#endif
