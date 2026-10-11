#!/usr/bin/env python3
"""INSPIRE-HEP and Crossref lookups for lit-sweep and /cite-check.

  inspire.py search "<INSPIRE query>" [-n N] [--sort mostrecent|mostcited]
  inspire.py bibtex <arXiv id | DOI | texkey>...
  inspire.py check <file.bib>

Set CROSSREF_MAILTO to join Crossref's polite pool.
"""
import argparse
import difflib
import json
import os
import re
import sys
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request

INSPIRE = "https://inspirehep.net/api/literature"
CROSSREF = "https://api.crossref.org/works/"
FIELDS = ("texkeys,titles,authors.full_name,arxiv_eprints,dois,publication_info,"
          "preprint_date,earliest_date,citation_count")
PAUSE = 0.4  # INSPIRE rate-limits bursts of requests
TITLE_MATCH = 0.9
WORKING_PAPER_DOI = {"10.3386": "NBER working paper", "10.2139": "SSRN paper"}
UA = "lit-sweep-inspire.py" + (f" (mailto:{os.environ['CROSSREF_MAILTO']})"
                               if os.environ.get("CROSSREF_MAILTO") else "")

DOI_RE = re.compile(r"^(?:https?://(?:dx\.)?doi\.org/|doi:)?(10\.\d{4,9}/\S+)$", re.I)
ARXIV_RE = re.compile(r"^(?:arxiv:)?(\d{4}\.\d{4,5}|[a-z-]+(?:\.[a-z]{2})?/\d{7})(?:v\d+)?$", re.I)
TEXKEY_RE = re.compile(r"^[^\s:]+:\d{4}[a-z]{2,3}$")
ENTRY_RE = re.compile(r"@(\w+)\s*\{\s*([^,\s]+)\s*,")
BRACE_RE = re.compile(r"[{}]")

_last = 0.0


def get(url, accept):
    """Body of a GET, or None on 404. Any other failure ends the run with the server's message."""
    global _last
    time.sleep(max(0.0, _last + PAUSE - time.monotonic()))
    host = urllib.parse.urlsplit(url).netloc
    req = urllib.request.Request(url, headers={"Accept": accept, "User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        sys.exit(f"{host}: HTTP {e.code} {e.reason}\n{e.read(500).decode('utf-8', 'replace')}")
    except (urllib.error.URLError, TimeoutError) as e:
        sys.exit(f"cannot reach {host}: {getattr(e, 'reason', e)}")
    finally:
        _last = time.monotonic()


def inspire_json(query, size, sort=None):
    params = {"q": query, "size": size, "fields": FIELDS}
    if sort:
        params["sort"] = sort
    hits = json.loads(get(f"{INSPIRE}?{urllib.parse.urlencode(params)}", "application/json"))["hits"]
    return hits["total"], [h["metadata"] for h in hits["hits"]]


def inspire_bibtex(query):
    params = urllib.parse.urlencode({"q": query, "size": 5, "format": "bibtex"})
    return get(f"{INSPIRE}?{params}", "application/x-bibtex").strip()


def crossref_json(doi):
    body = get(CROSSREF + urllib.parse.quote(doi), "application/json")
    return json.loads(body)["message"] if body else None


def crossref_bibtex(doi):
    body = get(CROSSREF + urllib.parse.quote(doi) + "/transform/application/x-bibtex",
               "application/x-bibtex")
    return body.strip() if body else None


def inspire_record(m):
    return {
        "titles": [t["title"] for t in m.get("titles", [])],
        "first": m["authors"][0]["full_name"].split(",")[0] if m.get("authors") else None,
        "years": {p["year"] for p in m.get("publication_info", []) if "year" in p}
                 | {int(m[k][:4]) for k in ("preprint_date", "earliest_date") if k in m},
        "dois": {d["value"].lower() for d in m.get("dois", [])},
        "arxiv": {e["value"] for e in m.get("arxiv_eprints", [])},
    }


def crossref_record(m):
    authors = m.get("author", [])
    years = {m[k]["date-parts"][0][0] for k in ("issued", "published-print", "published-online")
             if k in m and m[k]["date-parts"][0][0]}
    return {
        "titles": m.get("title", []),
        "first": (authors[0].get("family") or authors[0].get("name")) if authors else None,
        "years": years,
        "dois": {m["DOI"].lower()},
        "arxiv": set(),
    }


def wp_note(doi):
    kind = WORKING_PAPER_DOI.get(doi.split("/")[0])
    return f"{kind}; check for a published version" if kind else ""


def classify(ident):
    s = ident.strip()
    if m := DOI_RE.match(s):
        return "doi", m.group(1)
    if m := ARXIV_RE.match(s):
        return "arxiv", m.group(1)
    if TEXKEY_RE.match(s):
        return "texkey", s
    sys.exit(f"not an arXiv id, DOI or INSPIRE texkey: {ident}")


def inspire_query(kind, value):
    return {"arxiv": f"arxiv:{value}", "doi": f'doi:"{value}"', "texkey": f'texkeys:"{value}"'}[kind]


def cmd_search(query, n, sort):
    total, hits = inspire_json(query, n, sort)
    print(f"# {total} hits, showing {len(hits)}", file=sys.stderr)
    for m in hits:
        r = inspire_record(m)
        first = (r["first"] or "?") + (" et al." if len(m.get("authors", [])) > 1 else "")
        arxiv = m["arxiv_eprints"][0]["value"] if m.get("arxiv_eprints") else None
        print(" | ".join([
            (m.get("texkeys") or ["-"])[0],
            first,
            str(min(r["years"])) if r["years"] else "----",
            " ".join((r["titles"] or ["?"])[0].split()),
            f"arXiv:{arxiv}" if arxiv else "no arXiv",
            f"{m.get('citation_count', 0)} cites",
        ]))
    return 0


def cmd_bibtex(idents):
    missing = []
    for ident in idents:
        kind, value = classify(ident)
        text = inspire_bibtex(inspire_query(kind, value))
        n = len(re.findall(r"^@", text, re.M))
        if n:
            warn = "" if n == 1 else f"; AMBIGUOUS: {n} records matched, keep the right one"
            print(f"% {ident}: from INSPIRE{warn}\n{text}\n")
            continue
        if kind == "doi" and (text := crossref_bibtex(value)):
            note = wp_note(value)
            print(f"% {ident}: from Crossref, not in INSPIRE{'; ' + note if note else ''}\n{text}\n")
            continue
        missing.append((kind, ident))
    for kind, ident in missing:
        where = "INSPIRE or Crossref" if kind == "doi" else "INSPIRE"
        hint = " (pass the DOI of the published version if it has one)" if kind == "arxiv" else ""
        print(f"NOT FOUND in {where}: {ident}{hint}", file=sys.stderr)
    return 1 if missing else 0


def entries(text):
    for m in ENTRY_RE.finditer(text):
        if m.group(1).lower() in ("string", "comment", "preamble"):
            continue
        depth = 1
        for b in BRACE_RE.finditer(text, m.end()):
            depth += 1 if b.group() == "{" else -1
            if depth == 0:
                yield m.group(2), text[m.end():b.start()]
                break
        else:
            sys.exit(f"unbalanced braces in entry {m.group(2)}")


def field(body, name):
    m = re.search(rf"(?<![\w-]){name}\s*=\s*", body, re.I)
    if not m:
        return None
    i = m.end()
    if body[i] not in '{"':
        return re.match(r"[^,\s}]*", body[i:]).group()
    close, depth, j = ("}" if body[i] == "{" else '"'), 0, i + 1
    while body[j] != close or depth:
        depth += {"{": 1, "}": -1}.get(body[j], 0)
        j += 1
    return body[i + 1:j]


def bib_eprint(body):
    e = field(body, "eprint")
    prefix = field(body, "archiveprefix")
    if not e or (prefix and prefix.strip().lower() != "arxiv"):
        return None
    e = re.sub(r"v\d+$", "", re.sub(r"^arxiv:", "", e.strip(), flags=re.I))
    if re.fullmatch(r"\d{7}", e) and (pc := field(body, "primaryclass")):
        e = f"{pc.strip()}/{e}"
    return e


def bib_doi(body):
    d = field(body, "doi")
    if not d:
        return None
    return re.sub(r"^(?:https?://(?:dx\.)?doi\.org/|doi:)", "", d.strip(), flags=re.I).replace("\\_", "_")


def norm(s):
    s = re.sub(r"<[^>]+>|\\[a-zA-Z]+", " ", s)
    s = re.sub(r"\\[^a-zA-Z]", "", s)
    s = "".join(c for c in unicodedata.normalize("NFKD", s) if not unicodedata.combining(c))
    return " ".join(re.sub(r"[^a-z0-9]+", " ", s.lower()).split())


def bib_first_author(author):
    first = re.split(r"\s+and\s+", " ".join(author.split()), maxsplit=1)[0].strip("{} ")
    return first.split(",")[0] if "," in first else first.split()[-1]


def compare(body, rec, eprint, doi):
    issues = []
    title = field(body, "title")
    if title and rec["titles"]:
        best = max(difflib.SequenceMatcher(None, norm(title), norm(t)).ratio() for t in rec["titles"])
        if best < TITLE_MATCH:
            issues.append(f'title: bib "{" ".join(title.split())}" vs record "{rec["titles"][0]}"'
                          f" (similarity {best:.2f})")
    author = field(body, "author")
    if author and author.strip() and rec["first"]:
        a, b = norm(bib_first_author(author)).replace(" ", ""), norm(rec["first"]).replace(" ", "")
        if a not in b and b not in a:
            issues.append(f"first author: bib {bib_first_author(author)} vs record {rec['first']}")
    year = re.search(r"\d{4}", field(body, "year") or "")
    if year and rec["years"] and int(year.group()) not in rec["years"]:
        issues.append(f"year: bib {year.group()} vs record {', '.join(map(str, sorted(rec['years'])))}")
    if doi and rec["dois"] and doi.lower() not in rec["dois"]:
        issues.append(f"doi {doi} is not on this record (record: {', '.join(sorted(rec['dois']))})")
    if eprint and rec["arxiv"] and eprint not in rec["arxiv"]:
        issues.append(f"eprint {eprint} is not on this record (record: {', '.join(sorted(rec['arxiv']))})")
    return issues


def cmd_check(path):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    found = {"INSPIRE": 0, "Crossref": 0}
    checked, bad, missing, unchecked = 0, 0, [], []
    for key, body in entries(text):
        eprint, doi = bib_eprint(body), bib_doi(body)
        if not (eprint or doi):
            unchecked.append(key)
            continue
        checked += 1
        ids = [x for x in (eprint and f"arxiv:{eprint}", doi and f'doi:"{doi}"') if x]
        _, hits = inspire_json(" or ".join(ids), 2)
        if len(hits) > 1:
            bad += 1
            keys = ", ".join((h.get("texkeys") or ["?"])[0] for h in hits)
            print(f"{key}: eprint {eprint} and doi {doi} belong to different INSPIRE records ({keys})")
            continue
        recs = [("INSPIRE", inspire_record(hits[0]))] if hits else []
        # A DOI the INSPIRE record does not carry may point at a different work; Crossref settles it.
        if doi and (not recs or doi.lower() not in recs[0][1]["dois"]) and (m := crossref_json(doi)):
            recs.append(("Crossref", crossref_record(m)))
        if not recs:
            missing.append(key)
            print(f"{key}: NOT FOUND ({' '.join(ids)})")
            continue
        issues = []
        for src, rec in recs:
            found[src] += 1
            issues += [f"[{src}] {i}" for i in compare(body, rec, eprint, doi if src == "INSPIRE" else None)]
        if doi and (note := wp_note(doi)):
            print(f"{key}: note: {note}")
        if issues:
            bad += 1
            print(f"{key}:\n  " + "\n  ".join(issues))
    print(f"\n{checked} entries checked ({found['INSPIRE']} INSPIRE, {found['Crossref']} Crossref records): "
          f"{bad} with problems, {len(missing)} not found.")
    if unchecked:
        print(f"{len(unchecked)} without eprint or doi, not checked: {', '.join(unchecked)}")
    return 1 if bad or missing else 0


def main():
    p = argparse.ArgumentParser(description="INSPIRE-HEP / Crossref lookups for lit-sweep and /cite-check.")
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("search", help="INSPIRE search, one line per hit")
    s.add_argument("query", help="INSPIRE search syntax")
    s.add_argument("-n", type=int, default=10, help="number of hits (default 10)")
    s.add_argument("--sort", choices=["mostrecent", "mostcited"])
    b = sub.add_parser("bibtex", help="BibTeX from INSPIRE, Crossref fallback for DOIs")
    b.add_argument("ids", nargs="+", metavar="ID", help="arXiv id, DOI or INSPIRE texkey")
    c = sub.add_parser("check", help="check .bib entries that have an eprint or doi")
    c.add_argument("bib")
    a = p.parse_args()
    if a.cmd == "search":
        return cmd_search(a.query, a.n, a.sort)
    if a.cmd == "bibtex":
        return cmd_bibtex(a.ids)
    return cmd_check(a.bib)


if __name__ == "__main__":
    sys.exit(main())
