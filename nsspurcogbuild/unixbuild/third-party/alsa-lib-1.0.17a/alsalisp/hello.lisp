(princ "Hello ALSA world\n")
(princ "One " 1 "\n")
(princ "Two " (+ 1 1) "\n")

(defun myprinc (o) (progn (princ o)))
(myprinc "Printed via myprinc function!\n")
(unsetq myprinc)

(defun printnum (from to) (while (<= from to) (princ " " from) (setq from (+ from 1))))
(princ "Numbers 1-10: ") (printnum 1 10) (princ "\n")
(unsetq printnum)

(defun factorial (n) (if (> n 1) (* n (factorial (- n 1))) 1))
(princ "Factorial of 10: " (factorial 10) "\n")
(princ "Float test 1.1 + 1.35 = " (+ 1.1 1.35) "\n")
(princ "Factorial of 10.0: " (factorial 10.0) "\n")
(princ "Factorial of 20.0: " (factorial 20.0) "\n")
(unsetq factorial)

(setq alist '((one . first) (two . second) (three . third)))
(princ "alist = " alist "\n")
(princ "alist assoc one = " (assoc 'one alist) "\n")
(princ "alist rassoc third = " (rassoc 'third alist) "\n")
(unsetq alist)

(&stat-memory)
