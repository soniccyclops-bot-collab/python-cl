;;;; parser.lisp - Simple Python parser (MVP implementation)

(in-package #:python-cl)

;;; Simple Recursive Descent Parser

(defstruct parse-state
  tokens
  position
  current-token)

(defun operator-precedence (op-string)
  "Return precedence for Python operators (higher = tighter binding)"
  (case (intern (string-upcase op-string) :keyword)
    (:** 14)     ; Exponentiation (right associative)
    ((:* :/ :/\/ :%) 12) ; Multiplication, division, modulo
    ((:+ :-) 11) ; Addition, subtraction (binary context)
    ((:< :<= :> :>= :!= :==) 8) ; Comparisons
    (:AND 5)     ; Boolean AND
    (:OR 4)      ; Boolean OR
    (t 0)))      ; Unknown operators

(defun advance-token (state)
  "Advance to next token in parse state"
  (when (< (1+ (parse-state-position state)) (length (parse-state-tokens state)))
    (incf (parse-state-position state))
    (setf (parse-state-current-token state)
          (nth (parse-state-position state) (parse-state-tokens state))))
  (parse-state-current-token state))

(defun peek-token (state)
  "Look at current token without consuming it"
  (parse-state-current-token state))

(defun token-matches-p (state type &optional value)
  "Check if current token matches type and optional value"
  (let ((token (peek-token state)))
    (and token
         (eq (token-type token) type)
         (or (null value)
             (string= (token-value token) value)))))

(defun consume-token (state type &optional value)
  "Consume token if it matches, otherwise error"
  (if (token-matches-p state type value)
      (prog1 (peek-token state)
        (advance-token state))
      (error "Expected ~A~@[ with value ~A~], got ~A"
             type value (peek-token state))))

;;; Expression Parsing (Precedence Climbing)

(defun parse-expression (state)
  "Parse a Python expression"
  (parse-binary-op state 0))

(defun parse-binary-op (state min-precedence)
  "Parse binary operations with precedence climbing"
  (let ((left (parse-unary state)))
    (loop while (and (peek-token state)
                     (or (and (eq (token-type (peek-token state)) :operator)
                              (>= (operator-precedence (token-value (peek-token state))) min-precedence))
                         (and (eq (token-type (peek-token state)) :keyword)
                              (member (token-value (peek-token state)) '("and" "or") :test #'string=)
                              (>= (operator-precedence (token-value (peek-token state))) min-precedence))))
          do (let* ((op-token (if (eq (token-type (peek-token state)) :operator)
                                  (consume-token state :operator)
                                  (consume-token state :keyword)))
                    (op (intern (string-upcase (token-value op-token)) :python-cl))
                    (precedence (operator-precedence (token-value op-token)))
                    (right (parse-binary-op state (1+ precedence))))
               (setf left (make-py-binop left op right))))
    left))

(defun parse-unary (state)
  "Parse unary operations"
  (let ((token (peek-token state)))
    (if (and (eq (token-type token) :operator)
             (member (token-value token) '("+" "-" "~" "not") :test #'string=))
        ;; Unary operator
        (let* ((op-token (consume-token state :operator))
               (op (intern (string-upcase (token-value op-token)) :python-cl))
               (operand (parse-unary state)))  ; Right-associative
          (make-py-unaryop op operand))
        ;; Not a unary operator, parse primary
        (parse-primary state))))

(defun parse-primary (state)
  "Parse primary expressions (literals, names, parentheses)"
  (let ((token (peek-token state)))
    (cond
      ;; Numbers
      ((eq (token-type token) :number)
       (advance-token state)
       (let ((num-expr (make-py-num (token-value-as-number token))))
         (parse-postfix state num-expr)))
      
      ;; Strings
      ((eq (token-type token) :string)
       (advance-token state)
       (let ((str-expr (make-py-str (token-value token))))
         (parse-postfix state str-expr)))
      
      ;; Boolean literals
      ((and (eq (token-type token) :keyword)
            (member (token-value token) '("True" "False") :test #'string=))
       (advance-token state)
       (let ((bool-expr (make-py-bool (string= (token-value token) "True"))))
         (parse-postfix state bool-expr)))
      
      ;; Identifiers
      ((eq (token-type token) :identifier)
       (advance-token state)
       (let ((name-expr (make-py-name (token-value token))))
         (parse-postfix state name-expr)))
      
      ;; Parenthesized expressions
      ((token-matches-p state :delimiter "(")
       (consume-token state :delimiter "(")
       (let ((expr (parse-expression state)))
         (consume-token state :delimiter ")")
         (parse-postfix state expr)))
      
      (t (error "Unexpected token in expression: ~A" token))))

(defun parse-postfix (state expr)
  "Parse postfix operations like function calls"
  (loop while (token-matches-p state :delimiter "(")
        do (consume-token state :delimiter "(")
           (let ((args (parse-call-arguments state)))
             (consume-token state :delimiter ")")
             (setf expr (make-py-call expr args))))
  expr)

(defun parse-call-arguments (state)
  "Parse function call argument list"
  (let (args)
    (unless (token-matches-p state :delimiter ")")
      (loop
        (push (parse-expression state) args)
        (unless (token-matches-p state :delimiter ",")
          (return))
        (consume-token state :delimiter ",")))
    (reverse args)))

;;; Statement Parsing

(defun parse-statement (state)
  "Parse a Python statement"
  (let ((first-token (peek-token state)))
    (cond
      ;; Function definition
      ((and (eq (token-type first-token) :keyword)
            (string= (token-value first-token) "def"))
       (parse-function-def state))
      
      ;; If statement
      ((and (eq (token-type first-token) :keyword)
            (string= (token-value first-token) "if"))
       (parse-if-statement state))
      
      ;; While statement  
      ((and (eq (token-type first-token) :keyword)
            (string= (token-value first-token) "while"))
       (parse-while-statement state))
      
      ;; Return statement
      ((and (eq (token-type first-token) :keyword)
            (string= (token-value first-token) "return"))
       (parse-return-statement state))
      
      ;; Break statement
      ((and (eq (token-type first-token) :keyword)
            (string= (token-value first-token) "break"))
       (consume-token state :keyword "break")
       (make-py-break))
       
      ;; Continue statement
      ((and (eq (token-type first-token) :keyword)
            (string= (token-value first-token) "continue"))
       (consume-token state :keyword "continue")
       (make-py-continue))
      
      ;; Check for assignment: identifier = expression
      ((and (eq (token-type first-token) :identifier)
            (< (1+ (parse-state-position state)) (length (parse-state-tokens state)))
            (let ((next-token (nth (1+ (parse-state-position state)) (parse-state-tokens state))))
              (and next-token 
                   (eq (token-type next-token) :operator)
                   (string= (token-value next-token) "="))))
       (parse-assignment state))
      
      ;; Otherwise, parse as expression statement
      (t 
       (let ((expr (parse-expression state)))
         (make-py-expr-stmt expr))))))

(defun parse-if-statement (state)
  "Parse if statement with elif/else: if condition: body [elif condition: body]* [else: body]"
  (consume-token state :keyword "if")
  (let ((test (parse-expression state)))
    (consume-token state :delimiter ":")
    (let ((body (list (parse-statement state)))
          (orelse nil))
      
      ;; Parse elif/else chain
      (loop while (and (not (eq (token-type (peek-token state)) :eof))
                       (not (eq (token-type (peek-token state)) :newline))
                       (eq (token-type (peek-token state)) :keyword)
                       (member (token-value (peek-token state)) '("elif" "else") :test #'string=))
            do (cond
                 ;; elif: create nested if statement
                 ((string= (token-value (peek-token state)) "elif")
                  (consume-token state :keyword "elif")
                  (let ((elif-test (parse-expression state)))
                    (consume-token state :delimiter ":")
                    (let ((elif-body (list (parse-statement state))))
                      (setf orelse (list (make-py-if elif-test elif-body nil))))))
                 
                 ;; else: final body
                 ((string= (token-value (peek-token state)) "else")
                  (consume-token state :keyword "else")
                  (consume-token state :delimiter ":")
                  (setf orelse (list (parse-statement state)))
                  (return)))) ; else ends the chain
      
      (make-py-if test body orelse))))

(defun parse-while-statement (state)
  "Parse while statement: while condition: body"
  (consume-token state :keyword "while")
  (let ((test (parse-expression state)))
    (consume-token state :delimiter ":")
    ;; For now, parse single statement as body
    (let ((body (list (parse-statement state))))
      (make-py-while test body))))

(defun parse-function-def (state)
  "Parse function definition: def name(args): body"
  (consume-token state :keyword "def")
  (let ((name-token (consume-token state :identifier)))
    (consume-token state :delimiter "(")
    (let ((args (parse-argument-list state)))
      (consume-token state :delimiter ")")
      (consume-token state :delimiter ":")
      ;; For now, parse single statement as body
      (let ((body (list (parse-statement state))))
        (make-py-function-def (intern (string-upcase (token-value name-token)) :python-cl) 
                             args body))))))

(defun parse-argument-list (state)
  "Parse function argument list"
  (let (args)
    (unless (token-matches-p state :delimiter ")")
      (loop
        (let ((arg-token (consume-token state :identifier)))
          (push (intern (string-upcase (token-value arg-token)) :python-cl) args))
        (unless (token-matches-p state :delimiter ",")
          (return))
        (consume-token state :delimiter ",")))
    (reverse args)))

(defun parse-return-statement (state)
  "Parse return statement: return [expression]"
  (consume-token state :keyword "return")
  (if (or (eq (token-type (peek-token state)) :eof)
          (eq (token-type (peek-token state)) :newline))
      (make-py-return nil)  ; return with no value
      (make-py-return (parse-expression state))))

(defun parse-assignment (state)
  "Parse assignment statement: target = value"
  (let ((target (consume-token state :identifier)))
    (consume-token state :operator "=")
    (let ((value (parse-expression state)))
      (make-py-assign (list (make-py-name (token-value target))) value))))

;;; Top-level Parser Interface

(defun parse-tokens (tokens)
  "Parse tokens into an AST"
  (when (null tokens)
    (return-from parse-tokens nil))
  
  (let ((state (make-parse-state :tokens tokens
                                 :position 0
                                 :current-token (first tokens))))
    
    ;; Skip EOF tokens at the end
    (when (eq (token-type (peek-token state)) :eof)
      (return-from parse-tokens nil))
    
    ;; Try to parse as statement first, then as expression
    (handler-case
        (parse-statement state)
      (error ()
        ;; Fallback to expression parsing for backward compatibility
        (setf (parse-state-position state) 0
              (parse-state-current-token state) (first tokens))
        (parse-expression state)))))

(defun parse-python (source)
  "Parse Python source code into AST"
  (let ((tokens (tokenize source)))
    (parse-tokens tokens)))