#!/usr/bin/env python3
"""Refresh the narrow Microsoft download rule set from Microsoft's endpoint table."""

import os
import re
import tempfile
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path('/opt/kai-subscription/rules')
URL = 'https://learn.microsoft.com/en-us/windows/deployment/do/delivery-optimization-endpoints'
ROW_PREFIXES = (
    'Windows Update ', 'Edge Browser ', 'M365 app updates ',
    'Delivery Optimization Service ', 'Microsoft package updates ',
)
REQUIRED = {
    'windowsupdate.com', 'dl.delivery.mp.microsoft.com',
    'do.dsp.mp.microsoft.com', 'officecdn.microsoft.com',
    'cdn.office.net', 'static.microsoft',
}


class Rows(HTMLParser):
    def __init__(self):
        super().__init__()
        self.row = None
        self.rows = []

    def handle_starttag(self, tag, attrs):
        if tag == 'tr':
            self.row = []

    def handle_data(self, data):
        if self.row is not None:
            self.row.append(data.strip())

    def handle_endtag(self, tag):
        if tag == 'tr' and self.row is not None:
            self.rows.append(' '.join(part for part in self.row if part))
            self.row = None


def build(html):
    parser = Rows()
    parser.feed(html)
    domains = set()
    for row in parser.rows:
        if row.startswith(ROW_PREFIXES):
            domains.update(re.findall(
                r'(?<![A-Za-z0-9.-])(?:\*\.)?([a-z0-9][a-z0-9.-]+\.[a-z]{2,})(?![A-Za-z0-9.-])',
                row,
            ))
    if not REQUIRED <= domains or len(domains) > 20:
        raise ValueError('Microsoft endpoint table changed; keeping last validated rules')
    if domains & {'microsoft.com', 'office.net', 'live.com', 'google.com', 'com'}:
        raise ValueError('Overbroad domain in endpoint table')
    if not all(d.endswith(('.microsoft.com', '.office.net', '.static.microsoft')) or d in REQUIRED for d in domains):
        raise ValueError('Unexpected domain in endpoint table')
    return ['DOMAIN-SUFFIX,' + domain for domain in sorted(domains)]


def main():
    request = urllib.request.Request(URL, headers={'User-Agent': 'Kai-VPS-Infra-rules/1.0'})
    with urllib.request.urlopen(request, timeout=20) as response:
        if not response.url.startswith('https://learn.microsoft.com/'):
            raise ValueError('Unexpected redirect')
        html = response.read(2_000_001)
    if len(html) > 2_000_000:
        raise ValueError('Endpoint page too large')
    rules = build(html.decode('utf-8'))
    body = ('payload:\n' + ''.join('  - ' + rule + '\n' for rule in rules)).encode()
    target = ROOT / 'microsoft-download.yaml'
    fd, candidate = tempfile.mkstemp(prefix='.microsoft-', suffix='.yaml', dir=ROOT)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(body)
            os.fchown(stream.fileno(), 0, ROOT.stat().st_gid)
            os.fchmod(stream.fileno(), 0o640)
        os.replace(candidate, target)
    finally:
        if os.path.exists(candidate):
            os.unlink(candidate)
    print('Validated Microsoft download rules:', len(rules))


if __name__ == '__main__':
    main()
