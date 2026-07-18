import sys
import os
import zlib
import urllib.request
import urllib.error

_ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"

def _encode6bit(b):
    return _ALPHABET[b & 0x3F]

def _append3bytes(b1, b2, b3):
    c1 = b1 >> 2
    c2 = ((b1 & 0x3) << 4) | (b2 >> 4)
    c3 = ((b2 & 0xF) << 2) | (b3 >> 6)
    c4 = b3 & 0x3F
    return _encode6bit(c1) + _encode6bit(c2) + _encode6bit(c3) + _encode6bit(c4)

def encode_plantuml(data: bytes) -> str:
    out = []
    for i in range(0, len(data), 3):
        chunk = data[i:i + 3]
        b1 = chunk[0]
        b2 = chunk[1] if len(chunk) > 1 else 0
        b3 = chunk[2] if len(chunk) > 2 else 0
        out.append(_append3bytes(b1, b2, b3))
    return "".join(out)

def main():
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print("Usage: python render.py <file.puml> [--png]", file=sys.stderr)
        sys.exit(2)
        
    src = sys.argv[1]
    want_png = len(sys.argv) == 3 and sys.argv[2] == "--png"
    
    if not os.path.exists(src):
        print(f"[ERROR] Không thấy file: {src}", file=sys.stderr)
        sys.exit(1)
        
    svg = src.rsplit(".", 1)[0] + ".svg"
    
    with open(src, "rb") as f:
        text = f.read()
        
    try:
        compressed = zlib.compress(text, 9)[2:-4]
        encoded = encode_plantuml(compressed)
    except Exception as e:
        print(f"[ERROR] Encode PlantUML thất bại: {e}", file=sys.stderr)
        sys.exit(1)
        
    url = f"https://www.plantuml.com/plantuml/svg/{encoded}"
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'})
        with urllib.request.urlopen(req, timeout=20) as response:
            if response.status != 200:
                print(f"[ERROR] Render PlantUML thất bại (HTTP {response.status})", file=sys.stderr)
                sys.exit(1)
            svg_data = response.read()
    except urllib.error.HTTPError as e:
        print(f"[ERROR] Render PlantUML thất bại (HTTP {e.code})", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"[ERROR] Kết nối tới server PlantUML thất bại: {e}", file=sys.stderr)
        sys.exit(1)
        
    if len(svg_data) < 200:
        print(f"[WARNING] SVG trả về bất thường nhỏ ({len(svg_data)} bytes) — khả năng cao cú pháp .puml lỗi.", file=sys.stderr)
        sys.exit(1)
        
    svg_text = svg_data.decode("utf-8", errors="ignore")
    if "Syntax Error" in svg_text or "An error has occured" in svg_text or "cannot find message" in svg_text:
        print("[ERROR] PlantUML báo lỗi cú pháp trong SVG (server trả 200 nhưng nội dung là thông báo lỗi).", file=sys.stderr)
        with open(svg, "wb") as f:
            f.write(svg_data)
        sys.exit(1)
        
    with open(svg, "wb") as f:
        f.write(svg_data)
    print(f"[OK] SVG: {svg} (qua plantuml.com)")
    
    if want_png:
        png = src.rsplit(".", 1)[0] + ".png"
        png_url = f"https://www.plantuml.com/plantuml/png/{encoded}"
        try:
            req_png = urllib.request.Request(png_url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'})
            with urllib.request.urlopen(req_png, timeout=20) as response:
                if response.status == 200:
                    png_data = response.read()
                    if len(png_data) > 500:
                        with open(png, "wb") as f:
                            f.write(png_data)
                        print(f"[OK] PNG: {png}")
                    else:
                        print("[WARNING] PNG render fail (file quá nhỏ) — SVG vẫn OK, bỏ qua PNG.", file=sys.stderr)
                else:
                    print(f"[WARNING] PNG render fail (HTTP {response.status}) — SVG vẫn OK, bỏ qua PNG.", file=sys.stderr)
        except Exception as e:
            print(f"[WARNING] PNG render fail ({e}) — SVG vẫn OK, bỏ qua PNG.", file=sys.stderr)

if __name__ == "__main__":
    main()
