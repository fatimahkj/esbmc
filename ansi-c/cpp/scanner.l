%{
/*	$Id: scanner.l,v 1.32 2008/01/15 16:40:15 ragge Exp $   */

/*
 * Copyright (c) 2004 Anders Magnusson. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef _WIN32
#include <unistd.h>
#else
#include <windows.h>
#define YY_NO_UNISTD_H
// I am going to gnaw my own leg off.
#endif

#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <fcntl.h>
#include <errno.h>

#include "compat.h"
#include "cpp.h"
#include "y.tab.h"
%}

%{
static void cvtdig(int rad);
static int charcon(void);
static void elsestmt(void);
static void ifdefstmt(void);
static void ifndefstmt(void);
static void endifstmt(void);
static void ifstmt(void);
static void pragmastmt(void);
static void undefstmt(void);
static void cpplexerror(void);
static void elifstmt(void);
static void storepb(void);
static void badop(const char *);
void  include(void);
void  define(void);

extern int yyget_lineno (void);
extern void yyset_lineno (int);

static int inch(void);

static int scale, gotdef, contr;
int inif;

#ifdef FLEX_SCANNER /* should be set by autoconf instead */
static int
yyinput(char *b, int m)
{
	int c, i;

	for (i = 0; i < m; i++) {
		if ((c = inch()) < 0)
			break;
		*b++ = c;
		if (c == '\n') {
			i++;
			break;
		}
	}
	return i;
}
#undef YY_INPUT
#undef YY_BUF_SIZE
#define	YY_BUF_SIZE 32768
#define YY_INPUT(b,r,m) (r = yyinput(b, m))
#define fprintf(x, ...) error(__VA_ARGS__)
#define	ECHO putstr((usch *)cpptext)
#undef fileno
#define fileno(x) 0

#if YY_FLEX_SUBMINOR_VERSION >= 31
/* Hack to avoid unneccessary warnings */
FILE *yyget_in	(void);
FILE *yyget_out  (void);
char *yyget_text  (void);
void yyset_in (FILE *  in_str );
void yyset_out (FILE *	out_str );
int yyget_debug  (void);
void yyset_debug (int  bdebug );
int cpplex_destroy  (void);
#endif
#else	/* Assume lex here */
#undef input
#undef unput
#define input() inch()
#define unput(ch) unch(ch)
#endif
#define PRTOUT(x) if (YYSTATE || slow) return x; if (!flslvl) putstr((usch *)cpptext);
int inclevel;
%}

D	[0-9]
L	[a-zA-Z_]
H	[a-fA-F0-9]
E	[Ee][+-]?{D}+
FS	(f|F|l|L)
IS	(u|U|l|L)*
WS	[\t ]

%s IFR CONTR DEF
%x LINEINFO

%%

{WS}*#{WS}+[0-9]+{WS}+	{ contr = 0; BEGIN LINEINFO; putstr((usch*)cpptext); }
<LINEINFO>\".*\"{WS}*	{ putstr((usch*)cpptext); }
<LINEINFO>[0-9]{WS}*	{ putstr((usch*)cpptext); }
<LINEINFO>"\n"		{ putstr("\n"); BEGIN 0; }


"\n"			{	int os = YYSTATE;
				if (os != IFR)
					BEGIN 0;
				ifiles->lineno++;
				if (flslvl == 0) {
					if (ifiles->lineno == 1)
						prtline();
					else
						putch('\n');
				}
				if ((os != 0 || slow) && !contr)
					return '\n';
				contr = 0;
			}

"\r"			{ ; /* Ignore CR's */ }

<IFR>"++"		{ badop("++"); }
<IFR>"--"		{ badop("--"); }
<IFR>"=="		{ return EQ; }
<IFR>"!="		{ return NE; }
<IFR>"<="		{ return LE; }
<IFR>"<<"		{ return LS; }
<IFR>">>"		{ return RS; }
<IFR>">="		{ return GE; }
<IFR>"||"		{ return OROR; }
<IFR>"&&"		{ return ANDAND; }
<IFR>"defined"		{	int p, c;
				gotdef = 1;
				if ((p = c = cpplex()) == '(')
					c = cpplex();
				if (c != IDENT || (p != IDENT && p != '('))
					error("syntax error");
				if (p == '(' && cpplex() != ')')
					error("syntax error");
				return NUMBER;
			}

<IFR>{WS}+		{ ; }
<IFR>{L}({L}|{D})*	{
				cpplval.node.op = NUMBER;
				if (gotdef) {
					cpplval.node.nd_val
					    = lookup((usch *)cpptext, FIND) != 0;
					gotdef = 0;
					return IDENT;
				}
				cpplval.node.nd_val = 0;
				return NUMBER;
			}

[1-9][0-9]*		{ if (slow && !YYSTATE) return IDENT; scale = 10; goto num; }

0[xX]{H}+{IS}?		{	scale = 16;
			num:	if (YYSTATE == IFR) 
					cvtdig(scale);
				PRTOUT(NUMBER);
			}
0{D}+{IS}?		{ scale = 8; goto num; }
{D}+{IS}?		{ scale = 10; goto num; }
L?'(\\.|[^\\'])+'	{	if (YYSTATE) {
					cpplval.node.op = NUMBER;
					cpplval.node.nd_val = charcon();
				}
				PRTOUT(NUMBER);
			}

<IFR>.			{ return cpptext[0]; }

{D}+{E}{FS}?		{ PRTOUT(FPOINT); }
{D}*"."{D}+({E})?{FS}?	{ PRTOUT(FPOINT); }
{D}+"."{D}*({E})?{FS}?	{ PRTOUT(FPOINT); }

^{WS}*#{WS}*		{	extern int inmac;

				if (inmac)
					error("preprocessor directive found "
					    "while expanding macro");
				contr = 1;
				BEGIN CONTR;
			}
{WS}+			{ PRTOUT(WSPACE); }

<CONTR>"ifndef"		{ contr = 0; ifndefstmt(); }
<CONTR>"ifdef"		{ contr = 0; ifdefstmt(); }
<CONTR>"if"		{ contr = 0; storepb(); BEGIN IFR; ifstmt(); BEGIN 0; }
<CONTR>"include"	{ contr = 0; BEGIN 0; include(); prtline(); }
<CONTR>"else"		{ contr = 0; elsestmt(); }
<CONTR>"endif"		{ contr = 0; endifstmt(); }
<CONTR>"error"		{ contr = 0; if (slow) return IDENT; cpplexerror(); BEGIN 0; }
<CONTR>"define"		{ contr = 0; BEGIN DEF; define(); BEGIN 0; }
<CONTR>"undef"		{ contr = 0; if (slow) return IDENT; undefstmt(); }
<CONTR>"line"		{ contr = 0; storepb(); BEGIN 0; line(); }
<CONTR>"pragma"		{ contr = 0; pragmastmt(); BEGIN 0; }
<CONTR>"elif"		{ contr = 0; storepb(); BEGIN IFR; elifstmt(); BEGIN 0; }



"//".*$			{ /* if (tflag) yyless(..) */
				if (Cflag)
					putstr((usch *)cpptext);
				else if (!flslvl)
					putch(' ');
			}
"/*"			{	int c, wrn;
				if (Cflag)
					putstr((usch *)cpptext);
				wrn = 0;
			more:	while ((c = input()) && c != '*') {
					if (c == '\n')
						putch(c), ifiles->lineno++;
					else if (c == 1) /* WARN */
						wrn = 1;
					else if (Cflag)
						putch(c);
				}
				if (c == 0)
					return 0;
				if (Cflag)
					putch(c);
				if ((c = input()) && c != '/') {
					if (Cflag)
						putch('*');
					unput(c);
					goto more;
				}
				if (Cflag)
					putch(c);
				if (c == 0)
					return 0;
				if (!tflag && !Cflag && !flslvl)
					unput(' ');
				if (wrn)
					unput(1);
			}

<DEF>"##"		{ return CONCAT; }
<DEF>"#"		{ return MKSTR; }
<DEF>"..."		{ return ELLIPS; }
<DEF>"__VA_ARGS__"	{ return VA_ARGS; }

L?\"(\\.|[^\\"])*\"	{ PRTOUT(STRING); }
[a-zA-Z_0-9]+		{ /* {L}({L}|{D})* */
				struct symtab *nl;
				if (slow)
					return IDENT;
				if (YYSTATE == CONTR) {
					if (flslvl == 0) {
						/*error("undefined control");*/
						while (input() != '\n')
							;
						unput('\n');
						BEGIN 0;
						goto xx;
					} else {
						BEGIN 0; /* do nothing */
					}
				}
				if (flslvl) {
					; /* do nothing */
				} else if (isdigit((int)cpptext[0]) == 0 &&
				    (nl = lookup((usch *)cpptext, FIND)) != 0) {
					usch *op = stringbuf;
					putstr(gotident(nl));
					stringbuf = op;
				} else
					putstr((usch *)cpptext);
				xx: ;
			}

.			{ PRTOUT(cpptext[0]); }


%%

usch *yyp, yybuf[CPPBUF];

int cpplex(void);
int yywrap(void);

static int
inpch(void)
{
	int len;

	if (ifiles->curptr < ifiles->maxread)
		return *ifiles->curptr++;

	if (ifiles->infil == -1)
		/* Invalid fd indicates not-a-file */
		return -1;

	if ((len = read(ifiles->infil, ifiles->buffer, CPPBUF)) < 0)
		error("read error on file %s", ifiles->orgfn);
	if (len == 0)
		return -1;
	ifiles->curptr = ifiles->buffer;
	ifiles->maxread = ifiles->buffer + len;
	return inpch();
}

#define unch(c) *--ifiles->curptr = c

static int
inch(void)
{
	int c;

again:	switch (c = inpch()) {
	case '\\': /* continued lines */
		if ((c = inpch()) == '\n') {
			ifiles->lineno++;
			putch('\n');
			goto again;
		}
		unch(c);
		return '\\';
	case '?': /* trigraphs */
		if ((c = inpch()) != '?') {
			unch(c);
			return '?';
		}
		switch (c = inpch()) {
		case '=': c = '#'; break;
		case '(': c = '['; break;
		case ')': c = ']'; break;
		case '<': c = '{'; break;
		case '>': c = '}'; break;
		case '/': c = '\\'; break;
		case '\'': c = '^'; break;
		case '!': c = '|'; break;
		case '-': c = '~'; break;
		default:
			unch(c);
			unch('?');
			return '?';
		}
		unch(c);
		goto again;
	default:
		return c;
	}
}

/*
 * Let the command-line args be faked defines at beginning of file.
 */
static void
prinit(struct initar *it, struct includ *ic)
{
	char *a, *pre, *post;

	if (it->next)
		prinit(it->next, ic);
	pre = post = NULL; /* XXX gcc */
	switch (it->type) {
	case 'D':
		pre = "#define ";
		if ((a = strchr(it->str, '=')) != NULL) {
			*a = ' ';
			post = "\n";
		} else
			post = " 1\n";
		break;
	case 'U':
		pre = "#undef ";
		post = "\n";
		break;
	case 'i':
		pre = "#include \"";
		post = "\"\n";
		break;
	default:
		error("prinit");
	}
	strlcat((char *)ic->buffer, pre, CPPBUF+1);
	strlcat((char *)ic->buffer, it->str, CPPBUF+1);
	if (strlcat((char *)ic->buffer, post, CPPBUF+1) >= CPPBUF+1)
		error("line exceeds buffer size");

	ic->lineno--;
	while (*ic->maxread)
		ic->maxread++;
}

/*
 * A new file included.
 * If ifiles == NULL, this is the first file and already opened (stdin).
 * Return 0 on success, -1 if file to be included is not found.
 */
int
pushfile(usch *file)
{
	extern struct initar *initar;
	struct includ ibuf;
	struct includ *ic;
	int c, otrulvl;

	ic = &ibuf;
	ic->next = ifiles;

	slow = 0;
	if (file != NULL) {
		if ((ic->infil = open((char *)file, O_RDONLY)) < 0) {
			if (errno != ENOENT)
				error("Cannot open '%s'. %s", file,
						strerror(errno));
			return -1;
		}
		ic->orgfn = ic->fname = file;
		if (++inclevel > MAX_INCLEVEL)
			error("Limit for nested includes exceeded");
	} else {
		ic->infil = 0;
		ic->orgfn = ic->fname = (usch *)"<stdin>";
	}
	ic->buffer = ic->bbuf+NAMEMAX;
	ic->curptr = ic->buffer;
	ifiles = ic;
	ic->lineno = 1;
	ic->maxread = ic->curptr;
	prtline();
	if (initar) {
		*ic->maxread = 0;
		prinit(initar, ic);
		if (dMflag)
			write(ofd, ic->buffer, strlen((char *)ic->buffer));
		initar = NULL;
	}

	otrulvl = trulvl;

	if ((c = cpplex()) != 0)
		error("cpplex returned %d", c);

	if (otrulvl != trulvl || flslvl)
		error("unterminated conditional");

	ifiles = ic->next;
	close(ic->infil);
	inclevel--;
	return 0;
}

/*
 * Print current position to output file.
 */
void
prtline()
{
	usch *s, *os = stringbuf;

	if (Mflag) {
		if (dMflag)
			return; /* no output */
		if (ifiles->lineno == 1) {
			s = sheap("%s: %s\n", Mfile, ifiles->fname);
			write(ofd, s, strlen((char *)s));
		}
	} else {
		usch *tmp, *put;
		unsigned int i, len, idx;
		/* jmorse: for greater windows compatibility, escape backslashes
		 * in the file path. The ESBMC parser/scanner _really_ doesn't
		 * like them. (Presumably in the past MSVC has escaped them)*/
		tmp = sheap("# %d \"%s\"\n", ifiles->lineno, ifiles->fname);
		len = strlen(tmp);
		put = malloc(len * 2 + 2);
		for (i = 0, idx = 0; i < len; i++) {
			if (tmp[i] == '\\') {
				put[idx++] = '\\';
				put[idx++] = '\\';
			} else {
				put[idx++] = tmp[i];
			}
		}
		put[idx++] = 0;
		putstr(put);
//		free(put);
//		free(tmp);
	}
	stringbuf = os;
}

void
cunput(int c)
{
#ifdef CPP_DEBUG
	extern int dflag;
	if (dflag)printf(": '%c'(%d)", c, c);
#endif
	unput(c);
}

int yywrap(void) { return 1; }

static int
dig2num(int c)
{
	if (c >= 'a')
		c = c - 'a' + 10;
	else if (c >= 'A')
		c = c - 'A' + 10;
	else
		c = c - '0';
	return c;
}

/*
 * Convert string numbers to unsigned long long and check overflow.
 */
static void
cvtdig(int rad)
{
	unsigned long long rv = 0;
	unsigned long long rv2 = 0;
	char *y = cpptext;
	int c;

	c = *y++;
	if (rad == 16)
		y++;
	while (isxdigit(c)) {
		rv = rv * rad + dig2num(c);
		/* check overflow */
		if (rv / rad < rv2)
			error("Constant \"%s\" is out of range", cpptext);
		rv2 = rv;
		c = *y++;
	}
	y--;
	while (*y == 'l' || *y == 'L')
		y++;
	cpplval.node.op = *y == 'u' || *y == 'U' ? UNUMBER : NUMBER;
	cpplval.node.nd_uval = rv;
	if ((rad == 8 || rad == 16) && cpplval.node.nd_val < 0)
		cpplval.node.op = UNUMBER;
	if (cpplval.node.op == NUMBER && cpplval.node.nd_val < 0)
		/* too large for signed */
		error("Constant \"%s\" is out of range", cpptext);
}

static int
charcon(void)
{
	usch *p = (usch *)cpptext;
	int val, c;

	if (*p == 'L')
		p++;
	p++; /* first ' */
	val = 0;
	if (*p++ == '\\') {
		switch (*p++) {
		case 'a': val = '\a'; break;
		case 'b': val = '\b'; break;
		case 'f': val = '\f'; break;
		case 'n': val = '\n'; break;
		case 'r': val = '\r'; break;
		case 't': val = '\t'; break;
		case 'v': val = '\v'; break;
		case '\"': val = '\"'; break;
		case '\'': val = '\''; break;
		case '\\': val = '\\'; break;
		case 'x':
			while (isxdigit(c = *p)) {
				val = val * 16 + dig2num(c);
				p++;
			}
			break;
		case '0': case '1': case '2': case '3': case '4':
		case '5': case '6': case '7':
			p--;
			while (isdigit(c = *p)) {
				val = val * 8 + (c - '0');
				p++;
			}
			break;
		default: val = p[-1];
		}

	} else
		val = p[-1];
	return val;
}

static void
chknl(void)
{
	int t;

	slow = 1;
	while ((t = cpplex()) == WSPACE)
		;
	if (t != '\n')
		error("newline expected, got \"%s\"", cpptext);
	slow = 0;
}

static void
elsestmt(void)
{
	if (flslvl) {
		if (elflvl > trulvl)
			;
		else if (--flslvl!=0) {
			flslvl++;
		} else {
			trulvl++;
			prtline();
		}
	} else if (trulvl) {
		flslvl++;
		trulvl--;
	} else
		error("If-less else");
	if (elslvl==trulvl+flslvl)
		error("Too many else");
	elslvl=trulvl+flslvl;
	chknl();
}

static void
ifdefstmt(void)		 
{ 
	int t;

	if (flslvl) {
		/* just ignore the rest of the line */
		while (input() != '\n')
			;
		unput('\n');
		cpplex();
		flslvl++;
		return;
	}
	slow = 1;
	do
		t = cpplex();
	while (t == WSPACE);
	if (t != IDENT)
		error("bad ifdef");
	slow = 0;
	if (flslvl == 0 && lookup((usch *)cpptext, FIND) != 0)
		trulvl++;
	else
		flslvl++;
	chknl();
}

static void
ifndefstmt(void)	  
{ 
	int t;

	slow = 1;
	do
		t = cpplex();
	while (t == WSPACE);
	if (t != IDENT)
		error("bad ifndef");
	slow = 0;
	if (flslvl == 0 && lookup((usch *)cpptext, FIND) == 0)
		trulvl++;
	else
		flslvl++;
	chknl();
}

static void
endifstmt(void)		 
{
	if (flslvl) {
		flslvl--;
		if (flslvl == 0)
			prtline();
	} else if (trulvl)
		trulvl--;
	else
		error("If-less endif");
	if (flslvl == 0)
		elflvl = 0;
	elslvl = 0;
	chknl();
}

/*
 * Note! Ugly!
 * Walk over the string s and search for defined, and replace it with 
 * spaces and a 1 or 0. 
 */
static void
fixdefined(usch *s)
{
	usch *bc, oc;

	for (; *s; s++) {
		if (*s != 'd')
			continue;
		if (memcmp(s, "defined", 7))
			continue;
		/* Ok, got defined, can scratch it now */
		memset(s, ' ', 7);
		s += 7;
#define	WSARG(x) (x == ' ' || x == '\t')
		if (*s != '(' && !WSARG(*s))
			continue;
		while (WSARG(*s))
			s++;
		if (*s == '(')
			s++;
		while (WSARG(*s))
			s++;
#define IDARG(x) ((x>= 'A' && x <= 'Z') || (x >= 'a' && x <= 'z') || (x == '_'))
#define	NUMARG(x) (x >= '0' && x <= '9')
		if (!IDARG(*s))
			error("bad defined arg");
		bc = s;
		while (IDARG(*s) || NUMARG(*s))
			s++;
		oc = *s;
		*s = 0;
		*bc = (lookup(bc, FIND) != 0) + '0';
		memset(bc+1, ' ', s-bc-1);
		*s = oc;
	}
}

/*
 * get the full line of identifiers after an #if, pushback a WARN and
 * the line and prepare for expmac() to expand.
 * This is done before switching state.  When expmac is finished,
 * pushback the expanded line, change state and call cppparse.
 */
static void
storepb(void)
{
	usch *opb = stringbuf;
	int c;

	while ((c = input()) != '\n')
		savch(c);
	cunput('\n');
	savch(0);
	fixdefined(opb); /* XXX can fail if #line? */
	cunput(1); /* WARN XXX */
	unpstr(opb);
	stringbuf = opb;
	slow = 1;
	expmac(NULL);
	slow = 0;
	/* line now expanded */
	while (stringbuf > opb)
		cunput(*--stringbuf);
}

static void
ifstmt(void)
{
	if (flslvl == 0) {
		slow = 1;
		if (cppparse())
			++trulvl;
		else
			++flslvl;
		slow = 0;
	} else
		++flslvl;
}

static void
elifstmt(void)
{
	if (flslvl == 0)
		elflvl = trulvl;
	if (flslvl) {
		if (elflvl > trulvl)
			;
		else if (--flslvl!=0)
			++flslvl;
		else {
			slow = 1;
			if (cppparse()) {
				++trulvl;
				prtline();
			} else
				++flslvl;
			slow = 0;
		}
	} else if (trulvl) {
		++flslvl;
		--trulvl;
	} else
		error("If-less elif");
}

static usch *
svinp(void)
{
	int c;
	usch *cp = stringbuf;

	while ((c = input()) && c != '\n')
		savch(c);
	savch('\n');
	savch(0);
	BEGIN 0;
	return cp;
}

static void
cpplexerror(void)
{
	usch *cp;
	int c;

	if (flslvl)
		return;
	c = cpplex();
	if (c != WSPACE && c != '\n')
		error("bad error");
	cp = svinp();
	if (flslvl)
		stringbuf = cp;
	else
		error("%s", cp);
}

static void
undefstmt(void)
{
	struct symtab *np;

	slow = 1;
	if (cpplex() != WSPACE || cpplex() != IDENT)
		error("bad undef");
	if (flslvl == 0 && (np = lookup((usch *)cpptext, FIND)))
		np->value = 0;
	slow = 0;
	chknl();
}

static void
pragmastmt(void)
{
	int c;

	slow = 1;
	if (cpplex() != WSPACE)
		error("bad pragma");
	if (!flslvl)
		putstr((usch *)"#pragma ");
	do {
		c = input();
		if (!flslvl)
			putch(c);	/* Do arg expansion instead? */
	} while (c && c != '\n');
	ifiles->lineno++;
	prtline();
	slow = 0;
}

static void
badop(const char *op)
{
	error("invalid operator in preprocessor expression: %s", op);
}