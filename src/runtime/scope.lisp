;;;; runtime/scope.lisp - Python scoping (LEGB) implementation

(in-package #:python-cl)

;;; Python Environment (LEGB Scoping)

(defclass py-env ()
  ((local :initarg :local
          :accessor py-local
          :initform (make-hash-table :test 'eq)
          :documentation "Local scope variables")
   (enclosing :initarg :enclosing
              :accessor py-enclosing
              :initform nil
              :type (or py-env null)
              :documentation "Enclosing scope (for closures)")
   (global :initarg :global
           :accessor py-global
           :initform nil
           :type (or hash-table null)
           :documentation "Global scope variables")
   (builtin :initarg :builtin
            :accessor py-builtin
            :initform (make-hash-table :test 'eq)
            :documentation "Built-in scope variables")))

(defun make-py-env (&key enclosing global)
  "Create a new Python environment"
  (let ((env (make-instance 'py-env 
                            :enclosing enclosing
                            :global (or global (make-hash-table :test 'eq)))))
    ;; Initialize built-ins
    (initialize-builtins env)
    env))

(defun initialize-builtins (env)
  "Initialize built-in functions and constants in environment"
  (let ((builtins (py-builtin env)))
    ;; Built-in constants
    (setf (gethash 'none builtins) nil)
    (setf (gethash 'true builtins) (make-py-int 1))
    (setf (gethash 'false builtins) (make-py-int 0))
    
    ;; Built-in functions (will be implemented in builtins.lisp)
    (setf (gethash 'print builtins) #'py-print)
    (setf (gethash 'len builtins) #'py-len)
    (setf (gethash 'type builtins) #'py-type)
    (setf (gethash 'int builtins) #'py-int-constructor)
    (setf (gethash 'float builtins) #'py-float-constructor)
    (setf (gethash 'str builtins) #'py-str-constructor)
    (setf (gethash 'list builtins) #'py-list-constructor)))

;;; Variable Lookup (LEGB Order)

(defun py-lookup (name env)
  "Look up a variable using Python's LEGB scoping rules"
  (let ((symbol-name (if (symbolp name) name (intern (string-upcase name)))))
    (or
     ;; L - Local scope
     (multiple-value-bind (value exists-p)
         (gethash symbol-name (py-local env))
       (when exists-p value))
     
     ;; E - Enclosing scope (closures)
     (when (py-enclosing env)
       (handler-case
           (py-lookup symbol-name (py-enclosing env))
         (py-name-error () nil)))
     
     ;; G - Global scope  
     (multiple-value-bind (value exists-p)
         (gethash symbol-name (py-global env))
       (when exists-p value))
     
     ;; B - Built-in scope
     (multiple-value-bind (value exists-p)
         (gethash symbol-name (py-builtin env))
       (when exists-p value))
     
     ;; Not found - raise NameError
     (error 'py-name-error :name symbol-name))))

(defun py-bind (name value env &key (scope :local))
  "Bind a variable in the specified scope"
  (let ((symbol-name (if (symbolp name) name (intern (string-upcase name)))))
    (case scope
      (:local (setf (gethash symbol-name (py-local env)) value))
      (:global (setf (gethash symbol-name (py-global env)) value))
      (:builtin (setf (gethash symbol-name (py-builtin env)) value))
      (t (error "Invalid scope: ~A" scope))))
  value)

(defun py-bound-p (name env &key (scope :all))
  "Check if a variable is bound in the specified scope"
  (let ((symbol-name (if (symbolp name) name (intern (string-upcase name)))))
    (case scope
      (:local (nth-value 1 (gethash symbol-name (py-local env))))
      (:global (nth-value 1 (gethash symbol-name (py-global env))))
      (:builtin (nth-value 1 (gethash symbol-name (py-builtin env))))
      (:all (handler-case
                (progn (py-lookup symbol-name env) t)
              (py-name-error () nil))))))

;;; Scope Management

(defun py-push-scope (env)
  "Create a new local scope (for function calls, etc.)"
  (make-py-env :enclosing env :global (py-global env)))

(defun py-pop-scope (env)
  "Return to the enclosing scope"
  (or (py-enclosing env)
      (error "Cannot pop from top-level scope")))

(defmacro with-py-scope (env &body body)
  "Execute body with a new Python scope"
  (let ((new-env-sym (gensym "NEW-ENV")))
    `(let ((,new-env-sym (py-push-scope ,env)))
       (unwind-protect
           (let ((,env ,new-env-sym))
             ,@body)
         ;; Cleanup if needed
         ))))

;;; Scope Introspection

(defun py-locals (env)
  "Return local variables as a Python dict (like locals())"
  (let ((result (make-py-dict)))
    (maphash (lambda (name value)
               (setf (gethash name (py-table result)) value))
             (py-local env))
    result))

(defun py-globals (env)
  "Return global variables as a Python dict (like globals())"
  (let ((result (make-py-dict)))
    (maphash (lambda (name value)
               (setf (gethash name (py-table result)) value))
             (py-global env))
    result))

;;; Exception Types

(define-condition py-name-error (error)
  ((name :initarg :name :reader py-error-name))
  (:report (lambda (condition stream)
             (format stream "NameError: name '~A' is not defined" 
                     (py-error-name condition)))))

(define-condition py-unbound-local-error (py-name-error)
  ()
  (:report (lambda (condition stream)
             (format stream "UnboundLocalError: local variable '~A' referenced before assignment"
                     (py-error-name condition)))))

;;; Environment Debugging

(defun print-py-env (env &optional (stream t))
  "Print the contents of a Python environment for debugging"
  (format stream "Python Environment:~%")
  
  (format stream "  Local scope (~A variables):~%" 
          (hash-table-count (py-local env)))
  (maphash (lambda (name value)
             (format stream "    ~A = ~A~%" name value))
           (py-local env))
  
  (when (py-enclosing env)
    (format stream "  Has enclosing scope~%"))
  
  (format stream "  Global scope (~A variables):~%"
          (hash-table-count (py-global env)))
  (maphash (lambda (name value)
             (format stream "    ~A = ~A~%" name value))
           (py-global env))
  
  (format stream "  Built-in scope (~A variables):~%"
          (hash-table-count (py-builtin env)))
  (maphash (lambda (name value)
             (format stream "    ~A = ~A~%" name value))
           (py-builtin env)))