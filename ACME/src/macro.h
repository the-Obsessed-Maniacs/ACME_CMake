// ACME - a crossassembler for producing 6502/65c02/65816/65ce02 code.
// Copyright (C) 1998-2024 Marco Baye
// Have a look at "acme.c" for further info
//
// Macro stuff
#ifndef macro_H
#define macro_H


#include "config.h"


// Prototypes

// only call once (during first pass)
extern void macro_parse_definition(void);

// Parse macro call ("+MACROTITLE"). Has to be re-entrant.
extern void macro_parse_call(void);


#endif
