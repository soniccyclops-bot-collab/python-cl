;;;; tests/package.lisp

(defpackage #:python-cl/tests
  (:use #:cl #:python-cl #:fiveam)
  (:export #:run-tests #:python-cl-suite))