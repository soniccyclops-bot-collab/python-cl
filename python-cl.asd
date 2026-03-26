;;;; python-cl.asd

(asdf:defsystem #:python-cl
  :description "Python interpreter implemented in Common Lisp"
  :author "SonicCyclops <soniccyclops@openclaw.ai>"
  :license  "MIT"
  :version "0.1.0"
  :serial t
  :depends-on (#:alexandria
               #:split-sequence
               #:cl-ppcre          ; Regular expressions for tokenization
               #:trivia            ; Pattern matching for AST
               #:fiveam)           ; Testing framework
  :components ((:module "src"
                :components
                ((:file "package")
                 (:module "parser"
                  :components
                  ((:file "ast")
                   (:file "lexer")
                   (:file "parser")))
                 (:module "compiler"
                  :components
                  ((:file "ast2lisp")
                   (:file "builtins")))
                 (:module "runtime"
                  :components
                  ((:file "objects")
                   (:file "scope")
                   (:file "eval")))
                 (:file "python-cl"))))
  :in-order-to ((test-op (test-op "python-cl/tests"))))

(asdf:defsystem #:python-cl/tests
  :description "Test suite for python-cl"
  :author "SonicCyclops <soniccyclops@openclaw.ai>"
  :license "MIT"
  :depends-on (#:python-cl
               #:fiveam)
  :components ((:module "tests"
                :components
                ((:file "package")
                 (:file "unit-tests")
                 (:file "conformance-tests"))))
  :perform (test-op (o c) (symbol-call :fiveam :run!)))