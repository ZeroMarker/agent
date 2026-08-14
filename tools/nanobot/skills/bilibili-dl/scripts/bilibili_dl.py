#!/usr/bin/env python3
"""Bilibili video downloader.

Resolves b23.tv short links or direct Bilibili URLs, fetches metadata,
downloads the video, and outputs JSON result.

Usage:
    bilibili_dl.py <url_or_bvid>

Output (stdout): JSON with keys: path, title, author, duration, bvid, error
"""

import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from urllib.parse import urlparse, parse_qs

USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/125.0.0.0 Safari/537.36"
)

HEADERS = {
    "User-Agent": USER_AGENT,
    "Referer": "https://www.bilibili.com/",
}

OUTPUT_DIR = "/root/downloads"


def _ensure_output_dir():
    os.makedirs(OUTPUT_DIR, exist_ok=True)


def _http_get(url, headers=None):
    """GET a URL and return (status, data, final_url)."""
    hdrs = HEADERS.copy()
    if headers:
        hdrs.update(headers)
    req = urllib.request.Request(url, headers=hdrs)
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = resp.read()
            return resp.status, data, resp.url
    except urllib.error.HTTPError as e:
        return e.code, e.read(), url
    except urllib.error.URLError as e:
        return 0, str(e.reason).encode(), url


def resolve_b23(url):
    """Resolve b23.tv short link by getting the redirect target.

    Returns (final_url, error_msg).
    """
    if 'b23.tv' not in url:
        return url, None

    try:
        # Use curl to follow redirects silently and report final URL
        result = subprocess.run(
            ["curl", "-s", "-o", "/dev/null", "-w", "%{redirect_url}", url],
            capture_output=True, text=True, timeout=15
        )
        final = result.stdout.strip()
        if result.returncode != 0 or not final:
            # Fallback: try with -L
            result = subprocess.run(
                ["curl", "-sL", "-o", "/dev/null", "-w", "%{url_effective}", url],
                capture_output=True, text=True, timeout=15
            )
            final = result.stdout.strip()
        if final:
            return final, None
        return url, "Failed to resolve b23.tv link"
    except subprocess.TimeoutExpired:
        return url, "Timeout resolving b23.tv link"
    except FileNotFoundError:
        return url, "curl not found"


def extract_bvid(text):
    """Extract BV number from a URL or text."""
    # Direct BV match
    m = re.search(r'(BV[a-zA-Z0-9]{10,12})', text)
    if m:
        return m.group(1)
    # AV number (e.g., av123456)
    m = re.search(r'av(\d+)', text, re.IGNORECASE)
    if m:
        return m.group(0)
    return None


def get_video_info(bvid):
    """Fetch video metadata from Bilibili API.

    Returns dict with keys: title, author, author_mid, duration_sec, cid, pic
    or None on failure.
    """
    url = f"https://api.bilibili.com/x/web-interface/view?bvid={bvid}"
    status, data, _ = _http_get(url)
    if status != 200:
        return None

    try:
        resp = json.loads(data)
    except json.JSONDecodeError:
        return None

    if resp.get("code") != 0:
        return None

    vdata = resp.get("data", {})
    pages = vdata.get("pages", [])
    first_page = pages[0] if pages else {}

    return {
        "title": vdata.get("title", ""),
        "author": vdata.get("owner", {}).get("name", ""),
        "author_mid": vdata.get("owner", {}).get("mid", 0),
        "duration_sec": vdata.get("duration", 0),
        "cid": first_page.get("cid", 0),
        "pic": vdata.get("pic", ""),
        "bvid": vdata.get("bvid", bvid),
        "aid": vdata.get("aid", 0),
    }


def get_download_url(bvid, cid, qn=80):
    """Get video download URL from Bilibili play API.

    qn=80 = 480P, qn=32 = 360P, qn=64 = 720P, qn=74 = 720P60, qn=116 = 1080P+
    Returns (url, size_bytes) or (None, None).
    """
    url = (
        f"https://api.bilibili.com/x/player/playurl"
        f"?bvid={bvid}&cid={cid}&qn={qn}&platform=html5&high_quality=1"
    )
    status, data, _ = _http_get(url)
    if status != 200:
        return None, None

    try:
        resp = json.loads(data)
    except json.JSONDecodeError:
        return None, None

    if resp.get("code") != 0:
        return None, None

    durls = resp.get("data", {}).get("durl", [])
    if not durls:
        return None, None

    # First segment has the primary URL
    first = durls[0]
    video_url = first.get("url") or first.get("backup_url", [None])[0]
    size = first.get("size", 0)
    return video_url, size


def download_video(video_url, output_path):
    """Download video using curl with proper headers."""
    result = subprocess.run(
        [
            "curl", "-L", "-o", output_path,
            "-H", f"User-Agent: {USER_AGENT}",
            "-H", "Referer: https://www.bilibili.com/",
            "-s",
            "--retry", "2",
            "--retry-delay", "2",
            video_url,
        ],
        capture_output=True, text=True, timeout=120
    )
    if result.returncode != 0:
        return False
    return os.path.exists(output_path) and os.path.getsize(output_path) > 1000


def sanitize_filename(name):
    """Remove or replace characters not allowed in filenames."""
    name = re.sub(r'[\\/:*?"<>|]', '_', name)
    name = re.sub(r'\s+', ' ', name).strip()
    return name[:128]


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: bilibili_dl.py <url_or_bvid>"}))
        sys.exit(1)

    input_text = sys.argv[1].strip()
    _ensure_output_dir()

    # Step 1: Resolve b23.tv short link
    resolved_url = input_text
    if 'b23.tv' in input_text:
        resolved_url, err = resolve_b23(input_text)
        if err:
            print(json.dumps({"error": err}))
            sys.exit(1)

    # Step 2: Extract BVID
    bvid = extract_bvid(resolved_url) or extract_bvid(input_text)
    if not bvid:
        # Try as direct bvid
        if re.match(r'^[a-zA-Z0-9]+$', input_text):
            bvid = input_text
        else:
            print(json.dumps({"error": f"Could not extract BVID from: {input_text}"}))
            sys.exit(1)

    # Step 3: Get video info
    info = get_video_info(bvid)
    if info is None:
        print(json.dumps({"error": f"Failed to fetch video info for {bvid}"}))
        sys.exit(1)

    # Step 4: Get download URL
    video_url, size = get_download_url(bvid, info["cid"])
    if not video_url:
        print(json.dumps({"error": f"Failed to get download URL for {bvid}"}))
        sys.exit(1)

    # Step 5: Download
    out_name = sanitize_filename(info["title"]) + ".mp4"
    out_path = os.path.join(OUTPUT_DIR, out_name)
    success = download_video(video_url, out_path)

    if not success:
        # Try one more time
        success = download_video(video_url, out_path)

    if not success:
        print(json.dumps({"error": "Download failed"}))
        sys.exit(1)

    # Step 6: Output result
    result = {
        "path": out_path,
        "title": info["title"],
        "author": info["author"],
        "duration_sec": info["duration_sec"],
        "bvid": info["bvid"],
        "size_bytes": os.path.getsize(out_path),
    }
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
