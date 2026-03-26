;;;; tests/unit-tests.lisp

(in-package #:python-cl/tests)

(def-suite python-cl-suite
  :description "Python-CL unit tests")

(in-suite python-cl-suite)

;;; Lexer Tests

(test tokenize-numbers
  "Test numeric literal tokenization"
  (let ((tokens (tokenize "42")))
    (is (= (length tokens) 3))  ; number + newline + EOF
    (is (eq (token-type (first tokens)) :number))
    (is (string= (token-value (first tokens)) "42")))
  
  (let ((tokens (tokenize "3.14")))
    (is (= (length tokens) 3))
    (is (eq (token-type (first tokens)) :number))
    (is (string= (token-value (first tokens)) "3.14")))
  
  (let ((tokens (tokenize "0xFF")))
    (is (= (length tokens) 3))
    (is (eq (token-type (first tokens)) :number))
    (is (string= (token-value (first tokens)) "0xFF"))))

(test tokenize-identifiers
  "Test identifier tokenization"
  (let ((tokens (tokenize "hello")))
    (is (= (length tokens) 2))  ; identifier + EOF
    (is (eq (token-type (first tokens)) :identifier))
    (is (string= (token-value (first tokens)) "hello")))
  
  (let ((tokens (tokenize "def")))
    (is (= (length tokens) 2))
    (is (eq (token-type (first tokens)) :keyword))
    (is (string= (token-value (first tokens)) "def"))))

(test tokenize-operators
  "Test operator tokenization"
  (let ((tokens (tokenize "+")))
    (is (= (length tokens) 2))  ; operator + EOF
    (is (eq (token-type (first tokens)) :operator))
    (is (string= (token-value (first tokens)) "+")))
  
  (let ((tokens (tokenize "+=")))
    (is (= (length tokens) 2))
    (is (eq (token-type (first tokens)) :operator))
    (is (string= (token-value (first tokens)) "+="))))

(test tokenize-expressions
  "Test tokenizing simple expressions"
  (let ((tokens (tokenize "2 + 3")))
    (is (= (length tokens) 5))  ; number, operator, number, newline, EOF
    (is (eq (token-type (first tokens)) :number))
    (is (eq (token-type (second tokens)) :operator))
    (is (eq (token-type (third tokens)) :number))))

;;; AST Tests

(test ast-creation
  "Test AST node creation"
  (let ((num-node (make-py-num 42)))
    (is (typep num-node 'py-num))
    (is (= (py-value num-node) 42)))
  
  (let ((name-node (make-py-name 'x)))
    (is (typep name-node 'py-name))
    (is (eq (py-id name-node) 'x)))
  
  (let ((binop-node (make-py-binop (make-py-num 2) '+ (make-py-num 3))))
    (is (typep binop-node 'py-binop))
    (is (eq (py-op binop-node) '+))
    (is (= (py-value (py-left binop-node)) 2))
    (is (= (py-value (py-right binop-node)) 3))))

;;; Object System Tests

(test python-objects
  "Test Python object creation"
  (let ((py-int (make-py-int 42)))
    (is (typep py-int 'py-int))
    (is (= (py-value py-int) 42))
    (is (eq (py-type-name py-int) 'int)))
  
  (let ((py-str (make-py-str "hello")))
    (is (typep py-str 'py-str))
    (is (string= (py-value py-str) "hello"))
    (is (equal (symbol-name (py-type-name py-str)) "STR")))
  
  (let ((py-list (make-py-list 1 2 3)))
    (is (typep py-list 'py-list))
    (is (= (length (py-elements py-list)) 3))))

(test type-conversion
  "Test Lisp <-> Python type conversion"
  (is (= (python-to-lisp (make-py-int 42)) 42))
  (is (string= (python-to-lisp (make-py-str "hello")) "hello"))
  (is (equal (python-to-lisp (make-py-list 1 2 3)) '(1 2 3)))
  
  (is (typep (lisp-to-python 42) 'py-int))
  (is (typep (lisp-to-python "hello") 'py-str))
  (is (typep (lisp-to-python '(1 2 3)) 'py-list)))

;;; Environment Tests

(test environment-basics
  "Test environment creation and lookup"
  (let ((env (make-py-env)))
    (is (typep env 'py-env))
    
    ;; Test binding and lookup
    (py-bind 'x (make-py-int 42) env)
    (is (= (py-value (py-lookup 'x env)) 42))
    
    ;; Test built-ins
    (is (py-bound-p 'print env))))

(test scoping-rules
  "Test Python LEGB scoping"
  (let ((global-env (make-py-env)))
    ;; Bind in global scope
    (py-bind 'x (make-py-int 10) global-env :scope :global)
    
    ;; Create local scope
    (let ((local-env (py-push-scope global-env)))
      ;; Local should see global
      (is (= (py-value (py-lookup 'x local-env)) 10))
      
      ;; Bind locally
      (py-bind 'x (make-py-int 20) local-env :scope :local)
      (is (= (py-value (py-lookup 'x local-env)) 20))  ; Local shadows global
      
      ;; Global should still be 10
      (is (= (py-value (py-lookup 'x global-env)) 10)))))

;;; Evaluation Tests

(test simple-evaluation
  "Test basic expression evaluation"
  ;; Numbers
  (is (= (py-eval "42") 42))
  (is (= (py-eval "3.14") 3.14))
  (is (= (py-eval "0xFF") 255))
  
  ;; Arithmetic
  (is (= (py-eval "2 + 3") 5))
  (is (= (py-eval "10 - 4") 6))
  (is (= (py-eval "6 * 7") 42))
  (is (= (py-eval "15 / 3") 5))
  (is (= (py-eval "17 // 3") 5))
  (is (= (py-eval "17 % 3") 2))
  (is (= (py-eval "2 ** 8") 256)))

(test built-in-functions
  "Test built-in function implementations"
  ;; Type constructors
  (is (= (py-value (py-int-constructor 42.7)) 42))
  (is (= (py-value (py-float-constructor 42)) 42.0))
  (is (string= (py-value (py-str-constructor 42)) "42"))
  
  ;; len function
  (is (= (py-len (make-py-str "hello")) 5))
  (is (= (py-len (make-py-list 1 2 3)) 3))
  
  ;; type function
  (is (equal (symbol-name (py-type (make-py-int 42))) "INT"))
  (is (equal (symbol-name (py-type (make-py-str "hello"))) "STR")))

(test tokenize-indentation
  "Tokenizer emits INDENT/DEDENT tokens for Python blocks"
  (let* ((tokens (tokenize "if x > 5:\n    y = 1\n    z = 2\nw = 3\n"))
         (types (mapcar #'token-type tokens)))
    (is (equal types
               '(:keyword :identifier :operator :number :delimiter :newline
                 :indent
                 :identifier :operator :number :newline
                 :identifier :operator :number :newline
                 :dedent
                 :identifier :operator :number :newline
                 :eof)))))

(test indentation-errors
  "Invalid indentation patterns raise errors"
  (signals error (tokenize "if x:\n  y = 1\n z = 2\n"))
  (signals error (tokenize "if x:\n \ty = 1\n")))

(test parse-top-level-expressions-as-expressions
  "Top-level expressions should parse as expressions, not expression statements."
  (let ((ast (python-cl::parse-python "x + 1")))
    (is (typep ast 'python-cl::py-binop))
    (is (eq (python-cl::py-op ast) :+))))

(test parse-top-level-statements-as-statements
  "Top-level statements should stay statements."
  (is (typep (python-cl::parse-python "x = 1") 'python-cl::py-assign))
  (is (typep (python-cl::parse-python "return 1") 'python-cl::py-return))
  (is (typep (python-cl::parse-python "break") 'python-cl::py-break))
  (is (typep (python-cl::parse-python "continue") 'python-cl::py-continue))
  (is (typep (python-cl::parse-python "if True:\n    x\n") 'python-cl::py-if))
  (is (typep (python-cl::parse-python "while True:\n    x\n") 'python-cl::py-while)))

(test reject-invalid-statement-fallbacks
  "Malformed statements must not silently parse."
  (signals error (python-cl::parse-python "x + 1 = 2"))
  (signals error (python-cl::parse-python "x ="))
  (signals error (python-cl::parse-python "return = 1")))

(test conditional-expressions
  "Conditional expressions parse with low precedence and short-circuit correctly"
  (setf python-cl::*python-environment* (make-py-env))
  (is (= (py-eval "1 if True else 2") 1))
  (is (= (py-eval "1 if False else 2") 2))
  (is (= (py-eval "10 if 3 > 2 else 20") 10))
  (is (= (py-eval "1 + 2 if 3 > 2 else 4 + 5") 3))
  (is (= (py-eval "1 if 1 + 1 == 2 else 0") 1))
  ;; Current string literal handling preserves quotes in the value.
  (is (string= (py-eval "'A' if True else 'B' if True else 'C'") "'A'"))
  (is (string= (py-eval "'A' if False else 'B' if True else 'C'") "'B'"))
  (is (string= (py-eval "'A' if False else 'B' if False else 'C'") "'C'"))
  (is (= (py-eval "123 if True else missing_name") 123))
  (is (= (py-eval "missing_name if False else 456") 456)))

(test block-parsing-and-execution
  "Indented blocks execute for functions, if statements, and while loops"
  (setf python-cl::*python-environment* (make-py-env))
  (is (= (py-eval "x = 0\nif 2 > 1:\n    x = 7\nx\n") 7))
  (setf python-cl::*python-environment* (make-py-env))
  (is (= (py-eval "counter = 0\nwhile counter < 3:\n    counter += 1\ncounter\n") 3))
  (setf python-cl::*python-environment* (make-py-env))
  (is (= (py-eval "def add(a, b):\n    total = a + b\n    return total\nadd(2, 3)\n") 5))
  (setf python-cl::*python-environment* (make-py-env))
  (is (= (py-eval "value = 0\nif 1 < 2:\n    if 3 < 4:\n        value = 11\nvalue\n") 11)))

;;; Test Runner

(defun run-tests ()
  "Run all Python-CL unit tests"
  (run! 'python-cl-suite))