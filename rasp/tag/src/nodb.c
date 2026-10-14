/*
 * nodb.c -- sbcl-rasp: the tagger without Berkeley DB.
 *
 * The tagger can read its dictionary from a Berkeley DB file (option -v,
 * "bdbm"), but scripts/rasp.sh never uses that option: it reads the plain
 * text dictionary seclarge-c2s.lex.  These two functions replace the library,
 * so that building RASP needs no Berkeley DB.  Asking for option -v now
 * stops with a message instead of opening the file.
 */

#include <stdio.h>
#include <errno.h>
#include "../database/common/db.h"

int db_create(DB **dbp, DB_ENV *dbenv, u_int32_t flags)
{
	(void) dbenv;
	(void) flags;
	*dbp = NULL;
	return ENOSYS;
}

char *db_strerror(int error)
{
	(void) error;
	return "this build of RASP has no Berkeley DB; "
	       "use the text dictionary (rasp.sh does)";
}
