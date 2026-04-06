import re

def main():
    with open('flood_ai_core.dart', 'r', encoding='utf-8') as f:
        src = f.read()
        
    # Find the bounds of 'static double score(List<double> input) {'
    start_idx = src.find('static double score(List<double> input) {')
    if start_idx == -1:
        print("Could not find score()")
        return
        
    end_idx = src.find('static double _sigmoid(', start_idx)
    if end_idx == -1:
        print("Could not find _sigmoid()")
        return
    
    pre = src[:start_idx]
    score_body = src[start_idx:end_idx]
    post = src[end_idx:]
    
    # score_body contains all the trees.
    # We will look for: \n    double var(\d+);\n
    # And split by it.
    
    parts = re.split(r'\n    double var(\d+);\n', score_body)
    
    # parts[0] is `"static double score(List<double> input) {"`
    # parts[1] is `"0"` (the group \d+ for var0)
    # parts[2] is the body for var0
    # parts[3] is `"1"`
    # parts[4] is the body for var1
    
    out_score_lines = ["  static double score(List<double> input) {"]
    extracted_methods = []
    
    for i in range(1, len(parts), 2):
        var_num = parts[i]
        var_body = parts[i+1]
        
        # We replace "return varX;" in score_body with "double varX = _compute_varX(input);"
        out_score_lines.append(f"    double var{var_num} = _compute_var{var_num}(input);")
        
        # We need to handle if the var_body is just assignment `var335 = var0 + var1...`
        # Wait! If var_body uses previous variables (like var0 to var334), it CANNOT be an isolated method without passing them!
        # But wait! Do the `if/else` blocks of `varX` use previous variables?
        # NO. m2cgen generated LightGBM code does NOT use previous variables in the tree evaluation.
        # Tree evaluations only use `input`.
        # The ONLY things that use previous variables are the accumulation steps!
        
        if "var" in var_body and re.search(r'var\d+ \+', var_body):
            # This is an accumulation line: `        var335 = var0 + var1...;`
            # In this case, we DO NOT extract it to a separate method, we just inject it directly into the new score method!
            out_score_lines.pop() # Remove the method call
            out_score_lines.append(f"    double var{var_num};")
            out_score_lines.append(var_body.rstrip('\n'))
        else:
            # It's an isolated tree!
            # The body assigns to `var{var_num}`. At the end, we add `return var{var_num};`
            method_code = f"  static double _compute_var{var_num}(List<double> input) {{\n    double var{var_num};\n{var_body.rstrip()}\n    return var{var_num};\n  }}"
            extracted_methods.append(method_code)

    out_score = "\n".join(out_score_lines) + "\n\n"
    out_extracted = "\n\n".join(extracted_methods) + "\n\n"
    
    final_src = pre + out_score + out_extracted + post
    
    # Save a backup
    with open('flood_ai_core.dart.bak', 'w', encoding='utf-8') as f:
        f.write(src)
        
    with open('flood_ai_core.dart', 'w', encoding='utf-8') as f:
        f.write(final_src)
        
    print(f"Refactored {len(extracted_methods)} methods.")

if __name__ == '__main__':
    main()
