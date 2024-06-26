// ACME - a crossassembler for producing 6502/65c02/65816/65ce02 code.
// Copyright (C) 1998-2024 Marco Baye
// Have a look at "acme.c" for further info
//
// Dynamic buffer stuff
#ifndef dynabuf_H
#define dynabuf_H


#include "config.h"
#include <stdlib.h>	// for size_t


// macros
#define DYNABUF_APPEND(db, byte)	\
do {					\
	if (db->size == db->reserved)	\
		dynabuf_enlarge(db);	\
	db->buffer[(db->size)++] = byte;\
} while (0)
// the next one is dangerous - the buffer location can change when a character
// is appended. So after calling this, don't change the buffer as long as you
// use the address.
#define GLOBALDYNABUF_CURRENT		(GlobalDynaBuf->buffer)


// dynamic buffer structure
struct dynabuf {
	char	*buffer;	// pointer to buffer
	size_t	size;		// size of buffer's used portion
	size_t	reserved;	// total size of buffer
};
// new way of declaration/definition:
// the small struct above is static, only the buffer itself gets malloc'd (on
// first "clear").
#define STRUCT_DYNABUF_REF(name, size)	struct dynabuf name[1]	= {{NULL, 0, size}}
// the "[1]" makes sure the name refers to the address and not the struct
// itself, so existing code where the name referred to a pointer does not need
// to be changed.


// variables
extern struct dynabuf	GlobalDynaBuf[1];	// global dynamic buffer
// TODO - get rid of this, or move to global.c


// (ensure buffer is ready to use, then) clear dynamic buffer
extern void dynabuf_clear(struct dynabuf *db);

// this gets called by "APPEND" macro whenever buffer is too small
extern void dynabuf_enlarge(struct dynabuf *db);

// return malloc'd copy of buffer contents
extern char *dynabuf_get_copy(struct dynabuf *db);

// add string to buffer (terminator is added, but not included in "size"!)
extern void dynabuf_add_string(struct dynabuf *db, const char *str);

// add byte sequence to buffer
extern void dynabuf_add_bytes(struct dynabuf *db, const char *src, size_t size);

// add long integer as decimal number to buffer
extern void dynabuf_add_signed_long(struct dynabuf *db, signed long number);

// convert buffer contents to lower case
extern void dynabuf_to_lower(struct dynabuf *target, struct dynabuf *source);

// append char to buffer
extern void dynabuf_append(struct dynabuf *db, char);


#endif
