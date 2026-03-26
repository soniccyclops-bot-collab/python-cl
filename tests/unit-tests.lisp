;;;; tests/unit-tests.lisp

(in-package #:python-cl/tests)

(def-suite python-cl-suite
  :description "Python-CL unit tests")

(in-suite python-cl-suite)

;;; Lexer Tests

(test tokenize-numbers
  "Test numeric literal tokenization"
  (let ((tokens (tokenize "42")))
    (is (= (length tokens) 2))  ; number + EOF
    (is (eq (token-type (first tokens)) :number))
    (is (string= (token-value (first tokens)) "42")))
  
  (let ((tokens (tokenize "3.14")))
    (is (= (length tokens) 2))
    (is (eq (token-type (first tokens)) :number))
    (is (string= (token-value (first tokens)) "3.14")))
  
  (let ((tokens (tokenize "0xFF")))
    (is (= (length tokens) 2))
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
    (is (= (length tokens) 4))  ; number, operator, number, EOF
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
    (is (eq (py-type-name py-str) 'str)))
  
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
  (is (eq (py-type (make-py-int 42)) 'int))
  (is (eq (py-type (make-py-str "hello")) 'str)))

;;; Test Runner

(defun run-tests ()
  "Run all Python-CL unit tests"
  (run! 'python-cl-suite))