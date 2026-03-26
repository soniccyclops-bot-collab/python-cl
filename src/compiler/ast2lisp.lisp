;;;; compiler/ast2lisp.lisp - AST to Lisp code transformation

(in-package #:python-cl)

;;; AST to Lisp Code Generation

(defgeneric ast-to-lisp (node)
  (:documentation "Convert Python AST node to equivalent Lisp code"))

;; Literals
(defmethod ast-to-lisp ((node py-num))
  (py-value node))

(defmethod ast-to-lisp ((node py-str))
  `(make-py-str ,(py-value node)))

(defmethod ast-to-lisp ((node py-name))
  `(py-lookup ',(py-id node) *python-environment*))

;; Binary operations
(defmethod ast-to-lisp ((node py-binop))
  (let ((op-func (case (py-op node)
                   (+ 'py-add)
                   (- 'py-sub)
                   (* 'py-mul)
                   (/ 'py-div)
                   (/\/ 'py-floordiv)
                   (% 'py-mod)
                   (** 'py-power))))
    `(,op-func ,(ast-to-lisp (py-left node))
               ,(ast-to-lisp (py-right node)))))

;; Statements
(defmethod ast-to-lisp ((node py-assign))
  `(progn
     ,@(mapcar (lambda (target)
                 `(py-bind ',(py-id target) 
                           ,(ast-to-lisp (py-value node))
                           *python-environment*))
               (py-targets node))))

(defmethod ast-to-lisp ((node py-expr-stmt))
  (ast-to-lisp (py-value node)))

;;; Compilation Utilities

(defun compile-python-ast (ast)
  "Compile Python AST to executable Lisp code"
  (if (listp ast)
      `(progn ,@(mapcar #'ast-to-lisp ast))
      (ast-to-lisp ast)))

(defun compile-and-eval (ast)
  "Compile and evaluate Python AST"
  (eval (compile-python-ast ast)))