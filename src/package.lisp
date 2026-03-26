;;;; package.lisp

(defpackage #:python-cl
  (:use #:cl #:alexandria #:trivia)
  (:export
   ;; Main interpreter interface
   #:py-eval
   #:py-exec
   #:py-load
   
   ;; AST node types
   #:py-ast-node
   #:py-expr
   #:py-stmt
   #:py-num
   #:py-name
   #:py-binop
   #:py-assign
   #:py-function-def
   
   ;; Runtime objects
   #:py-object
   #:py-int
   #:py-float
   #:py-complex
   #:py-str
   #:py-list
   #:py-dict
   #:py-function
   
   ;; Built-in functions
   #:py-print
   #:py-len
   #:py-type
   
   ;; Scope and environment
   #:py-env
   #:py-lookup
   #:py-bind
   
   ;; Conformance test integration
   #:run-conformance-tests
   #:test-section))

(defpackage #:python-cl/tests
  (:use #:cl #:python-cl #:fiveam)
  (:export #:run-tests))