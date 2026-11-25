#!/usr/bin/env python3
"""
generate-graph.py — rebuild the "everything in the container" reference graph
for a hello-docker / gOW-style Nix Docker image.

What it produces (in --out, default: this docs/ directory):
  image-graph.html   interactive (pan / zoom / search, no network needed)
  image-graph.svg    static render of the same graph
  image-graph.dot    Graphviz source (regenerable with any graphviz)

Inputs (in --data-dir, default: docs/graph-data/ next to this script):
  paths.txt   one store path per line          (/nix/store/<hash>-<name>)
  sizes.txt   "<bytes>\t<path>" per line       (on-disk bytes, e.g. du -sb)
  refs.json   { "<path>": [ "<path>" refs... ] }   runtime references

  paths + sizes can be refreshed from a fresh image with:
      python3 docs/generate-graph.py --refresh hello-docker:latest
  refs.json needs the Nix-side analysis (see footer of the HTML it produced,
  or session notes); render degrades gracefully if some paths lack refs.

Rendering: uses local `neato` if installed, otherwise pipes the DOT through
`docker run --rm -i <--docker-image> sh -c '... neato -Tsvg ...'` (works on
hosts without graphviz; verified with alpine:3.20). Fill colors are injected
post-render, so the result is identical across graphviz versions.

Stdlib only. Python 3.8+.
"""
import argparse, html as H, io, json, os, re, shutil, subprocess, tarfile, tempfile
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_DATA = os.path.join(HERE, "graph-data")

# ---------------------------------------------------------------- sizes/colors
def size_class(mb):
    if mb >= 100: return ("#c0392b", "#ffffff")   # red
    if mb >= 20:  return ("#e67e22", "#ffffff")   # orange
    if mb >= 5:   return ("#f1c40f", "#000000")   # yellow
    return ("#bdc3c7", "#000000")                 # gray

def pn(path):
    """store path -> package name (strip /nix/store/<hash>-)"""
    return re.sub(r"^/nix/store/[a-z0-9]{32}-", "", path)

def node_id(path):
    """unique, readable id: name + last 6 chars of the 32-char store hash.
    Duplicate builds (same name, different hash) must stay distinct nodes."""
    return pn(path) + "~" + path.rsplit("/", 1)[1][:32][-6:]

# ------------------------------------------------------------------- loading
def load_data(data_dir):
    paths, sizes, refs = [], {}, {}
    with open(os.path.join(data_dir, "paths.txt")) as f:
        for line in f:
            line = line.strip()
            if line.startswith("/nix/store/"):
                paths.append(line)
    pathset = set(paths)
    with open(os.path.join(data_dir, "sizes.txt")) as f:
        for line in f:
            parts = line.rstrip("\n").rsplit("\t", 1)
            if len(parts) == 2 and parts[0].isdigit():
                sizes[parts[1]] = int(parts[0])
    with open(os.path.join(data_dir, "refs.json")) as f:
        refs = json.load(f)
    return pathset, sizes, refs

def _refresh_via_run(image):
    """Exact final-rootfs paths+sizes: run `du -sb` inside the image itself.
    Returns (paths, sizes) or None if the image cannot be run."""
    proc = subprocess.run(
        ["docker", "run", "--rm", "--entrypoint", "sh", image,
         "-c", "du -sb /nix/store/*"],
        capture_output=True)
    if proc.returncode != 0:
        return None
    paths, sizes = [], {}
    for line in proc.stdout.decode("utf-8", "replace").splitlines():
        size, sep, name = line.partition("\t")
        if sep and size.isdigit() and name.startswith("/nix/store/"):
            paths.append(name)
            sizes[name] = int(size)
    return (paths, sizes) if len(paths) >= 50 else None


def _refresh_via_save(image):
    """Fallback: union of all docker-save layers (superseded duplicate
    builds included → count may be a few % high). zstd layers: loud warning."""
    ZSTD_MAGIC = bytes([0x28, 0xB5, 0x2F, 0xFD])
    tar_path = tempfile.mktemp(suffix=".tar")
    try:
        subprocess.run(["docker", "save", image, "-o", tar_path], check=True)
        paths, sizes, seen = set(), {}, set()
        zstd_blobs = 0
        with tarfile.open(tar_path, "r:*") as outer:
            for m in outer:
                base = m.name.split("/")[-1]
                if not re.fullmatch(r"[0-9a-f]{64}", base):
                    continue
                fh = outer.extractfile(m)
                if fh is None:
                    continue
                buf = fh.read()
                if buf[:4] == ZSTD_MAGIC:
                    zstd_blobs += 1
                    continue
                try:
                    tf = tarfile.open(fileobj=io.BytesIO(buf), mode="r:*")
                    members = tf.getmembers()
                except (tarfile.TarError, EOFError):
                    continue  # config/manifest json etc.
                for fm in members:
                    name = fm.name.lstrip("/")
                    if not name.startswith("nix/store/") or name in seen:
                        continue
                    seen.add(name)
                    top = "/".join(name.split("/")[:3])
                    paths.add("/" + top)
                    sizes[top] = sizes.get(top, 0) + fm.size
        if zstd_blobs:
            print(f"[refresh] WARNING: {zstd_blobs} zstd-compressed layer(s) skipped — "
                  "paths/sizes are incomplete.")
        return (sorted(paths), sizes) if paths else None
    finally:
        if os.path.exists(tar_path):
            os.unlink(tar_path)


def refresh_from_image(image, data_dir):
    """Re-extract paths.txt + sizes.txt from a docker image.
    Primary: `du -sb /nix/store/*` inside the image (exact final rootfs).
    Fallback: docker-save layer union (when the image can't be run).
    Sizes ≈ du -sb per store path."""
    result = _refresh_via_run(image)
    source = "rootfs (du)"
    if result is None:
        result = _refresh_via_save(image)
        source = "docker-save union"
    if result is None:
        raise RuntimeError("extraction found no nix/store — image wrong or unreadable?")
    paths, sizes = result
    os.makedirs(data_dir, exist_ok=True)
    with open(os.path.join(data_dir, "paths.txt"), "w") as f:
        f.write("\n".join(sorted(paths)) + "\n")
    with open(os.path.join(data_dir, "sizes.txt"), "w") as f:
        for p in sorted(sizes):
            f.write(f"{sizes[p]}\t{p}\n")
    print(f"[refresh] {image}: {len(paths)} store paths via {source}, sizes updated")
    return None

# --------------------------------------------------------------------- dot gen
def build_dot(pathset, sizes, refs):
    out = [
        "digraph image {",
        '  rankdir=LR;',
        '  node [fontname="Helvetica", fontsize=10, shape=box, style="rounded,filled"];',
        '  edge [penwidth=0.4, color="#99999980"];',
    ]
    nid = {}
    for p in sorted(pathset, key=lambda p: -sizes.get(p, 0)):
        mb = sizes.get(p, 0) / 1048576
        c1, c2 = size_class(mb)
        nid[p] = node_id(p)
        lab = pn(p).replace('"', '\\"')
        out.append(f'  "{nid[p]}" [label="{lab}\\n{mb:.1f} MB", '
                   f'fill="{c1}", fontcolor="{c2}", color="#555555"];')
    edges, dropped = set(), 0
    for src, rs in refs.items():
        if src not in pathset:
            continue
        for r in rs:
            if r not in pathset:
                continue
            if r == src:
                dropped += 1
                continue
            e = (nid[src], nid[r])
            if e not in edges:
                edges.add(e)
                out.append(f'  "{e[0]}" -> "{e[1]}";')
    out.append("}")
    return "\n".join(out) + "\n", len(edges), dropped

# -------------------------------------------------------------------- rendering
def render_svg(dot_text, docker_image):
    if shutil.which("neato"):
        proc = subprocess.run(
            ["neato", "-Tsvg"], input=dot_text.encode(),
            capture_output=True, check=True)
        return proc.stdout
    # no local graphviz: pipe through a throwaway docker container
    cmd = ("apk add --no-cache graphviz >/dev/null 2>&1 && "
           "cat > /tmp/g.dot && neato -Tsvg /tmp/g.dot -o /tmp/g.svg && cat /tmp/g.svg")
    proc = subprocess.run(
        ["docker", "run", "--rm", "-i", docker_image, "sh", "-c", cmd],
        input=dot_text.encode(), capture_output=True, check=True)
    return proc.stdout

def inject_fills(svg, fills):
    """graphviz SVG output doesn't reliably apply node fill attributes
    (verified on graphviz 9.0/alpine: fill comes out 'none'). Inject it."""
    def proc(m):
        block = m.group(0)
        t = re.search(r"<title>(.*?)</title>", block, re.S)
        if not t:
            return block
        fill = fills.get(H.unescape(t.group(1)))
        if not fill:
            return block
        def repl(sm):
            tag = sm.group(0)
            if 'fill=' in tag:
                tag = re.sub(r'fill="[^"]*"', f'fill="{fill}"', tag, count=1)
            else:
                tag = re.sub(r"<([a-z]+)", r'<\1 fill="%s"' % fill, tag, count=1)
            return tag
        return re.sub(r"<(?:path|ellipse|rect|polygon)[^>]*>", repl, block, count=1)
    svg = svg[svg.find("<svg"):]
    return re.sub(r'<g id="node\d+" class="node">.*?</g>', proc, svg, flags=re.S)

# ------------------------------------------------------------------------ html
HTML = """<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8">
<title>__TITLE__ — Nix store reference graph</title>
<style>
 html,body{margin:0;height:100%;overflow:hidden;font-family:system-ui,sans-serif;background:#16181d;color:#ddd}
 #viewport{position:absolute;inset:0;cursor:grab;user-select:none}
 #viewport.drag{cursor:grabbing}
 #viewport svg{position:absolute;top:0;left:0;transform-origin:0 0}
 .bar{position:absolute;top:10px;left:10px;z-index:10;background:rgba(20,22,28,.93);border:1px solid #3a3f4a;
   border-radius:10px;padding:10px 12px;max-width:430px;font-size:13px;box-shadow:0 4px 18px rgba(0,0,0,.5)}
 .bar h1{font-size:14px;margin:0 0 6px;font-weight:600}
 .row{margin:5px 0;display:flex;gap:6px;align-items:center;flex-wrap:wrap}
 input[type=text]{width:225px;padding:4px 8px;background:#22252c;color:#eee;border:1px solid #555;border-radius:5px}
 button{background:#2c3038;color:#eee;border:1px solid #555;border-radius:5px;padding:3px 10px;cursor:pointer;font-size:13px}
 button:hover{background:#3a3f4a}
 .legend{font-size:12px;line-height:1.6;color:#aab}
 .sw{display:inline-block;width:11px;height:11px;border-radius:3px;vertical-align:-1px;margin-right:5px}
 #count{color:#7fd6a0;font-size:12px;margin-left:4px}
 g.node{transition:opacity .15s}
 g.node.dim{opacity:.06}
 g.node.hl .box{stroke:#00e5ff;stroke-width:3}
</style></head><body>
<div class="bar">
 <h1>__TITLE__ — Nix store reference graph</h1>
 <div class="row">
  <input id="q" type="text" placeholder="search: rpcs3, llvm, qt6, opencv…" oninput="search(this.value)">
  <button onclick="resetView()">fit</button>
  <button onclick="zoomBy(1.35)">zoom +</button>
  <button onclick="zoomBy(1/1.35)">zoom −</button>
  <span id="count"></span>
 </div>
 <div class="legend">
  <span class="sw" style="background:#c0392b"></span>≥ 100 MB (__N100__ nodes)&nbsp;&nbsp;
  <span class="sw" style="background:#e67e22"></span>20–100 MB (__N20__)&nbsp;&nbsp;
  <span class="sw" style="background:#f1c40f"></span>5–20 MB (__N5__)&nbsp;&nbsp;
  <span class="sw" style="background:#bdc3c7"></span>&lt; 5 MB (__NS__)
 </div>
 <div class="legend" style="margin-top:4px">
  __NN__ nodes · __NE__ edges · edge A→B = "A references B" (linked / shebang / config).<br>
  drag = pan · wheel = zoom · hover = name + size · search highlights matches.
 </div>
</div>
<div id="viewport">__SVG__</div>
<script>
const vp=document.getElementById('viewport'), svgEl=vp.querySelector('svg');
const W=parseFloat(svgEl.getAttribute('width')), H=parseFloat(svgEl.getAttribute('height'));
svgEl.style.width=W+'px'; svgEl.style.height=H+'px';
let tx=0, ty=0, s=1;
function apply(){svgEl.style.transform=`translate(${tx}px,${ty}px) scale(${s})`;}
function fit(){s=Math.min(innerWidth/W, innerHeight/H)*.95;
 tx=(innerWidth-W*s)/2; ty=(innerHeight-H*s)/2; apply();}
function zoomBy(f){const cx=innerWidth/2, cy=innerHeight/2;
 const ns=Math.min(10,Math.max(.2,s*f)), k=ns/s;
 tx=cx-(cx-tx)*k; ty=cy-(cy-ty)*k; s=ns; apply();}
let drag=false,lx,ly;
vp.addEventListener('mousedown',e=>{drag=true;lx=e.clientX;ly=e.clientY;vp.classList.add('drag');});
addEventListener('mousemove',e=>{if(!drag)return;tx+=e.clientX-lx;ty+=e.clientY-ly;lx=e.clientX;ly=e.clientY;apply();});
addEventListener('mouseup',()=>{drag=false;vp.classList.remove('drag');});
vp.addEventListener('wheel',e=>{e.preventDefault();zoomBy(e.deltaY<0?1.15:1/1.15);},{passive:false});
function resetView(){search('');fit();}
fit();
const nodes=[...svgEl.querySelectorAll('g.node')];
const labelOf=g=>{const t=g.querySelector('title');return t?t.textContent.replace(/\\n/g,' '):'';};
function search(q){
 q=q.trim().toLowerCase(); const count=document.getElementById('count');
 if(!q){nodes.forEach(g=>g.classList.remove('dim','hl'));count.textContent='';return;}
 let n=0;
 nodes.forEach(g=>{
  const hit=labelOf(g).toLowerCase().includes(q);
  g.classList.toggle('dim',!hit); g.classList.toggle('hl',hit);
  const sh=g.querySelector('path,ellipse,rect,polygon');
  if(sh) sh.setAttribute('class','box');
  if(hit)n++;});
 count.textContent=n+' match'+(n===1?'':'es');
}
</script>
</body></html>
"""

def build_html(svg, title, pathset, sizes, nedges):
    cls = Counter(size_class(sizes.get(p, 0) / 1048576)[0] for p in pathset)
    rep = {
        "__TITLE__": title,
        "__N100__": str(cls.get("#c0392b", 0)),
        "__N20__": str(cls.get("#e67e22", 0)),
        "__N5__": str(cls.get("#f1c40f", 0)),
        "__NS__": str(cls.get("#bdc3c7", 0)),
        "__NN__": str(len(pathset)),
        "__NE__": f"{nedges:,}",
        "__SVG__": svg,
    }
    out = HTML
    for k, v in rep.items():
        out = out.replace(k, v)
    return out

# ----------------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser(description="Rebuild the container reference graph.")
    ap.add_argument("--data-dir", default=DEFAULT_DATA, help="dir with paths.txt, sizes.txt, refs.json")
    ap.add_argument("--out", default=HERE, help="output dir for image-graph.{html,svg,dot}")
    ap.add_argument("--title", default="hello-docker:latest")
    ap.add_argument("--docker-image", default="alpine:3.20",
                    help="image used for rendering when no local neato exists")
    ap.add_argument("--refresh", nargs="?", const="hello-docker:latest", default=None,
                    metavar="IMAGE",
                    help="re-extract paths.txt+sizes.txt from IMAGE before rendering")
    args = ap.parse_args()

    if args.refresh:
        refresh_from_image(args.refresh, args.data_dir)

    pathset, sizes, refs = load_data(args.data_dir)
    missing_refs = len(pathset) - len({p for p in pathset if p in refs})
    dot, nedges, ndropped = build_dot(pathset, sizes, refs)

    os.makedirs(args.out, exist_ok=True)
    dot_path = os.path.join(args.out, "image-graph.dot")
    open(dot_path, "w").write(dot)

    svg = render_svg(dot, args.docker_image).decode("utf-8", "replace")
    fills = {node_id(p): size_class(sizes.get(p, 0) / 1048576)[0] for p in pathset}
    svg = inject_fills(svg, fills)

    html = build_html(svg, args.title, pathset, sizes, nedges)
    svg_path = os.path.join(args.out, "image-graph.svg")
    open(svg_path, "w").write(svg)
    html_path = os.path.join(args.out, "image-graph.html")
    open(html_path, "w").write(html)

    cls = Counter(size_class(sizes.get(p, 0) / 1048576)[0] for p in pathset)
    print(f"nodes: {len(pathset)}  (red {cls.get('#c0392b',0)} / orange {cls.get('#e67e22',0)} "
          f"/ yellow {cls.get('#f1c40f',0)} / gray {cls.get('#bdc3c7',0)})")
    print(f"edges: {nedges}  (self-refs dropped: {ndropped}, paths without refs: {missing_refs})")
    print(f"wrote: {html_path}")
    print(f"       {svg_path}")
    print(f"       {dot_path}")

if __name__ == "__main__":
    main()
