#!/usr/bin/env python3
"""Verify every local asset referenced by the built site actually exists.

Run after `quarto render` and before publishing. Exits non-zero if any local
asset reference cannot be resolved inside the output directory.

Why this exists: plotly widgets were blank on the published site for about a
year. The pages rendered, the widget divs were present, and only the
JavaScript 404'd -- which looks like a layout gap, not an error. The libraries
lived in _freeze/site_libs, which a bare `site_libs/` line in .gitignore
silently excluded from the repository, so CI had nothing to copy. Nothing in
the build failed.

Only local references are checked. External URLs are deliberately out of
scope: network flakiness would make the build non-deterministic.

Usage:
    python3 scripts/check_site_links.py [output_dir]   # default: _site
"""

import os
import re
import sys
from urllib.parse import unquote, urldefrag

# Anything that is not a path into the output directory.
EXTERNAL = re.compile(
    r"""^(?:
          [a-zA-Z][a-zA-Z0-9+.-]*:   # any scheme: http, https, data, mailto, javascript, tel
        | //                          # protocol-relative
        | [#?]                        # pure fragment or query
        | \{\{                        # template placeholder
        | \$\{                        # JS template literal
      )""",
    re.VERBOSE,
)

# Attributes that point at an asset the browser must fetch.
ATTR_PATTERNS = [
    ("script src", re.compile(r"<script\b[^>]*?\bsrc\s*=\s*[\"']([^\"']+)[\"']", re.I)),
    ("link href", re.compile(r"<link\b[^>]*?\bhref\s*=\s*[\"']([^\"']+)[\"']", re.I)),
    ("img src", re.compile(r"<img\b[^>]*?\bsrc\s*=\s*[\"']([^\"']+)[\"']", re.I)),
    ("source src", re.compile(r"<(?:source|video|audio|embed)\b[^>]*?\bsrc\s*=\s*[\"']([^\"']+)[\"']", re.I)),
    ("object data", re.compile(r"<object\b[^>]*?\bdata\s*=\s*[\"']([^\"']+)[\"']", re.I)),
]

SRCSET_RE = re.compile(r"<(?:img|source)\b[^>]*?\bsrcset\s*=\s*[\"']([^\"']+)[\"']", re.I)
CSS_URL_RE = re.compile(r"url\(\s*[\"']?([^\"')]+)[\"']?\s*\)", re.I)


def candidates(text, is_css):
    """Yield (kind, raw_reference) pairs found in one file."""
    if is_css:
        for m in CSS_URL_RE.finditer(text):
            yield "css url()", m.group(1)
        return

    for kind, pat in ATTR_PATTERNS:
        for m in pat.finditer(text):
            yield kind, m.group(1)

    for m in SRCSET_RE.finditer(text):
        # "a.png 1x, b.png 2x" -> a.png, b.png
        for part in m.group(1).split(","):
            url = part.strip().split(" ")[0].strip()
            if url:
                yield "img srcset", url

    # url(...) inside inline <style> blocks
    for style in re.findall(r"<style\b[^>]*>(.*?)</style>", text, re.S | re.I):
        for m in CSS_URL_RE.finditer(style):
            yield "css url()", m.group(1)


def main():
    root = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else "_site")
    if not os.path.isdir(root):
        print("ERROR: output directory not found: %s" % root)
        return 2

    files = []
    for dirpath, _dirnames, filenames in os.walk(root):
        for name in filenames:
            if name.endswith((".html", ".css")):
                files.append(os.path.join(dirpath, name))
    files.sort()

    broken = []          # (page, kind, reference)
    checked = 0
    seen = set()         # de-duplicate identical (page, reference) pairs
    exists = {}          # resolved target -> bool; shared assets are referenced
                         # from many pages, so this cuts syscalls several-fold

    for path in files:
        try:
            with open(path, encoding="utf-8", errors="replace") as fh:
                text = fh.read()
        except OSError as err:
            print("ERROR: could not read %s: %s" % (path, err))
            return 2

        base = os.path.dirname(path)
        page = os.path.relpath(path, root).replace(os.sep, "/")

        for kind, raw in candidates(text, path.endswith(".css")):
            raw = raw.strip()
            if not raw or EXTERNAL.match(raw):
                continue
            ref = unquote(urldefrag(raw)[0].split("?")[0])
            if not ref:
                continue
            key = (page, ref)
            if key in seen:
                continue
            seen.add(key)

            target = os.path.normpath(
                os.path.join(root, ref.lstrip("/")) if ref.startswith("/")
                else os.path.join(base, ref)
            )
            checked += 1
            ok = exists.get(target)
            if ok is None:
                ok = os.path.exists(target)
                exists[target] = ok
            if not ok:
                broken.append((page, kind, ref))

    print("Asset link check")
    print("  output dir        : %s" % root)
    print("  files scanned     : %d" % len(files))
    print("  local refs checked: %d" % checked)
    print("  broken            : %d" % len(broken))

    if not broken:
        print("\nOK - every local asset reference resolves.")
        return 0

    print("\nBROKEN LOCAL ASSET REFERENCES")
    print("-" * 72)
    by_page = {}
    for page, kind, ref in broken:
        by_page.setdefault(page, []).append((kind, ref))
    for page in sorted(by_page):
        print("  %s" % page)
        for kind, ref in sorted(by_page[page]):
            print("      [%-11s] %s" % (kind, ref))
    print("-" * 72)
    print("%d broken local asset reference(s) across %d page(s)."
          % (len(broken), len(by_page)))
    print("The build is failing on purpose: publishing this would ship a site")
    print("whose pages load but whose assets 404. Fix the references, or commit")
    print("the missing files, then push again.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
