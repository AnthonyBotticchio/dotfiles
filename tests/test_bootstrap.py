"""Run with python3 -m unittest discover -s tests -v; requires GNU Stow."""

import gzip
import io
import os
from pathlib import Path
import shutil
import shlex
import subprocess
import sys
import tarfile
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
STOW = shutil.which("stow")


@unittest.skipUnless(STOW, "GNU Stow is required for config-linking checks")
class BootstrapTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles-bootstrap-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.bin = self.root / "bin"
        self.home.mkdir()
        self.bin.mkdir()
        self.log = self.root / "calls"
        self.log.touch()
        self.env = {
            "HOME": str(self.home), "PATH": str(self.bin),
            "TEST_LOG": str(self.log), "TEST_OS": "Linux",
            "TEST_ARCH": "x86_64", "TEST_NVIM_EXIT": "0",
            "TEST_TS_VERSION": "0.27.1", "LC_ALL": "C",
        }
        for name in ("bash", "dirname", "mktemp", "rm", "mkdir", "mv", "ln",
                     "chmod", "tar", "gzip", "perl", "cp"):
            (self.bin / name).symlink_to(shutil.which(name))
        for name in ("git", "vim", "tmux", "unzip", "make", "rg", "python3", "cc"):
            (self.bin / name).symlink_to(shutil.which("true"))
        (self.bin / "stow").symlink_to(STOW)
        self.script("uname", 'case "$1" in -s) echo "$TEST_OS";; -m) echo "$TEST_ARCH";; esac')
        self.script("git", '\n'.join([
            'case "$3" in',
            'https://github.com/ohmyzsh/ohmyzsh.git) mkdir -p "$4"; : > "$4/oh-my-zsh.sh";;',
            'https://github.com/romkatv/powerlevel10k.git) mkdir -p "$4"; : > "$4/powerlevel10k.zsh-theme";;',
            '*) exit 90;;',
            'esac',
            'echo "git clone $3" >> "$TEST_LOG"',
        ]))
        self.script("zsh", "exit 0")
        self.script("nvim", 'exit "$TEST_NVIM_EXIT"')
        self.script("tree-sitter", 'echo "tree-sitter $TEST_TS_VERSION"')
        for name in ("curl", "sudo", "apt", "dnf", "brew", "npm", "srun", "sbatch"):
            self.script(name, f'echo "FORBIDDEN {name} $*" >> "$TEST_LOG"; exit 90')

    def script(self, name, body):
        path = self.bin / name
        path.unlink(missing_ok=True)
        path.write_text("#!/bin/sh\n" + body + "\n")
        path.chmod(0o755)

    def run_bootstrap(self, *args, success=True):
        result = subprocess.run(
            [str(REPO / "bootstrap.sh"), *args], env=self.env, cwd=REPO,
            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30,
        )
        self.assertEqual(result.returncode == 0, success, result.stdout)
        self.assertNotIn("FORBIDDEN", self.log.read_text())
        return result.stdout

    def assert_links(self):
        for package, relative in (("vim", ".vimrc"), ("nvim", ".config/nvim"),
                                  ("tmux", ".tmux.conf"), ("git", ".gitconfig")):
            self.assertEqual((self.home / relative).resolve(), REPO / package / relative)
        self.assertFalse((self.home / ".config/kitty").exists())

    def assert_zsh_links(self):
        for name in (".zshrc", ".p10k.zsh"):
            self.assertEqual((self.home / name).resolve(), REPO / "zsh" / name)
        self.assertTrue((self.home / ".oh-my-zsh/oh-my-zsh.sh").is_file())
        self.assertTrue((self.home / ".oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme").is_file())

    def downloads(self, *, incompatible=False):
        fixtures = self.root / "downloads"
        fixtures.mkdir()
        archive = f"nvim-linux-{self.env['TEST_ARCH'].replace('aarch64', 'arm64')}"
        nvim = b"#!/bin/sh\nexit " + (b"1" if incompatible else b"0") + b"\n"
        with tarfile.open(fixtures / f"{archive}.tar.gz", "w:gz") as output:
            entry = tarfile.TarInfo(f"{archive}/bin/nvim")
            entry.mode, entry.size = 0o755, len(nvim)
            output.addfile(entry, io.BytesIO(nvim))
        arch = "x64" if self.env["TEST_ARCH"] == "x86_64" else "arm64"
        version = "0.25.0" if incompatible else "0.27.1"
        with gzip.open(fixtures / f"tree-sitter-linux-{arch}.gz", "wb") as output:
            output.write(f'#!/bin/sh\necho "tree-sitter {version}"\n'.encode())
        self.env["TEST_DOWNLOADS"] = str(fixtures)
        self.script("curl", "exec " + shlex.quote(sys.executable) + " -c '" + "\n".join([
            "import os, pathlib, shutil, sys",
            'args = sys.argv[1:]',
            'url = next(arg for arg in args if arg.startswith("https://"))',
            'with open(os.environ["TEST_LOG"], "a") as log: log.write(url + "\\n")',
            'shutil.copyfile(pathlib.Path(os.environ["TEST_DOWNLOADS"]) / url.rsplit("/", 1)[1], args[args.index("-o") + 1])',
        ]) + "' \"$@\"")

    def test_reuse_backup_and_repeat_with_real_stow(self):
        (self.home / ".vimrc").write_text("original vim\n")
        (self.home / ".config/nvim").mkdir(parents=True)
        (self.home / ".config/nvim/init.lua").write_text("original nvim\n")
        (self.home / ".zshrc").write_text("original zsh\n")
        (self.home / ".p10k.zsh").write_text("original prompt\n")
        self.run_bootstrap("--cluster", "--backup")
        self.assert_links()
        self.assert_zsh_links()
        backups = list(self.home.glob(".dotfiles-backup.*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / ".vimrc").read_text(), "original vim\n")
        self.assertEqual((backups[0] / ".config/nvim/init.lua").read_text(), "original nvim\n")
        shell_backups = list(self.home.glob(".zsh-backup.*"))
        self.assertEqual(len(shell_backups), 1)
        self.assertEqual((shell_backups[0] / ".zshrc").read_text(), "original zsh\n")
        self.assertEqual((shell_backups[0] / ".p10k.zsh").read_text(), "original prompt\n")
        calls = self.log.read_text()
        self.run_bootstrap("--cluster", "--backup")
        self.assert_links()
        self.assert_zsh_links()
        self.assertEqual((backups[0] / ".vimrc").read_text(), "original vim\n")
        self.assertEqual(list(self.home.glob(".zsh-backup.*")), shell_backups)
        self.assertEqual(self.log.read_text(), calls)

    def test_missing_prerequisite_stops_before_changes(self):
        (self.bin / "rg").unlink()
        output = self.run_bootstrap("--cluster", "--backup", success=False)
        self.assertIn("Missing cluster tools: rg", output)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_conflict_without_backup_preserves_file(self):
        (self.home / ".vimrc").write_text("keep me\n")
        self.run_bootstrap("--cluster", success=False)
        self.assertEqual((self.home / ".vimrc").read_text(), "keep me\n")
        self.assertFalse((self.home / ".gitconfig").exists())

    def test_binary_downloads_and_repeat(self):
        for arch in ("x86_64", "aarch64"):
            with self.subTest(arch=arch):
                self.env.update(TEST_ARCH=arch, TEST_NVIM_EXIT="1", TEST_TS_VERSION="0.25.0")
                self.downloads()
                self.run_bootstrap("--cluster", "--backup")
                self.assert_links()
                for name in ("nvim", "tree-sitter"):
                    path = self.home / ".local/bin" / name
                    self.assertTrue(path.is_symlink())
                    self.assertTrue(path.resolve().is_relative_to(self.home.resolve() / ".local/opt"))
                calls = self.log.read_text()
                self.run_bootstrap("--cluster", "--backup")
                self.assertEqual(self.log.read_text(), calls)
                if arch == "x86_64":
                    shutil.rmtree(self.home)
                    self.home.mkdir()
                    shutil.rmtree(self.root / "downloads")

    def test_incompatible_download_is_not_activated(self):
        self.env["TEST_TS_VERSION"] = "0.25.0"
        self.downloads(incompatible=True)
        self.run_bootstrap("--cluster", "--backup", success=False)
        self.assertFalse((self.home / ".local/bin/tree-sitter").exists())
        self.assertFalse((self.home / ".vimrc").exists())

    def test_failed_download_preserves_existing_link_and_configs(self):
        self.env["TEST_NVIM_EXIT"] = "1"
        path = self.home / ".local/bin/nvim"
        path.parent.mkdir(parents=True)
        path.symlink_to(self.bin / "nvim")
        (self.home / ".vimrc").write_text("original vim\n")
        self.script("curl", "exit 22")
        self.run_bootstrap("--cluster", "--backup", success=False)
        self.assertEqual(path.readlink(), self.bin / "nvim")
        self.assertEqual((self.home / ".vimrc").read_text(), "original vim\n")
        self.assertEqual(list(self.home.glob(".dotfiles-backup.*")), [])

    def test_existing_local_executable_is_not_overwritten(self):
        for name in ("nvim", "tree-sitter"):
            with self.subTest(name=name):
                path = self.home / ".local/bin" / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("#!/bin/sh\nexit 1\n")
                path.chmod(0o755)
                self.run_bootstrap("--cluster", "--backup", success=False)
                self.assertEqual(path.read_text(), "#!/bin/sh\nexit 1\n")
                path.unlink()

    def test_version_floor_and_nonstandard_architecture(self):
        self.env.update(TEST_ARCH="ppc64le", TEST_TS_VERSION="0.26.1")
        self.run_bootstrap("--cluster", "--backup")
        self.assert_links()
        self.env["TEST_TS_VERSION"] = "0.26.0"
        output = self.run_bootstrap("--cluster", success=False)
        self.assertIn("Install Tree-sitter CLI 0.26.1+", output)

    def test_cluster_rejects_macos(self):
        self.env["TEST_OS"] = "Darwin"
        self.assertIn("--cluster requires Linux", self.run_bootstrap("--cluster", success=False))
        self.assertEqual(list(self.home.iterdir()), [])

    def test_macos_minimal_still_links_default_packages(self):
        self.env["TEST_OS"] = "Darwin"
        self.script("brew", 'echo "brew $*" >> "$TEST_LOG"')
        self.run_bootstrap("--minimal", "--backup")
        self.assert_links()
        self.assertNotIn("--cask", self.log.read_text())

    def test_cluster_builds_missing_zsh_in_user_prefix(self):
        (self.bin / "zsh").unlink()
        (self.bin / "xz").symlink_to(shutil.which("xz"))
        fixtures = self.root / "downloads"
        fixtures.mkdir()
        files = {
            "configure": '#!/bin/sh\nprintf "%s\\n" "${1#--prefix=}" > prefix\n',
            "zsh": '#!/bin/sh\necho "zsh 5.9.2"\n',
        }
        with tarfile.open(fixtures / "zsh-5.9.2.tar.xz", "w:xz") as output:
            for name, body in files.items():
                data = body.encode()
                entry = tarfile.TarInfo(f"zsh-5.9.2/{name}")
                entry.mode, entry.size = 0o755, len(data)
                output.addfile(entry, io.BytesIO(data))
        self.script("curl", f'exec cp "{fixtures}/zsh-5.9.2.tar.xz" "$6"')
        self.script("make", '\n'.join([
            'echo "make $*" >> "$TEST_LOG"',
            'test "$1" = -j1 || exit 91',
            'if test "${2:-}" = install; then',
            '    IFS= read -r prefix < prefix',
            '    mkdir -p "$prefix/bin"',
            '    cp zsh "$prefix/bin/zsh"',
            'fi',
        ]))
        self.run_bootstrap("--cluster", "--backup")
        self.assert_links()
        self.assert_zsh_links()
        zsh = self.home / ".local/bin/zsh"
        self.assertTrue(zsh.is_symlink())
        self.assertTrue(zsh.resolve().is_relative_to(self.home.resolve() / ".local/opt"))
        self.assertIn("make -j1 install", self.log.read_text())
        calls = self.log.read_text()
        self.run_bootstrap("--cluster", "--backup")
        self.assertEqual(self.log.read_text(), calls)

    def test_zsh_build_failure_keeps_shell_configs(self):
        (self.bin / "zsh").unlink()
        (self.bin / "xz").symlink_to(shutil.which("xz"))
        (self.home / ".zshrc").write_text("original zsh\n")
        self.script("curl", "exit 22")
        self.run_bootstrap("--cluster", "--backup", success=False)
        self.assertEqual((self.home / ".zshrc").read_text(), "original zsh\n")
        self.assertFalse((self.home / ".local/bin/zsh").exists())

    def test_zsh_only_cluster_setup_uses_no_system_installer(self):
        result = subprocess.run(
            [str(REPO / "install-zsh.sh"), "--cluster"], env=self.env,
            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertNotIn("FORBIDDEN", self.log.read_text())
        self.assert_zsh_links()


if __name__ == "__main__":
    unittest.main()
