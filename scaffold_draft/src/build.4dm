#ifndef INCLUDE_BUILD_4DM
#define INCLUDE_BUILD_4DM

// Safety first: blocks every dangerous library call for all the
// source files below (see the header). Keep it the first include.
#include "../include/safety.h"

// Build settings

#define RELEASE
//#define DEBUG


// Build logic
#if defined(DEBUG) && defined(RELEASE)
#warning Conflicting build modes enabled <RELEASE|DEBUG>
#elif !defined(DEBUG) && !defined(RELEASE)
#warning Build mode unspecified : <RELEASE|DEBUG>
#endif

#ifdef RELEASE
#undef DEBUG
#endif

#include "../include/debug.h"

// Optional libraries (uncomment the ones the macro uses)
//#include "../libs/macro_assert.h"
//#include "../libs/to_text.h"


// Source files (each includes the headers it needs, so the order
// here doesn't matter)
#include "records.4dm"
#include "events.4dm"
#include "model.4dm"
#include "main_panel.4dm"


// Error for multiple inclusions of build.4dm
#else
#error Don't include build.4dm more than once
#endif
