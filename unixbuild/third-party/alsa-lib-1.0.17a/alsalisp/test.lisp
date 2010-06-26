;
; Test code for all basic alsa lisp commands.
; The test is indended to find memory leaks.
;
; Copyright (c) 2003 Jaroslav Kysela <perex@perex.cz>
; License: GPL v2 (http://www.gnu.org/licenses/gpl.html)
;

;
; Basic commands
;

(!=)				(&check-memory)
(!= 0)				(&check-memory)
(!= 0 1)			(&check-memory)
(!= 1 1)			(&check-memory)
(!= 0 1 2)			(&check-memory)
(!= 'aaaa 'bbbb)		(&check-memory)

(%)				(&check-memory)
(% 11)				(&check-memory)
(% 11 5)			(&check-memory)
(% 11.5 5.1)			(&check-memory)
(% 11.5 5.1 2.2)		(&check-memory)
(% 'aaaa 'bbbb)			(&check-memory)

(&check-memory)			(&check-memory)
(&check-memory "abcd")		(&check-memory)
(&dump-memory "-")		(&check-memory)
(&dump-memory)			(&check-memory)
(&dump-objects "-")		(&check-memory)
(&dump-objects)			(&check-memory)
(&stat-memory)			(&check-memory)
(&stat-memory "abcd")		(&check-memory)

(*)				(&check-memory)
(* 1)				(&check-memory)
(* 1 2)				(&check-memory)
(* 1.1 2.2)			(&check-memory)
(* 1.1 2.2 3.3)			(&check-memory)
(* 'aaaa)			(&check-memory)

(+)				(&check-memory)
(+ 1)				(&check-memory)
(+ 1 2)				(&check-memory)
(+ 1.1 2.2)			(&check-memory)
(+ 1.1 2.2 3.3)			(&check-memory)
(+ 'aaaa)			(&check-memory)
(+ 'aaaa 'bbbb)			(&check-memory)
(+ "aaaa")			(&check-memory)
(+ "aaaa" "bbbb")		(&check-memory)
(+ "aaaa" "bbbb" "cccc")	(&check-memory)

(-)				(&check-memory)
(- 1)				(&check-memory)
(- 1 2)				(&check-memory)
(- 1.1 2.2)			(&check-memory)
(- 1.1 2.2 3.3)			(&check-memory)
(- 'aaaa)			(&check-memory)
(- 'aaaa 'bbbb)			(&check-memory)

(/)				(&check-memory)
(/ 1)				(&check-memory)
(/ 1 2)				(&check-memory)
(/ 1.1 2.2)			(&check-memory)
(/ 1.1 2.2 3.3)			(&check-memory)
(/ 'aaaa)			(&check-memory)
(/ 'aaaa 'bbbb)			(&check-memory)

(<)				(&check-memory)
(< 0)				(&check-memory)
(< 0 1)				(&check-memory)
(< 1 0)				(&check-memory)
(< 0 1 2)			(&check-memory)

(<=)				(&check-memory)
(<= 0)				(&check-memory)
(<= 0 1)			(&check-memory)
(<= 1 0)			(&check-memory)
(<= 0 1 2)			(&check-memory)

(=)				(&check-memory)
(= 0)				(&check-memory)
(= 0 1)				(&check-memory)
(= 1 1)				(&check-memory)
(= 0 1 2)			(&check-memory)

(>)				(&check-memory)
(> 0)				(&check-memory)
(> 0 1)				(&check-memory)
(> 1 0)				(&check-memory)
(> 0 1 2)			(&check-memory)

(>= 0)				(&check-memory)
(>= 0 1)			(&check-memory)
(>= 1 0)			(&check-memory)
(>= 0 1 2)			(&check-memory)

(and)				(&check-memory)
(and 0)				(&check-memory)
(and 1)				(&check-memory)
(and 0 0 0)			(&check-memory)

(quote a)			(&check-memory)

(assoc)							(&check-memory)
(assoc 'one)						(&check-memory)
(assoc 'one '((one . first)))				(&check-memory)
(assoc 'one '((two . second)))				(&check-memory)
(assoc 'one '((one . first) (two . second)))		(&check-memory)

(assq)							(&check-memory)
(assq 'one)						(&check-memory)
(assq "one" '(("one" . "first")))			(&check-memory)
(assq "one" '(("two" . "second")))			(&check-memory)
(assq "one" '(("one" . "first") ("two" . "second")))	(&check-memory)

(atom)				(&check-memory)
(atom 'one)			(&check-memory)
(atom "one")			(&check-memory)
(atom "one" 'two)		(&check-memory)

(funcall)			(&check-memory)

(car)				(&check-memory)
(car '(one . two))		(&check-memory)

(cdr)				(&check-memory)
(cdr '(one . two))		(&check-memory)

(concat)			(&check-memory)
(concat 'aaaa)			(&check-memory)
(concat 'aaaa 'bbbb)		(&check-memory)
(concat "aaaa")			(&check-memory)
(concat "aaaa" "bbbb")		(&check-memory)
(concat "aaaa" "bbbb" "cccc")	(&check-memory)

(cond)				(&check-memory)
(cond 0)			(&check-memory)
(cond 0 1)			(&check-memory)
(cond 0 1 2)			(&check-memory)
(cond 0 1 2 3)			(&check-memory)
(cond (0 'a) (1 'b) (0 'd))	(&check-memory)
(cond 1)			(&check-memory)
(cond 1 1)			(&check-memory)
(cond 1 1 2)			(&check-memory)
(cond 1 1 2 3)			(&check-memory)

(cons)				(&check-memory)
(cons "a")			(&check-memory)
(cons "a" "b")			(&check-memory)
(cons "a" "b" "c")		(&check-memory)

(eq)				(&check-memory)
(eq 1)				(&check-memory)
(eq 0 0)			(&check-memory)
(eq "a" "b")			(&check-memory)
(eq "a" "b" "c")		(&check-memory)

(equal)				(&check-memory)
(equal 1)			(&check-memory)
(equal 0 0)			(&check-memory)
(equal "a" "b")			(&check-memory)
(equal "a" "b" "c")		(&check-memory)

(exfun)				(&check-memory)
(exfun 'abcd)			(&check-memory)
(exfun 'abcd 'ijkl)		(&check-memory)

(format)			(&check-memory)
(format 1)			(&check-memory)
(format 'a)			(&check-memory)
(format "a" "b" "c")		(&check-memory)
(format "1.2")			(&check-memory)
(format "%c" 43)		(&check-memory)
(format "%d" 12)		(&check-memory)
(format "%i" 12)		(&check-memory)
(format "%f" 12.1)		(&check-memory)
(format "%s" "abcd")		(&check-memory)
(format "%s %i %i" "abcd" 1 2)	(&check-memory)

(garbage-collect)		(&check-memory)
(gc)				(&check-memory)

(if)				(&check-memory)
(if t)				(&check-memory)
(if t 'a)			(&check-memory)
(if t 'a 'b)			(&check-memory)
(if nil)			(&check-memory)
(if nil 'a)			(&check-memory)
(if nil 'a 'b)			(&check-memory)

(include "itest.lisp")		(&check-memory)

(list)				(&check-memory)
(list "a")			(&check-memory)
(list "a" "b")			(&check-memory)
(list "a" "b" "c")		(&check-memory)

(not)				(&check-memory)
(not 0)				(&check-memory)
(not nil)			(&check-memory)
(not t)				(&check-memory)
(not 'a)			(&check-memory)
(not 'a 'b 'c 'd)		(&check-memory)

(nth)				(&check-memory)
(nth 2)				(&check-memory)
(nth 2 nil)			(&check-memory)
(nth 2 '(('one 'two 'three)))	(&check-memory)

(null)				(&check-memory)
(null 0)			(&check-memory)
(null nil)			(&check-memory)
(null t)			(&check-memory)
(null 'a)			(&check-memory)
(null 'a 'b 'c 'd)		(&check-memory)

(or)				(&check-memory)
(or 0)				(&check-memory)
(or 1)				(&check-memory)
(or 0 0 0)			(&check-memory)

(path)				(&check-memory)
(path 0)			(&check-memory)
(path 1)			(&check-memory)
(path 0 0 0)			(&check-memory)
(path "data")			(&check-memory)

(princ)				(&check-memory)
(princ "\nabcd\n")		(&check-memory)
(princ "a" "b" "c\n")		(&check-memory)

(prog1)				(&check-memory)
(prog1 1)			(&check-memory)
(prog1 1 2 3 4)			(&check-memory)

(prog2)				(&check-memory)
(prog2 1)			(&check-memory)
(prog2 1 2 3 4)			(&check-memory)

(progn)				(&check-memory)
(progn 1)			(&check-memory)
(progn 1 2 3 4)			(&check-memory)

(quote)				(&check-memory)
(quote a)			(&check-memory)

(rassoc)						(&check-memory)
(rassoc 'first)						(&check-memory)
(rassoc 'first '((one . first)))			(&check-memory)
(rassoc 'first '((two . second)))			(&check-memory)
(rassoc 'first '((one . first) (two . second)))		(&check-memory)

(rassq)							(&check-memory)
(rassq "first")						(&check-memory)
(rassq "first" '(("one" . "first")))			(&check-memory)
(rassq "first" '(("two" . "second")))			(&check-memory)
(rassq "first" '(("one" . "first") ("two" . "second")))	(&check-memory)

(set)				(&check-memory)
(set "a") (unset "a")		(&check-memory)
(set "a" 1) (unset "a")		(&check-memory)
(set a 1) (unset a)		(&check-memory)
(set "a" 1 2) (unset "a")	(&check-memory)

(setf)				(&check-memory)
(setf a) (unsetf a)		(&check-memory)
(setf a 1) (unsetf a)		(&check-memory)
(setf a 1 2) (unsetf a)		(&check-memory)

(setq)				(&check-memory)
(setq a) (unsetq a)		(&check-memory)
(setq a 1) (unsetq a)		(&check-memory)
(setq a 1 2) (unsetq a)		(&check-memory)

(string-equal)			(&check-memory)
(string-equal 1)		(&check-memory)
(string-equal "a")		(&check-memory)
(string-equal "a" "a")		(&check-memory)
(string-equal "a" "b")		(&check-memory)
(string-equal "a" "b" "c")	(&check-memory)

(string-to-integer)		(&check-memory)
(string-to-integer 1)		(&check-memory)
(string-to-integer 1.5)		(&check-memory)
(string-to-integer "a")		(&check-memory)
(string-to-integer "a" "a")	(&check-memory)
(string-to-integer "a" "b")	(&check-memory)
(string-to-integer "a" "b" "c")	(&check-memory)

(string-to-float)		(&check-memory)
(string-to-float 1)		(&check-memory)
(string-to-float 1.5)		(&check-memory)
(string-to-float "a")		(&check-memory)
(string-to-float "a" "a")	(&check-memory)
(string-to-float "a" "b")	(&check-memory)
(string-to-float "a" "b" "c")	(&check-memory)

(string=)			(&check-memory)
(string= 1)			(&check-memory)
(string= "a")			(&check-memory)
(string= "a" "a")		(&check-memory)
(string= "a" "b")		(&check-memory)
(string= "a" "b" "c")		(&check-memory)

(unless)			(&check-memory)
(unless 1)			(&check-memory)
(unless 0 1 2)			(&check-memory)
(unless t 2 3 4)		(&check-memory)
(unless nil 2 3 4)		(&check-memory)

(unset)				(&check-memory)
(unset "a")			(&check-memory)

(unsetf)			(&check-memory)
(unsetf a)			(&check-memory)
(unsetf a b)			(&check-memory)

(unsetq)			(&check-memory)
(unsetq a)			(&check-memory)
(unsetq a b)			(&check-memory)

(when)				(&check-memory)
(when 0)			(&check-memory)
(when 0 1)			(&check-memory)
(when t 1)			(&check-memory)
(when nil 1)			(&check-memory)

(while)				(&check-memory)
(while nil)			(&check-memory)
(while nil 1)			(&check-memory)
(while nil 1 2 3 4)		(&check-memory)

;
; more complex command sequences
;

(setq abcd "abcd")
(unsetq abcd)
(&check-memory)

(setq abcd (("abcd" . "efgh") ("1234" . "5678")))
(unsetq abcd)
(&check-memory)

(defun myfun () (princ "a\n"))
(exfun 'myfun)
(unsetq myfun)
(&check-memory)

(defun myfun () (princ "a\n"))
(funcall 'myfun)
(funcall 'myfun 'aaaaa)
(unsetq myfun)
(&check-memory)

(defun myfun (o) (princ o "a\n"))
(funcall 'myfun)
(funcall 'myfun 'aaaaa)
(unsetq myfun)
(&check-memory)

(defun myfun (o p) (princ o p "\n"))
(funcall 'myfun)
(funcall 'myfun 'aaaaa)
(funcall 'myfun 'aaaaa 'bbbbb)
(unsetq myfun)
(&check-memory)

(defun printnum (from to) (while (<= from to) (princ " " from) (setq from (+ from 1))))
(princ "Numbers 1-10:") (printnum 1 10) (princ "\n")
(unsetq printnum)

;
; game over
;

(princ "*********************\n")
(princ "OK, all tests passed!\n")
(princ "*********************\n")
(&stat-memory)
