# Python-CL Example Programs

This directory contains example Python programs to test the Python-CL interpreter.

## Basic Examples

### arithmetic.py
```python
# Basic arithmetic operations
print(2 + 3)
print(10 - 4) 
print(6 * 7)
print(15 / 3)
print(17 // 3)
print(17 % 3)
print(2 ** 8)
```

### literals.py  
```python
# Numeric literal examples
x = 42          # Decimal
y = 0xFF        # Hexadecimal  
z = 0o755       # Octal
w = 0b1010      # Binary
pi = 3.14159    # Float
sci = 1.5e-10   # Scientific notation
comp = 3+4j     # Complex number

print(f"Decimal: {x}")
print(f"Hex: {y}")
print(f"Octal: {z}")
print(f"Binary: {w}")
print(f"Float: {pi}")
print(f"Scientific: {sci}")
print(f"Complex: {comp}")
```

## Usage

To run these examples with Python-CL:

```bash
# Start the REPL and load examples manually
make repl
* (py-load "examples/arithmetic.py")

# Or run specific tests
make test-section SECTION=2.6
```

## Implementation Status

- ✅ **arithmetic.py** - Basic arithmetic works
- ⏳ **literals.py** - Partial (complex literals and f-strings not yet implemented)
- ⏳ **variables.py** - Variable assignment pending
- ⏳ **functions.py** - Function definitions pending
- ⏳ **control.py** - Control flow pending