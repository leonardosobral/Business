#!/usr/bin/env python3
"""Build a fresh manifest from reviewed candidates and captured baselines; never edit either."""
import argparse
import json
from pathlib import Path
from release_support import BASE, publisher


def build(release, baseline_dir, evidence_paths, allow_subset=False):
    release, baseline_dir = Path(release).resolve(), Path(baseline_dir).resolve()
    evidence = {}
    for path in evidence_paths:
        for row in json.loads(Path(path).read_text()):
            key = (row['site'], row['path'])
            publisher.require(key not in evidence or evidence[key] == row['sha'], f'Conflicting captured baseline: {key}')
            evidence[key] = row['sha']
    candidates = release / 'candidate'
    publisher.safe_path(candidates)
    found = set()
    for file in candidates.rglob('*'):
        publisher.safe_path(file)
        if file.is_file():
            relative = file.relative_to(candidates)
            publisher.require(len(relative.parts) > 1, 'Unexpected candidate layout')
            key = (relative.parts[0], Path(*relative.parts[1:]).as_posix())
            publisher.require(key in publisher.ORDER, f'Unreviewed candidate: {key}')
            found.add(key)
    publisher.require(found and (allow_subset or found == set(publisher.ORDER)), 'Expected all 12 reviewed runtime candidates')
    lines = []
    for key in publisher.ORDER:
        if key not in found:
            continue
        site, relative = key
        if key in publisher.NEW_FILES:
            # This is the required absence contract, not proof of remote absence.
            # The guarded remote prepare checks actual production before any publish.
            publisher.require(not (baseline_dir / site / relative).exists(), f'Unexpected baseline for new file: {key}')
            publisher.require(key not in evidence or evidence[key] == 'ABSENT', f'New file was captured as present: {key}')
            before = 'ABSENT'
        else:
            publisher.require(key in evidence, f'Missing production capture evidence: {key}')
            before = publisher.sha256(baseline_dir / site / relative)
            publisher.require(before == evidence[key], f'Captured baseline bytes mismatch: {key}')
        after = publisher.sha256(candidates / site / relative)
        publisher.require(before != after, f'Unchanged runtime candidate: {key}')
        lines.append(f'{site}\t{relative}\t{before}\t{after}\n')
    manifest = release / 'runtime.tsv'
    with manifest.open('x', encoding='utf-8') as handle:
        handle.write(''.join(lines))
    publisher.Release(release).plan()
    return len(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--allow-subset', action='store_true', help='Only after reviewing every omitted target')
    args = parser.parse_args()
    count = build(BASE / 'release', BASE / 'production-baseline',
                  [BASE / 'baseline.json', BASE / 'baseline-extra.json'], args.allow_subset)
    print(f'Created runtime.tsv with {count} reviewed paths; remote ABSENT checks remain required at prepare.')


if __name__ == '__main__':
    main()
