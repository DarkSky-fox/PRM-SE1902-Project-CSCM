import sys
import os
import subprocess
import shutil

def find_d2():
    if os.name == 'nt':
        common_paths = [
            r"C:\Program Files\D2\d2.exe",
            r"C:\Program Files (x86)\D2\d2.exe",
        ]
        for p in common_paths:
            if os.path.exists(p):
                return p
    else:
        home = os.path.expanduser("~")
        p = os.path.join(home, ".local", "bin", "d2")
        if os.path.exists(p) and os.access(p, os.X_OK):
            return p
            
    d2_path = shutil.which("d2")
    if d2_path:
        return d2_path
        
    return None

def main():
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print("Usage: python render.py <file.d2> [--png]", file=sys.stderr)
        sys.exit(2)
        
    src = sys.argv[1]
    want_png = len(sys.argv) == 3 and sys.argv[2] == "--png"
    
    if not os.path.exists(src):
        print(f"[ERROR] Không thấy file: {src}", file=sys.stderr)
        sys.exit(1)
        
    d2_bin = find_d2()
    if not d2_bin:
        print("[ERROR] Chưa cài d2. Vui lòng cài d2 từ d2lang.com", file=sys.stderr)
        sys.exit(1)
        
    svg = src.rsplit(".", 1)[0] + ".svg"
    
    cmd = [d2_bin, "--layout", "elk", "--theme", "1", "--pad", "40", src, svg]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print(f"[OK] SVG: {svg}")
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] D2 compile thất bại: {e.stderr}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
