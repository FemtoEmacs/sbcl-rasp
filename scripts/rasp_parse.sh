#!/bin/bash

 ##############################################################################
 # Copyright 2002, 2006, 2011, 2012 John Carroll, Oeistein Andersen           #
 #                                                                            #
 # This file is part of RASP.                                                 #
 #                                                                            #
 # RASP is free software: you can redistribute it and/or modify it            #
 # under the terms of the GNU Lesser General Public License as published      #
 # by the Free Software Foundation, either version 3 of the License, or       #
 # (at your option) any later version.                                        #
 #                                                                            #
 # RASP is distributed in the hope that it will be useful,                    #
 # but WITHOUT ANY WARRANTY; without even the implied warranty of             #
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
 # GNU Lesser General Public License for more details.                        #
 #                                                                            #
 # You should have received a copy of the GNU Lesser General Public License   #
 # along with RASP.  If not, see <http://www.gnu.org/licenses/>.              #
 ##############################################################################

#
# Run the probabilistic parser on text that has been tokenised, tagged etc.
# Insert appropriate value for the shell variable RASP right below this comment.
# Nothing else in the file should be changed.
#
# Example invocation:
#
# ./rasp_parse.sh < ../prob/greval/parc700/test.not-ne.stag.data | more 
#

RASP=`cd "\`dirname $0\`/.." && pwd`  # c2s: absolute, so the parser image can find prob/patch*.lsp

if [ ! -d "$RASP" ]; then
  printf "$0: could not read RASP directory '%s'\n" "$RASP" > /dev/stderr
  exit 1;
fi

arch=`uname -m | sed "s/i.86/ix86/"`_`uname -s | tr "[:upper:]" "[:lower:]"`
if [ $arch = ix86_darwin ] && [ `sysctl -n hw.optional.x86_64` = 1 ]; 
then
    arch=x86_64_darwin;
fi

# Parser image: Clozure CL (bin/<arch>/gde) or SBCL (bin/<arch>/gde-sbcl).
# RASP_LISP=sbcl or RASP_LISP=ccl chooses; otherwise use whichever exists, CCL first.
lisp="${RASP_LISP:-}"
if [ -z "$lisp" ]; then
  if [ -f $RASP/bin/${arch}/gde ]; then lisp=ccl; else lisp=sbcl; fi
fi
case $lisp in
  ccl)  gdebin=$RASP/bin/${arch}/gde;;
  sbcl) gdebin=$RASP/bin/${arch}/gde-sbcl;;
  *) printf "$0: RASP_LISP must be ccl or sbcl\n" > /dev/stderr; exit 1;;
esac
if [ ! -f $gdebin ]; then
  printf "$0: could not find parser executable %s\n" "$gdebin" > /dev/stderr
  exit 1;
fi

# Process any command line options

debug="false"
parseval=nil
initforms=nil
logfile="/tmp/`whoami`-`basename $0`-log"
nparses=1
outformat=""
subcat=nil
timeout=10
unnumbered=nil
wordlimit=0
xphrasal=nil
outoptions=""

# Compute a suitable value for the amount of reserved heap space - default is
# 80% of physical memory. User should use -m option to set a lower value in
# case of simultaneous runs on a single (multi-core or -processor) machine

case $arch in
  *_darwin) memlimit=`sysctl -n hw.memsize`;;
  *_linux) memlimit=`awk '/MemTotal/ {printf "%i", $2 * 1024}' /proc/meminfo`;;
  *) memlimit=2000000000;;
esac
memlimit=`expr $memlimit - $memlimit / 5`

while getopts dei:l:m:n:o:st:uw:xp: opt
do
  case $opt in
    d) debug="true";;
    e) parseval=t;;
    i) initforms="$OPTARG";;
    l) logfile="$OPTARG";;
    m) memlimit="$OPTARG";;
    n) nparses="$OPTARG";;
    o) outformat="$OPTARG";;
    s) subcat=t;;
    t) timeout="$OPTARG";;
    u) unnumbered=t;;
    w) wordlimit="$OPTARG";;
    x) xphrasal=t;;
    p) outoptions="$OPTARG";;
    ?) echo "Usage: $0 [-e(val)] [-i <initforms>] [-l <logfile>] [-m <memlimit>] [-n <nparses>] [-o <outformats>] [-s(ubcat)] [-t <timeout>] [-u(nnumbered)] [-w <wordlimit>] [-x(phrasal)] [-p <output format options>]" > /dev/stderr;
       exit 1;;
  esac
done

if [ $# -ge $OPTIND ]; then
  printf "$0: superfluous command line arguments\n" > /dev/stderr
  exit 1
fi

cat /dev/null > "$logfile"
if [ ! -w "$logfile" ]; then
  printf "$0: logfile '%s' cannot be written to\n" "$logfile" > /dev/stderr
  exit 1
fi

memlimit=`echo $memlimit | sed 's/K$/000/;s/M$/000000/;s/G$/000000000/'`
if [ `expr "$memlimit" : '[1-9][0-9]\{8,\}$'` -eq 0 ]; then
  printf "$0: memlimit '%s' should be an integer >= 100000000\n" "$memlimit" > /dev/stderr
  exit 1
fi

if [ `expr "$nparses" : '[0-9]*$'` -eq 0 ]; then
  printf "$0: number of parses '%s' should be an integer >= 0\n" "$nparses" > /dev/stderr
  exit 1
fi

if [ $parseval = t -a `echo $outformat | grep -c [A-Z]` -eq 1 ]; then
  echo "$0: -e and XML -o options are incompatible -- ignoring -e" > /dev/stderr
  parseval=nil
fi


# have to use numbered for gio (i) output format:
if [ $unnumbered = t -a `echo $outformat | grep -ci i` -eq 1 ]; then
  echo "$0: -u and -oi/-oI options are incompatible -- ignoring -u" > /dev/stderr
  unnumbered=nil
fi

if [ `expr "$timeout" : '[0-9]*$'` -eq 0 ]; then
  printf "$0: timeout '%s' should be an integer >= 0\n" "$timeout" > /dev/stderr
  exit 1
fi
if [ $timeout = 0 ]; then
    timeout=86400; # 24 hours
fi

if [ `expr "$wordlimit" : '[0-9]*$'` -eq 0 ]; then
  printf "$0: wordlimit '%s' should be an integer >= 0\n" "$wordlimit" > /dev/stderr
  exit 1
fi

if [ $lisp = ccl ]; then
  gde="$gdebin -b -R $memlimit"
else
  gde="$gdebin"
fi

fsh="/tmp/`whoami`-`basename $0`-sh$$"

cat > "$fsh" <<EOF

#|
Options: $debug $parseval $initforms $logfile $memlimit $nparses $outformat $subcat $timeout $unnumbered $wordlimit $xphrasal $outoptions
|#

(in-package #+(or cltl2 x3j13 ansi-cl) common-lisp-user #-(or cltl2 x3j13 ansi-cl) 'user)

;;; Disable rules which deal with elliptical dialogue-like text as
;;; they tend to overapply elsewhere

(defparameter +disabled-rules+
    '(|V1/do_gap-r| |V1/have_gap-r| |V1/be_gap-r| |V1/mod_gap-r|
      |P1/prt-of| |P1/prt-r|
      ))

;;; Subcat probabilities, phrasal verb list

(setq *subcat-probs-p* $subcat)
(setq *phrasal-verbs-p* (not $xphrasal))

;;(setq +analysis-tree-type+ '$tt)
;;(setq +analysis-tree-print-fn+ '$tp)

;; initialise the +print-list+
(init-print-list "$outformat")


;; set the format options for output:
(set-print-options "$outoptions")
(setq +preserve-quotes+ t)

(setq +parseval-output-p+ $parseval)

(setq +numbered-words-p+ (not $unnumbered))

;;; Tag filtering, numbers of parses and timeout
;;; relevant only if multiple tags per word are input
;;; +multiple-tag-certainty+ - if the top ranked tag is more probable
;;; than this value (in this case 0.9) then only this tag is considered
;;; +multiple-tag-threshold+ - only consider a tag if not less than this many
;;; times as probable. e.g. in this case we won't consider tags which are
;;; less than 1/50 times as probable as the top ranked tag.

(setq +multiple-tag-threshold+ (log 50 10))
(setq +multiple-tag-certainty+ (log 0.90 10))

(setq +n-best-retained+ $nparses)

(defparameter +parse-timeout+ $timeout) ; seconds cpu time

(setq +max-sentence-length+ $wordlimit)

;;; Partially disable generational GC (it's not particularly useful since storage is
;;; allocated and becomes garbage in waves), and raise global GC threshold

#+(and clozure x86 (not x86-64))
(progn
   (ccl:configure-egc 90000 90000 90000) ; 90MB
   (ccl:set-lisp-heap-gc-threshold 150000000)) ; 150 MB
#+(and clozure x86-64)
(progn
   (ccl:configure-egc 180000 180000 180000) ; 180MB
   (ccl:set-lisp-heap-gc-threshold 300000000)) ; 300MB
#+clozure (ccl:gc-retain-pages t)
; (ccl:gc-verbose t t)
#+clozure (setq +memlimit+ $memlimit)


;;; Ensure graceful recovery from interrupt (^C) and quits due to piping through
;;; head / less and then q / etc). Errors should be taken care of through the
;;; -b command argument

#+clozure
(embed lr1-parse-analysis-trees1
   (lambda (in out log-str)
      (handler-case (lr1-parse-analysis-trees1 in out log-str)
         (stream-error (cond)
            (format *error-output* "~%> Error of type ~A: ~A.~%" (type-of cond) cond)
            (finish-output *error-output*)
            (ccl:quit 1)))))
#+clozure
(setq ccl:*break-hook*
   #'(lambda (cond hook) (declare (ignore hook))
      (let ((cond-str (princ-to-string cond)))
         (format *error-output* "~%> Condition of type ~A: ~A.~%" (type-of cond) cond-str)
         (ccl:print-call-history :count 200 :stream *error-output*)
         (finish-output *error-output*)
         (ccl:quit 1))))

;;; SBCL: report the condition and exit with status 1 instead of entering the
;;; debugger (the CCL image does this through its -b option).
#+sbcl
(setf sb-ext:*invoke-debugger-hook*
   #'(lambda (cond hook) (declare (ignore hook))
      (format *error-output* "~%> Condition of type ~A: ~A.~%" (type-of cond) cond)
      (sb-debug:print-backtrace :count 50 :stream *error-output*)
      (finish-output *error-output*)
      (sb-ext:exit :code 1 :abort t)))


;;; Patches (if any, loaded in lexicographical order) and initialisation

(mapc #'(lambda (f) (load f :verbose nil))
   (sort
      (directory
         (merge-pathnames
            "patch*.lsp" ; c2s: a string, so that SBCL reads * as a wildcard
            (parse-namestring "$RASP/prob/")))
      #'string< :key #'namestring))
         

;;; Standard input (and output) should be
;;; "faithful", passing bytes through without interpretation - because we don't
;;; know the encoding of the input stream. This should work fine with the CCL
;;; default, which is for streams to have external format ISO-8859-1.
;;; SBCL's default is UTF-8, so give it ISO-8859-1 standard streams too.

#+sbcl
(setq *standard-input*
        (sb-sys:make-fd-stream 0 :input t :external-format :latin-1 :buffering :full)
      *standard-output*
        (sb-sys:make-fd-stream 1 :output t :external-format :latin-1 :buffering :full))


(progn $initforms)
EOF

if [ ! -r "$fsh" ]; then
  printf "$0: could not create temporary file '%s'\n" "$fsh" > /dev/stderr
  exit 1
fi

${gde} -e "(progn
(load \"$fsh\" :verbose nil)
(lr1-parse-analysis-trees *standard-input* *standard-output* \"$logfile\")
(finish-output *standard-output*)
(quit))"

parse_status=$?


# Remove temporary file

if [ $debug = "false" ]; then
  rm -rf "$fsh"
fi

exit $parse_status

