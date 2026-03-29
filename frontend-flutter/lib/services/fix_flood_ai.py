#!/usr/bin/env python3
"""Fix two corruption areas in the auto-generated flood_ai_core.dart file."""

import sys

DART_FILE = "flood_ai_core.dart"

with open(DART_FILE, "r", encoding="utf-8") as f:
    content = f.read()

original_len = len(content)

# ---- Fix 1: Header corruption (lines 1-9) ----
# The auto-generated code has an `import` and duplicate signature inside the method body.
OLD_HEADER = (
    "// Tự động phân tách từ file Python bằng m2cgen.\r\n"
    "// Lõi AI LightGBM (Edge) dự báo Ngập Lụt\r\n"
    "\r\n"
    "class FloodAICore {\r\n"
    "  /// Predict hàm lõi (LightGBM Score)\r\n"
    "  /// Trả về điểm Raw (Chưa can thiệp sigmoid/isotonic)\r\n"
    "  static double score(List<double> input) {\r\n"
    "import 'dart:math';\r\n"
    "List<double> score(List<double> input) {"
)

NEW_HEADER = (
    "// Tự động phân tách từ file Python bằng m2cgen.\r\n"
    "// Lõi AI LightGBM (Edge) dự báo Ngập Lụt\r\n"
    "\r\n"
    "import 'dart:math' as math;\r\n"
    "\r\n"
    "class FloodAICore {\r\n"
    "  /// Predict hàm lõi (LightGBM Score)\r\n"
    "  /// Trả về điểm Raw (Chưa can thiệp sigmoid/isotonic)\r\n"
    "  static double score(List<double> input) {"
)

if OLD_HEADER in content:
    content = content.replace(OLD_HEADER, NEW_HEADER, 1)
    print("✓ Fix 1 (header) applied.")
else:
    print("✗ Fix 1 (header) NOT found — check manually.")
    sys.exit(1)

# ---- Fix 2: End-of-file corruption (around lines 96200-96222) ----
# The sigmoid helper and return value are broken / outside class scope.
OLD_TAIL = (
    "    return [1.0 - var801, var801];\r\n"
    "}\r\n"
    "double sigmoid(double x) {\r\n"
    "    if (x < 0.0) {\r\n"
    "        double z = exp(x);\r\n"
    "        return z / (1.0 + z);\r\n"
    "    }\r\n"
    "    return 1.0 / (1.0 + exp(-x));\r\n"
    "}\r\n"
    "\r\n"
    "  }\r\n"
    "\r\n"
    "  /// Trả về Xác Suất xấp xỉ Prob [0, 1]\r\n"
    "  /// Tương đương Isotonic / Sigmoid\r\n"
    "  static double predictProb(List<double> input) {\r\n"
    "    double raw = score(input);\r\n"
    "    // Logistic scale\r\n"
    "    return 1.0 / (1.0 + (3.14159 / (raw.abs() + 0.1)));\r\n"
    "  }\r\n"
    "}\r\n"
)

NEW_TAIL = (
    "    return var801;\r\n"
    "  }\r\n"
    "\r\n"
    "  static double _sigmoid(double x) {\r\n"
    "    if (x < 0.0) {\r\n"
    "      final double z = math.exp(x);\r\n"
    "      return z / (1.0 + z);\r\n"
    "    }\r\n"
    "    return 1.0 / (1.0 + math.exp(-x));\r\n"
    "  }\r\n"
    "\r\n"
    "  /// Trả về Xác Suất xấp xỉ Prob [0, 1]\r\n"
    "  /// Tương đương Isotonic / Sigmoid\r\n"
    "  static double predictProb(List<double> input) {\r\n"
    "    final double raw = score(input);\r\n"
    "    // Logistic scale\r\n"
    "    return 1.0 / (1.0 + (3.14159 / (raw.abs() + 0.1)));\r\n"
    "  }\r\n"
    "}\r\n"
)

if OLD_TAIL in content:
    content = content.replace(OLD_TAIL, NEW_TAIL, 1)
    print("✓ Fix 2 (tail / sigmoid) applied.")
else:
    print("✗ Fix 2 (tail) NOT found — check manually.")
    sys.exit(1)

# Also fix the sigmoid() call inside score() to use _sigmoid()
OLD_CALL = "    var801 = sigmoid("
NEW_CALL = "    var801 = _sigmoid("
if OLD_CALL in content:
    content = content.replace(OLD_CALL, NEW_CALL, 1)
    print("✓ Fix 3 (sigmoid → _sigmoid call) applied.")
else:
    print("✗ Fix 3 (sigmoid call) NOT found — check manually.")
    sys.exit(1)

with open(DART_FILE, "w", encoding="utf-8") as f:
    f.write(content)

print(f"\nDone. File written ({len(content)} bytes, was {original_len} bytes).")
