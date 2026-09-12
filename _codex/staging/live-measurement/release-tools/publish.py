#!/usr/bin/env python3
"""Guarded, reversible file release for LIVE measurement. No SSH or SQL execution."""
import argparse
import base64
import errno
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import signal
import stat
import sys
import tempfile
import time

ROOTS = {
    "RoadRunners": Path("/var/www/roadrunners.com.br"),
    "Business": Path("/var/www/business.roadrunners.run"),
}
ORDER = (
    ("Business", "portal/audiencia/queries/live_journey.sql"),
    ("Business", "portal/audiencia/live_journey.cfm"),
    ("Business", "portal/includes/audience_backend.cfm"),
    ("Business", "portal/audiencia/home.cfm"),
    ("RoadRunners", "services/AudienceMeasurementService.cfc"),
    ("RoadRunners", "assets/js/rr-audience.js"),
    ("RoadRunners", "includes/modal/modal_cupom_link_conteudo.cfm"),
    ("RoadRunners", "evento/index.cfm"),
    ("RoadRunners", "evento/parts/barra_acoes.cfm"),
    ("RoadRunners", "evento/parts/edicoes_evento.cfm"),
    ("RoadRunners", "includes/analytics/bootstrap.cfm"),
)
NEW_FILES = frozenset(ORDER[:2])
GUARD_FILES = {
    "RoadRunners": (
        "Application.cfc", "config/settings.cfm", "config/ads.local.cfm",
        "config/audience.local.cfm", "services/LocationResolver.cfc",
        "services/AudienceRequestControlService.cfc", "services/AdsV1ConfigService.cfc",
        "includes/backend/backend_evento.cfm", "includes/ads_v1/runtime_config.cfm",
        "services/AdsV1BannerDeliveryService.cfc", "services/AdsV1CpcDeliveryService.cfc",
        "services/AdsV1HouseDeliveryService.cfc", "includes/ads_v1/viewability.cfm",
        "api/ads/v1/click.cfm", "api/ads/v1/cpc-click.cfm", "api/ads/v1/viewable.cfm",
        "api/ads/v1/cpc-viewable.cfm", "api/analytics/collect.cfm", "sw.js",
        "includes/modal/modal_youtube.cfm", "includes/analytics/slot_marker.cfm",
        "includes/ads_v1/banner_delivery.cfm", "includes/estrutura/home_sidebar_promos.cfm",
        "includes/eventos_ads.cfm", "circuito/index.cfm",
    ),
    "Business": (
        "Application.cfc", "includes/backend/business_request_identity.cfm",
        "includes/backend/business_google_callback.cfm", "logout.cfm",
        "ads/includes/backend.cfm", "assets/css/audience-dashboard.css",
        "assets/js/audience-dashboard.js", "portal/audiencia/queries/content.sql",
        "portal/audiencia/queries/inventory.sql",
    ),
}
# Snapshot inventories too: an added/deleted protected file is a change.
# An absent optional tree is recorded as absent; it cannot appear mid-release.
GUARD_TREES = {
    "RoadRunners": ("config", "_codex/sql"),
    "Business": ("config", "portal/audiencia/queries", "_codex/sql"),
}
SHA = re.compile(r"[a-f0-9]{64}\Z")


class ReleaseError(RuntimeError):
    pass


def require(condition, message):
    if not condition:
        raise ReleaseError(message)


def safe_path(path, absent=False):
    """Reject symlinks in every existing component, including the leaf."""
    path = Path(path)
    require(path.is_absolute() and ".." not in path.parts, f"Unsafe path: {path}")
    for part in reversed((path, *path.parents)):
        try:
            info = part.lstat()
        except FileNotFoundError:
            require(absent and part == path, f"Missing parent/path: {part}")
            return
        require(not stat.S_ISLNK(info.st_mode), f"Symlink refused: {part}")
        if part != path:
            require(stat.S_ISDIR(info.st_mode), f"Non-directory parent: {part}")


def sha256(path, allow_hardlinks=False):
    safe_path(path)
    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
    # Root can avoid access-time writes on Linux; contents never enter logs.
    noatime = getattr(os, "O_NOATIME", 0)
    try:
        fd = os.open(path, flags | noatime)
    except PermissionError:
        fd = os.open(path, flags)
    with os.fdopen(fd, "rb") as handle:
        first = os.fstat(handle.fileno())
        require(stat.S_ISREG(first.st_mode) and (allow_hardlinks or first.st_nlink == 1),
                f"Not an allowed regular file: {path}")
        digest = hashlib.sha256()
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
        last = os.fstat(handle.fileno())
        require((first.st_ino, first.st_size, first.st_mtime_ns, first.st_ctime_ns) ==
                (last.st_ino, last.st_size, last.st_mtime_ns, last.st_ctime_ns), f"Changed while reading: {path}")
    return digest.hexdigest()


def current_hash(path, allow_hardlinks=False):
    safe_path(path, absent=True)
    return sha256(path, allow_hardlinks=allow_hardlinks) if path.exists() else "ABSENT"


def xattrs(path):
    if not hasattr(os, "listxattr"):
        return {}
    try:
        return {name: base64.b64encode(os.getxattr(path, name, follow_symlinks=False)).decode("ascii")
                for name in sorted(os.listxattr(path, follow_symlinks=False))}
    except OSError as error:
        if error.errno in (errno.ENOTSUP, errno.EOPNOTSUPP):
            return {}
        raise


def metadata(path):
    safe_path(path)
    info = path.stat(follow_symlinks=False)
    require(stat.S_ISREG(info.st_mode), f"Not a regular file: {path}")
    return {"uid": info.st_uid, "gid": info.st_gid, "mode": stat.S_IMODE(info.st_mode),
            "mtime_ns": info.st_mtime_ns, "xattrs": xattrs(path)}


def apply_metadata(path, meta):
    os.chown(path, meta["uid"], meta["gid"], follow_symlinks=False)
    os.chmod(path, meta["mode"], follow_symlinks=False)
    os.utime(path, ns=(path.stat().st_atime_ns, meta["mtime_ns"]), follow_symlinks=False)
    existing = xattrs(path)
    for name in set(existing) - set(meta["xattrs"]):
        os.removexattr(path, name, follow_symlinks=False)
    for name, encoded in meta["xattrs"].items():
        os.setxattr(path, name, base64.b64decode(encoded, validate=True), follow_symlinks=False)
    require(metadata(path) == meta, f"Could not preserve metadata: {path}")


def sync_directory(path):
    fd = os.open(path, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0) | getattr(os, "O_NOFOLLOW", 0))
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def copy_exact(source, destination, meta):
    safe_path(source)
    safe_path(destination, absent=True)
    require(not destination.exists(), f"Destination already exists: {destination}")
    # Exclusive create; source/destination paths are private and previously checked.
    with source.open("rb") as src, destination.open("xb") as dst:
        shutil.copyfileobj(src, dst)
        dst.flush()
        os.fsync(dst.fileno())
    shutil.copystat(source, destination, follow_symlinks=False)
    apply_metadata(destination, meta)
    with destination.open("rb") as handle:
        os.fsync(handle.fileno())


class Release:
    def __init__(self, release, roots=ROOTS, new_owner=(0, 0)):
        # Injectable filesystem roots enable offline tests; the CLI has no override.
        self.release = Path(release)
        self.roots = {site: Path(path) for site, path in roots.items()}
        self.new_owner = new_owner
        self.state = None

    def target(self, row):
        return self.roots[row["site"]] / row["path"]

    def artifact(self, directory, row):
        return self.release / directory / row["site"] / row["path"]

    def event(self, action, **fields):
        path = self.release / "operations.jsonl"
        safe_path(path, absent=True)
        fd = os.open(path, os.O_WRONLY | os.O_APPEND | os.O_CREAT | getattr(os, "O_NOFOLLOW", 0), 0o600)
        with os.fdopen(fd, "a", encoding="utf-8") as handle:
            handle.write(json.dumps({"timeUTC": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                                     "action": action, **fields}, sort_keys=True) + "\n")
            handle.flush()
            os.fsync(handle.fileno())

    def save(self):
        fd, name = tempfile.mkstemp(prefix=".state-", dir=self.release)
        temporary = Path(name)
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as handle:
                json.dump(self.state, handle, indent=2, sort_keys=True)
                handle.write("\n")
                handle.flush()
                os.fsync(handle.fileno())
            safe_path(self.release / "state.json", absent=True)
            os.replace(temporary, self.release / "state.json")
            sync_directory(self.release)
        finally:
            temporary.unlink(missing_ok=True)

    def plan(self):
        path = self.release / "runtime.tsv"
        manifest_sha = sha256(path)
        lines = path.read_text(encoding="utf-8").splitlines()
        require(len(lines) == len(ORDER), "runtime.tsv must have exactly 11 rows; no header or blank rows")
        rows = []
        for expected, line in zip(ORDER, lines):
            parts = line.split("\t")
            require(len(parts) == 4, "runtime.tsv needs site, path, beforeSHA/ABSENT, afterSHA")
            site, path, before, after = parts
            require((site, path) == expected, f"Unexpected path/order: {site}/{path}; expected {expected}")
            require(bool(SHA.fullmatch(after)), f"Invalid candidate SHA: {site}/{path}")
            require(before == "ABSENT" if expected in NEW_FILES else bool(SHA.fullmatch(before)),
                    f"Wrong baseline/absence contract: {site}/{path}")
            require(before != after, f"Unchanged candidate refused: {site}/{path}")
            rows.append({"site": site, "path": path, "before": before, "after": after})
        require(sha256(self.release / "runtime.tsv") == manifest_sha, "Manifest changed while reading")
        return rows, manifest_sha

    def validate_layout(self, rows, candidates=True):
        device = self.release.stat().st_dev
        require(set(self.roots) == set(ROOTS), "Wrong site set")
        for root in self.roots.values():
            safe_path(root)
            require(root.is_dir(), f"Webroot is not a directory: {root}")
        for row in rows:
            target = self.target(row)
            safe_path(target, absent=True)
            require(target.parent.stat().st_dev == device, f"Release and target are on different filesystems: {target}")
            if candidates:
                candidate = self.artifact("candidate", row)
                require(sha256(candidate) == row["after"], f"Candidate hash mismatch: {candidate}")
                require(candidate.stat().st_dev == device, f"Candidate on a different filesystem: {candidate}")

    def guard_snapshot(self):
        result = {}
        for site, paths in GUARD_FILES.items():
            for path in paths:
                # Guards are read-only and may legitimately share an inode.
                result[f"{site}/{path}"] = current_hash(self.roots[site] / path, allow_hardlinks=True)
        for site, paths in GUARD_TREES.items():
            for path in paths:
                directory = self.roots[site] / path
                safe_path(directory, absent=True)
                result[f"{site}/{path}/"] = "DIRECTORY" if directory.exists() else "ABSENT"
                if not directory.exists():
                    continue
                require(directory.is_dir(), f"Protected tree is not a directory: {directory}")
                for current, directories, files in os.walk(directory, followlinks=False):
                    for child in sorted(directories + files):
                        entry = Path(current) / child
                        safe_path(entry)
                        relative = entry.relative_to(self.roots[site]).as_posix()
                        if (site, relative) in NEW_FILES:
                            continue
                        if entry.is_dir():
                            result[f"{site}/{relative}/"] = "DIRECTORY"
                        else:
                            result[f"{site}/{relative}"] = sha256(entry, allow_hardlinks=True)
        return result

    def check_guards(self):
        current = self.guard_snapshot()
        differences = sorted(key for key in set(current) | set(self.state["guards"])
                             if current.get(key) != self.state["guards"].get(key))
        require(not differences, "Protected files/inventory changed: " + ", ".join(differences))

    def check_before(self, rows):
        for row in rows:
            require(current_hash(self.target(row)) == row["before"],
                    f"Production baseline differs: {row['site']}/{row['path']}")
            if "metadata" in row and row["before"] != "ABSENT":
                require(metadata(self.target(row)) == row["metadata"],
                        f"Production metadata differs: {row['site']}/{row['path']}")

    def check_backups(self):
        for row in self.state["files"]:
            backup = self.artifact("before", row)
            if row["before"] == "ABSENT":
                require(not os.path.lexists(backup), f"Unexpected backup for originally absent file: {backup}")
            else:
                require(sha256(backup) == row["before"], f"Backup hash mismatch: {backup}")
                require(metadata(backup) == row["metadata"], f"Backup metadata mismatch: {backup}")

    def prepare(self, rows, manifest_sha):
        require(not os.path.lexists(self.release / "state.json") and not os.path.lexists(self.release / "before"),
                "Release already prepared or incomplete: use a new private release directory")
        self.validate_layout(rows)
        self.check_before(rows)
        guards = self.guard_snapshot()
        (self.release / "before").mkdir(mode=0o700)
        for row in rows:
            if row["before"] != "ABSENT":
                source = self.target(row)
                row["metadata"] = metadata(source)
                backup = self.artifact("before", row)
                backup.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
                safe_path(backup.parent)
                copy_exact(source, backup, row["metadata"])
                sync_directory(backup.parent)
            else:
                row["metadata"] = None
        self.state = {"version": 1, "manifestSHA": manifest_sha,
                      "roots": {key: str(value) for key, value in self.roots.items()},
                      "files": rows, "guards": guards, "phase": "prepared", "attempted": [],
                      "published": [], "rollbackConflicts": []}
        self.check_backups()
        self.check_before(rows)
        self.check_guards()
        self.save()
        self.event("prepared", existing=9, absent=2, guards=len(guards))

    def load(self, rows, manifest_sha):
        path = self.release / "state.json"
        sha256(path)
        self.state = json.loads(path.read_text(encoding="utf-8"))
        require(self.state.get("version") == 1 and self.state.get("manifestSHA") == manifest_sha,
                "Prepared state/manifest mismatch")
        require(self.state.get("roots") == {key: str(value) for key, value in self.roots.items()}, "Prepared roots mismatch")
        stored = [{key: row[key] for key in ("site", "path", "before", "after")} for row in self.state["files"]]
        require(stored == rows, "Prepared target list mismatch")
        require(all(type(index) is int and 0 <= index < len(ORDER) for index in self.state["attempted"]),
                "Invalid publication journal")

    def install(self, row, source, meta):
        target = self.target(row)
        fd, name = tempfile.mkstemp(prefix=".stage-", dir=self.release)
        os.close(fd)
        stage = Path(name)
        stage.unlink()
        try:
            copy_exact(source, stage, meta)
            require(sha256(stage) == row["after"], f"Staged hash mismatch: {target}")
            # Recheck immediately before the rename, after creating the full stage.
            self.check_before([row])
            if row["before"] == "ABSENT":
                # Atomic exclusive creation: another writer cannot be clobbered
                # between the absence check and publication of a new file.
                os.link(stage, target, follow_symlinks=False)
                stage.unlink()
            else:
                os.replace(stage, target)
            sync_directory(target.parent)
            sync_directory(self.release)
        finally:
            stage.unlink(missing_ok=True)

    def verify_published(self):
        for row in self.state["files"]:
            target = self.target(row)
            require(current_hash(target) == row["after"], f"Published hash differs: {target}")
            require(metadata(target) == row["publishedMetadata"], f"Published metadata differs: {target}")
        self.check_guards()

    def publish(self):
        require(self.state["phase"] == "prepared" and not self.state["attempted"], "Release is not fresh/prepared")
        rows = self.state["files"]
        self.validate_layout(rows)
        self.check_before(rows)
        self.check_backups()
        self.check_guards()
        try:
            self.state["phase"] = "publishing"
            self.save()
            for index, row in enumerate(rows):
                source = self.artifact("candidate", row)
                require(sha256(source) == row["after"], f"Candidate changed: {source}")
                baseline_meta = row["metadata"]
                if baseline_meta is None:
                    meta = {"uid": self.new_owner[0], "gid": self.new_owner[1], "mode": 0o644,
                            "mtime_ns": time.time_ns(), "xattrs": {}}
                else:
                    # CF template caches use mtime. Preserve ownership/mode/attrs,
                    # but do not publish changed code with the old timestamp.
                    meta = {**baseline_meta, "mtime_ns": max(time.time_ns(), baseline_meta["mtime_ns"] + 1_000_000_000)}
                row["publishedMetadata"] = meta
                self.state["attempted"].append(index)
                self.save()  # Durable intent before replacement also covers process interruption.
                self.event("install_intent", site=row["site"], path=row["path"])
                self.install(row, source, meta)
                self.state["published"].append(index)
                self.save()
                self.event("installed", site=row["site"], path=row["path"])
            self.verify_published()
            self.state["phase"] = "published"
            self.save()
            self.event("verified_published", targets=len(rows))
        except BaseException as error:
            # Rollback must still run if logging/state persistence is itself failing.
            try:
                self.event("publish_failed", reason=str(error))
            finally:
                try:
                    self.rollback()
                except BaseException as rollback_error:
                    raise ReleaseError(f"Publication failed: {error}; rollback needs review: {rollback_error}") from error
            raise ReleaseError(f"Publication failed; rollback phase={self.state['phase']}: {error}") from error

    def restore(self, row):
        target = self.target(row)
        observed = current_hash(target)
        if observed == row["before"]:
            if observed != "ABSENT":
                require(metadata(target) == row["metadata"], f"Baseline contents with changed metadata: {target}")
            return "already_before"
        require(observed == row["after"], f"Concurrent change preserved: {target}")
        require(metadata(target) == row["publishedMetadata"], f"Concurrent metadata change preserved: {target}")
        fd, name = tempfile.mkstemp(prefix=".rollback-", dir=self.release)
        os.close(fd)
        stage = Path(name)
        stage.unlink()
        try:
            if row["before"] == "ABSENT":
                # Keep removed new-file bytes as a recovery artifact, not an unlink.
                require(current_hash(target) == row["after"] and metadata(target) == row["publishedMetadata"],
                        f"Concurrent change preserved: {target}")
                os.replace(target, stage)
                sync_directory(target.parent)
                quarantine = self.release / ("removed-" + stage.name.lstrip("."))
                os.replace(stage, quarantine)
            else:
                backup = self.artifact("before", row)
                require(sha256(backup) == row["before"] and metadata(backup) == row["metadata"], f"Backup changed: {backup}")
                copy_exact(backup, stage, row["metadata"])
                require(sha256(stage) == row["before"], f"Restore stage hash differs: {target}")
                require(current_hash(target) == row["after"] and metadata(target) == row["publishedMetadata"],
                        f"Concurrent change preserved: {target}")
                os.replace(stage, target)
                sync_directory(target.parent)
            sync_directory(self.release)
            require(current_hash(target) == row["before"], f"Restoration verification failed: {target}")
            return "restored"
        finally:
            stage.unlink(missing_ok=True)

    def rollback(self):
        conflicts = []
        for index in reversed(self.state["attempted"]):
            row = self.state["files"][index]
            try:
                result = self.restore(row)
                self.event("rollback_" + result, site=row["site"], path=row["path"])
            except (OSError, ReleaseError) as error:
                conflicts.append(f"{row['site']}/{row['path']}: {error}")
        self.state["rollbackConflicts"] = conflicts
        self.state["phase"] = "rollback_conflict" if conflicts else "rolled_back"
        self.save()
        try:
            self.check_guards()
        except (OSError, ReleaseError) as error:
            self.event("guard_change_preserved", reason=str(error))
        self.event(self.state["phase"], conflicts=conflicts)
        require(not conflicts, "Rollback left concurrent changes untouched: " + "; ".join(conflicts))

    def run(self, mode):
        require(mode in ("prepare", "publish", "verify", "rollback"), "Invalid mode")
        safe_path(self.release)
        require(self.release.is_dir(), "Release is not a directory")
        require(stat.S_IMODE(self.release.stat().st_mode) == 0o700, "Release directory must have mode 0700")
        lock = self.release / "release.lock"
        safe_path(lock, absent=True)
        fd = os.open(lock, os.O_CREAT | os.O_RDWR | getattr(os, "O_NOFOLLOW", 0), 0o600)
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            rows, manifest_sha = self.plan()
            if mode == "prepare":
                self.prepare(rows, manifest_sha)
            else:
                self.load(rows, manifest_sha)
                if mode == "publish":
                    self.publish()
                elif mode == "rollback":
                    self.rollback()
                else:
                    self.validate_layout(rows, candidates=False)
                    self.check_backups()
                    if self.state["phase"] == "published":
                        self.verify_published()
                    elif self.state["phase"] in ("prepared", "rolled_back"):
                        self.check_before(self.state["files"])
                        self.check_guards()
                    else:
                        raise ReleaseError(f"Incomplete release ({self.state['phase']}): run rollback or review conflicts")
                    self.event("verified", phase=self.state["phase"])
            return self.state["phase"]
        finally:
            os.close(fd)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("release", help="/var/backups/rr-live-measurement.<alphanumeric>")
    parser.add_argument("mode", choices=("prepare", "publish", "verify", "rollback"))
    args = parser.parse_args()
    try:
        require(bool(re.fullmatch(r"/var/backups/rr-live-measurement\.[A-Za-z0-9]+", args.release)), "Unexpected release directory")
        require(os.geteuid() == 0, "Run the reviewed CLI as root on the server")
        safe_path(Path(args.release))
        require(Path(args.release).stat().st_uid == 0, "Release directory must be root-owned")
        os.umask(0o077)
        def interrupted(number, frame):
            raise ReleaseError(f"Interrupted by signal {number}")
        for number in (signal.SIGTERM, signal.SIGHUP):
            signal.signal(number, interrupted)
        phase = Release(Path(args.release)).run(args.mode)
        print(f"{args.mode}: {phase}; 11 whitelisted runtime targets; details in operations.jsonl")
    except (OSError, ValueError, KeyError, ReleaseError) as error:
        print(f"STOP: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
