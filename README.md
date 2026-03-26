# Python-CL: Python Implementation in Common Lisp

**🎯 Goal:** A Python interpreter implemented in Common Lisp, validated against the comprehensive [Python Language Reference Conformance Test Suite](https://github.com/soniccyclops-bot-collab/python-spec-test-suite).

**🔥 Why This Matters:**
- **Real Validation:** Our conformance suite has 1,412 tests covering ALL Python Language Reference sections
- **Cross-Implementation Proven:** Already validates CPython, PyPy, and GraalPy  
- **Lisp Power:** Leverage Lisp's metaprogramming for Python semantics
- **Academic Interest:** Study language implementation through different paradigms

## 🏗️ Architecture Design

### Core Implementation Strategy

**Python AST → Lisp S-expressions → Evaluation**

```lisp
;; Python: x = 42
;; AST: (assign (targets (name "x")) (value (num 42)))
;; Lisp: (py-assign 'x 42)

;; Python: def foo(x): return x + 1  
;; AST: (function-def "foo" (args (arg "x")) (body (return (binop (name "x") + (num 1)))))
;; Lisp: (py-defun 'foo '(x) (py-return (py-add (py-name 'x) 1)))
```

### Project Structure

```
python-cl/
├── src/
│   ├── parser/           # Python source → AST
│   │   ├── lexer.lisp   # Tokenization
│   │   ├── parser.lisp  # AST generation
│   │   └── ast.lisp     # AST node definitions
│   ├── compiler/        # AST → Lisp code
│   │   ├── ast2lisp.lisp # AST transformation
│   │   └── builtins.lisp # Python built-in functions
│   ├── runtime/         # Python execution environment
│   │   ├── objects.lisp  # Python object model
│   │   ├── scope.lisp    # LEGB scoping
│   │   └── eval.lisp     # Expression evaluation
│   └── python-cl.lisp   # Main interpreter interface
├── tests/
│   ├── unit/            # Unit tests for components
│   └── conformance/     # Python test suite integration
├── docs/                # Implementation documentation
├── examples/            # Example Python programs
└── README.md
```

## 🎯 Implementation Phases

### Phase 1: Minimal Viable Python (MVP)
**Target:** Pass basic conformance tests from Section 2 (Lexical Analysis)

**Features:**
- [x] Project structure setup
- [ ] Basic tokenization (numbers, identifiers, operators)
- [ ] Simple expression parsing
- [ ] Variable assignment and lookup
- [ ] Basic arithmetic operations
- [ ] Integration with conformance test runner

**Validation:** ~200 tests from Sections 2.1-2.6

### Phase 2: Expressions and Statements  
**Target:** Pass conformance tests from Sections 6-7

**Features:**
- [ ] Function definitions and calls
- [ ] Control flow (if/while/for)
- [ ] Exception handling
- [ ] List/dict/tuple literals
- [ ] Import system basics

**Validation:** ~600 additional tests

### Phase 3: Advanced Features
**Target:** Pass complete conformance test suite

**Features:**
- [ ] Classes and inheritance
- [ ] Generators and async/await
- [ ] Decorators
- [ ] Context managers
- [ ] Match statements (Python 3.10+)

**Validation:** All 1,412 conformance tests

### Phase 4: Performance and Polish
**Target:** Production-ready Python implementation

**Features:**
- [ ] Performance optimization
- [ ] Error message improvements
- [ ] Standard library compatibility
- [ ] Package manager integration

## 🧪 Conformance Test Integration

### Test Runner Architecture

```lisp
;; Integration with existing Python test suite
(defun run-conformance-tests ()
  "Run Python-CL against the comprehensive conformance test suite"
  (let ((test-suite-path "./tests/conformance/python-spec-test-suite/"))
    (run-python-tests test-suite-path :implementation 'python-cl)))

;; Example: Section 2.6 numeric literals
(deftest test-numeric-literals ()
  (assert (= (py-eval "42") 42))
  (assert (= (py-eval "3.14") 3.14))
  (assert (= (py-eval "2+3j") #C(2 3))))
```

### CI Integration

```yaml
name: Python-CL Conformance
on: [push, pull_request]

jobs:
  conformance:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Setup SBCL
      run: sudo apt-get install sbcl
    - name: Clone conformance test suite
      run: git clone https://github.com/soniccyclops-bot-collab/python-spec-test-suite.git tests/conformance/python-spec-test-suite
    - name: Run conformance tests
      run: make test-conformance
```

## 🚀 Getting Started

### Prerequisites
- **SBCL** (Steel Bank Common Lisp) or **CCL** (Clozure Common Lisp)
- **Quicklisp** for dependency management
- **Python 3.10+** for conformance test validation

### Quick Start

```bash
# Setup
git clone https://github.com/soniccyclops/python-cl.git
cd python-cl
make setup

# Run basic tests
make test

# Run conformance validation
make test-conformance

# Interactive development
sbcl --load python-cl.asd
* (in-package :python-cl)
* (py-eval "2 + 3")  ; => 5
```

## 🎯 Design Principles

### 1. **Conformance-Driven Development**
Every feature implementation guided by specific conformance test requirements. No guessing about Python semantics.

### 2. **Lisp Leverage** 
Use Lisp's strengths:
- **Metaprogramming:** Python AST transformations
- **REPL Development:** Interactive implementation
- **Condition System:** Python exception handling
- **Multiple Values:** Python tuple returns

### 3. **Incremental Validation**
Each implementation phase validated against growing subset of 1,412 conformance tests.

### 4. **Performance Awareness**
Design for reasonable performance while maintaining correctness. Optimization comes after conformance.

## 🏆 Success Metrics

### Technical Goals
- **100% Conformance:** Pass all 1,412 tests in the Python Language Reference test suite
- **Cross-Implementation Compatibility:** Join CPython, PyPy, GraalPy as validated implementations
- **Performance Target:** Within 10x of CPython performance for basic operations

### Educational Goals  
- **Language Implementation Study:** Document design decisions and trade-offs
- **Lisp Advocacy:** Demonstrate Lisp's power for language implementation
- **Open Source Contribution:** Provide reference implementation for Python semantics

## 📚 Resources

### Python Language Specification
- [Python Language Reference](https://docs.python.org/3/reference/)
- [Python Grammar](https://docs.python.org/3/reference/grammar.html)
- [Python AST Documentation](https://docs.python.org/3/library/ast.html)

### Implementation References
- **CPython:** Reference C implementation
- **PyPy:** Python-in-Python with JIT
- **GraalPy:** Oracle GraalVM implementation
- **Our Test Suite:** 1,412 comprehensive conformance tests

### Lisp Resources
- [Common Lisp HyperSpec](http://www.lispworks.com/documentation/HyperSpec/Front/)
- [Practical Common Lisp](http://www.gigamonkeys.com/book/)
- [Let Over Lambda](https://letoverlambda.com/)

## 🤝 Contributing

This project follows **test-driven development** using the conformance test suite:

1. **Choose a Language Reference section** not yet implemented
2. **Study the conformance tests** for that section  
3. **Implement the Lisp code** to pass those tests
4. **Validate** with `make test-section SECTION=X.Y`
5. **Document** design decisions and trade-offs

### Development Workflow

```bash
# Start with failing conformance tests
make test-section SECTION=2.6  # Numeric literals

# Implement until tests pass
edit src/parser/lexer.lisp
edit src/compiler/ast2lisp.lisp

# Validate implementation
make test-section SECTION=2.6

# Commit working implementation
git add . && git commit -m "Implement Section 2.6: Numeric literals (95 tests passing)"
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Building a Python interpreter in Common Lisp, validated by the most comprehensive Python conformance test suite ever created.**

*Why Python-CL? Because Python's beautiful syntax deserves Lisp's beautiful semantics.* ✨