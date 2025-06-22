#!/usr/bin/env python3
"""Comprehensive test suite for dot.py v2.0 - Modern dotfiles management.

Tests the new provisioner architecture, async command execution,
staged shell initialization, and modern Python 3.12+ features.

Run with: uv run py.test test_dot.py --cov -v
"""

from __future__ import annotations

import logging
import os
import pathlib
import subprocess
import sys
import tomllib
import typing
import unittest.mock
from unittest.mock import patch

import pytest

if typing.TYPE_CHECKING:
    import collections.abc

    import pytest

# Import our v2.0 module
import dot

# ═══════════════════════════════════════════════════════════════════════════════
# FIXTURES
# ═══════════════════════════════════════════════════════════════════════════════


@pytest.fixture
def temp_home(
    tmp_path: pathlib.Path,
) -> collections.abc.Generator[pathlib.Path, None, None]:
    """Create temporary home directory for testing."""
    home_dir = tmp_path / "home"
    home_dir.mkdir()

    with unittest.mock.patch("pathlib.Path.home", return_value=home_dir):
        yield home_dir


@pytest.fixture
def sample_toml_config() -> str:
    """Sample TOML configuration for testing."""
    return """
[config]
source = "~/.dot-config"
backup = true

[template_vars]
email = "test@example.com"
work_machine = true

[home.files]
".gitconfig" = ".gitconfig"
".zshrc" = ".zshrc"

[home.dirs]
".vim" = ".vim"

[foundation.build_tools]
managers = { apt = "build-essential", brew = "gcc" }
essential = true

[provisioners.rust]
description = "Rust toolchain"
type = "provisioner"
install_method = "script"
install_script = "curl https://sh.rustup.rs | sh"
provides = ["cargo", "rustc"]
requires = ["curl"]
priority = 3
verify_command = "cargo --version"
shell_integration = true
stage = 5

[enhancements.starship]
description = "Cross-shell prompt"
type = "enhancement"
install_method = "script"
install_script = "curl -sS https://starship.rs/install.sh | sh"
provides = ["starship"]
requires = ["curl"]
priority = 7
verify_command = "starship --version"
shell_integration = true
stage = 9

[shell_integration.snippets.early_env]
name = "early_env"
description = "Early environment setup"
stage = 0
default = "export DOT_LOADED=1"

[shell_integration.snippets.starship_init]
name = "starship_init"
description = "Initialize Starship prompt"
stage = 9
condition = "command -v starship"
bash = 'eval "$(starship init bash)"'
zsh = 'eval "$(starship init zsh)"'
fish = 'starship init fish | source'
"""


@pytest.fixture
def config_with_provisioners(
    tmp_path: pathlib.Path,
    sample_toml_config: str,
) -> dot.DotfilesConfig:
    """Create config file and return ConfigLoader."""
    config_file = tmp_path / "dot.toml"
    config_file.write_text(sample_toml_config)

    loader = dot.ConfigLoader(config_file)
    return loader.load()


# ═══════════════════════════════════════════════════════════════════════════════
# TYPE SYSTEM TESTS
# ═══════════════════════════════════════════════════════════════════════════════


class TestTypeSystem:
    """Test modern type system and enums."""

    def test_provisioner_type_enum(self) -> None:
        """Test ProvisionerType enum values."""
        assert dot.ProvisionerType.FOUNDATION.name == "FOUNDATION"
        assert dot.ProvisionerType.PROVISIONER.name == "PROVISIONER"
        assert dot.ProvisionerType.ENHANCEMENT.name == "ENHANCEMENT"

    def test_install_method_enum(self) -> None:
        """Test InstallMethod enum values."""
        assert dot.InstallMethod.SCRIPT.name == "SCRIPT"
        assert dot.InstallMethod.PACKAGE.name == "PACKAGE"
        assert dot.InstallMethod.BINARY.name == "BINARY"

    def test_shell_stage_enum(self) -> None:
        """Test ShellStage enum with numeric values."""
        assert dot.ShellStage.EARLY.value == 0
        assert dot.ShellStage.MAIN.value == 5
        assert dot.ShellStage.LATE.value == 9

    def test_newtype_paths(self) -> None:
        """Test NewType path safety."""
        source = dot.SourcePath(pathlib.Path("/src"))
        dest = dot.DestPath(pathlib.Path("/dest"))

        assert isinstance(source, pathlib.Path)
        assert isinstance(dest, pathlib.Path)


# ═══════════════════════════════════════════════════════════════════════════════
# DATACLASS TESTS
# ═══════════════════════════════════════════════════════════════════════════════


class TestDataClasses:
    """Test modern dataclasses with slots."""

    def test_system_info_immutable(self) -> None:
        """Test SystemInfo is immutable (frozen)."""
        info = dot.SystemInfo(
            os="linux",
            hostname="test",
            arch="x86_64",
            distro="ubuntu",
            is_linux=True,
            is_macos=False,
            is_wsl=False,
            home=pathlib.Path("/home/user"),
            user="user",
        )

        # Should be frozen
        with pytest.raises(AttributeError):
            info.os = "windows"  # type: ignore[misc]

    def test_provisioner_with_slots(self) -> None:
        """Test Provisioner dataclass with slots."""
        prov = dot.Provisioner(
            name="rust",
            description="Rust toolchain",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=frozenset(["cargo", "rustc"]),
            requires=frozenset(["curl"]),
            verify_command="cargo --version",
        )

        assert prov.name == "rust"
        assert prov.type == dot.ProvisionerType.PROVISIONER
        assert "cargo" in prov.provides
        assert prov.priority == 5  # default

    def test_provisioner_post_init(self) -> None:
        """Test Provisioner.__post_init__ converts lists to frozensets."""
        prov = dot.Provisioner(
            name="test",
            description="Test",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=["tool1", "tool2"],  # type: ignore[arg-type]
            requires=["dep1"],  # type: ignore[arg-type]
        )

        assert isinstance(prov.provides, frozenset)
        assert isinstance(prov.requires, frozenset)
        assert prov.provides == frozenset(["tool1", "tool2"])

    def test_shell_snippet_get_content(self) -> None:
        """Test ShellSnippet.get_content() method."""
        snippet = dot.ShellSnippet(
            name="test",
            description="Test snippet",
            stage=dot.ShellStage.MAIN,
            bash='echo "bash"',
            zsh='echo "zsh"',
            fish='echo "fish"',
            default='echo "{shell}"',
        )

        assert snippet.get_content("bash") == 'echo "bash"'
        assert snippet.get_content("zsh") == 'echo "zsh"'
        assert snippet.get_content("fish") == 'echo "fish"'
        # Test fallback for unsupported shell (type: ignore for test purposes)
        assert snippet.get_content("powershell") == 'echo "powershell"'  # type: ignore[arg-type]

    def test_command_result_dataclass(self) -> None:
        """Test CommandResult dataclass."""
        result = dot.CommandResult(
            success=True,
            stdout="output",
            stderr="",
            returncode=0,
            duration=1.5,
        )

        assert result.success is True
        assert result.stdout == "output"
        assert result.duration == 1.5


# ═══════════════════════════════════════════════════════════════════════════════
# PLATFORM DETECTION TESTS
# ═══════════════════════════════════════════════════════════════════════════════


class TestPlatform:
    """Test enhanced platform detection with pattern matching."""

    def test_platform_init(self) -> None:
        """Test Platform initialization."""
        platform_obj = dot.Platform()

        assert hasattr(platform_obj, "info")
        assert isinstance(platform_obj.info, dot.SystemInfo)

    @patch("platform.system")
    @patch("platform.node")
    @patch("platform.machine")
    def test_detect_linux(
        self,
        mock_machine: typing.Any,
        mock_node: typing.Any,
        mock_system: typing.Any,
    ) -> None:
        """Test Linux detection."""
        mock_system.return_value = "Linux"
        mock_node.return_value = "testhost"
        mock_machine.return_value = "x86_64"

        with (
            patch.object(dot.Platform, "_detect_wsl", return_value=False),
            patch.object(dot.Platform, "_detect_distro", return_value="ubuntu"),
        ):
            platform_obj = dot.Platform()

            assert platform_obj.info.is_linux is True
            assert platform_obj.info.is_macos is False
            assert platform_obj.info.distro == "ubuntu"

    @patch("platform.system")
    def test_detect_macos(self, mock_system: typing.Any) -> None:
        """Test macOS detection."""
        mock_system.return_value = "Darwin"

        platform_obj = dot.Platform()

        assert platform_obj.info.is_macos is True
        assert platform_obj.info.is_linux is False
        assert platform_obj.info.distro is None

    def test_get_package_manager_pattern_matching(self) -> None:
        """Test package manager detection with pattern matching."""
        with (
            patch("platform.system"),
            patch("platform.node"),
            patch("platform.machine"),
        ):
            platform_obj = dot.Platform()

            # Test macOS scenario
            mock_info = dot.SystemInfo(
                os="darwin",
                hostname="test",
                arch="x86_64",
                distro=None,
                is_linux=False,
                is_macos=True,
                is_wsl=False,
                home=pathlib.Path("/Users/test"),
                user="test",
            )
            platform_obj.info = mock_info
            with unittest.mock.patch(
                "shutil.which",
                return_value="/usr/local/bin/brew",
            ):
                assert platform_obj.get_package_manager() == "brew"

            # Test Ubuntu scenario
            mock_info = dot.SystemInfo(
                os="linux",
                hostname="test",
                arch="x86_64",
                distro="ubuntu",
                is_linux=True,
                is_macos=False,
                is_wsl=False,
                home=pathlib.Path("/home/test"),
                user="test",
            )
            platform_obj.info = mock_info
            assert platform_obj.get_package_manager() == "apt"

            # Test Fedora scenario
            mock_info = dot.SystemInfo(
                os="linux",
                hostname="test",
                arch="x86_64",
                distro="fedora",
                is_linux=True,
                is_macos=False,
                is_wsl=False,
                home=pathlib.Path("/home/test"),
                user="test",
            )
            platform_obj.info = mock_info
            assert platform_obj.get_package_manager() == "dnf"


# ═══════════════════════════════════════════════════════════════════════════════
# ASYNC COMMAND RUNNER TESTS
# ═══════════════════════════════════════════════════════════════════════════════


class TestAsyncCommandRunner:
    """Test async command execution with TaskGroup."""

    @pytest.mark.asyncio
    async def test_runner_init(self) -> None:
        """Test AsyncCommandRunner initialization."""
        runner = dot.AsyncCommandRunner(dry_run=True)
        assert runner.dry_run is True

        runner = dot.AsyncCommandRunner(dry_run=False)
        assert runner.dry_run is False

    @pytest.mark.asyncio
    async def test_dry_run_mode(self) -> None:
        """Test dry run mode doesn't execute commands."""
        runner = dot.AsyncCommandRunner(dry_run=True)

        result = await runner.run("rm -rf /")

        assert result.success is True
        assert result.stdout == ""
        assert result.stderr == ""

    @pytest.mark.asyncio
    async def test_successful_command(self) -> None:
        """Test successful command execution."""
        runner = dot.AsyncCommandRunner(dry_run=False)

        result = await runner.run("echo 'test'", shell=True, capture=True)

        assert result.success is True
        assert "test" in result.stdout
        assert result.returncode == 0
        assert result.duration > 0

    @pytest.mark.asyncio
    async def test_failed_command(self) -> None:
        """Test failed command handling."""
        runner = dot.AsyncCommandRunner(dry_run=False)

        result = await runner.run("exit 1", check=False, shell=True)

        assert result.success is False
        assert result.returncode == 1

    @pytest.mark.asyncio
    async def test_run_many_concurrent(self) -> None:
        """Test running multiple commands with concurrency control."""
        runner = dot.AsyncCommandRunner(dry_run=False)

        commands = ["echo 'cmd1'", "echo 'cmd2'", "echo 'cmd3'"]
        results = await runner.run_many(commands, max_concurrent=2)

        assert len(results) == 3
        assert all(result.success for result in results)
        assert "cmd1" in results[0].stdout
        assert "cmd2" in results[1].stdout
        assert "cmd3" in results[2].stdout


# ═══════════════════════════════════════════════════════════════════════════════
# CONFIG LOADER TESTS
# ═══════════════════════════════════════════════════════════════════════════════


class TestConfigLoader:
    """Test modern TOML configuration loading."""

    def test_config_loader_init(self, tmp_path: pathlib.Path) -> None:
        """Test ConfigLoader initialization."""
        config_path = tmp_path / "test.toml"
        loader = dot.ConfigLoader(config_path)

        assert loader.config_path == config_path

    def test_config_loader_default_path(self) -> None:
        """Test default config path."""
        loader = dot.ConfigLoader()
        assert loader.config_path == pathlib.Path.cwd() / "dot.toml"

    def test_load_missing_file(self, tmp_path: pathlib.Path) -> None:
        """Test loading missing config file returns defaults."""
        config_path = tmp_path / "missing.toml"
        loader = dot.ConfigLoader(config_path)

        config = loader.load()

        assert isinstance(config, dot.DotfilesConfig)
        assert config.source == pathlib.Path("~/.dot-config")

    def test_load_basic_config(
        self,
        tmp_path: pathlib.Path,
        sample_toml_config: str,
    ) -> None:
        """Test loading basic configuration."""
        config_path = tmp_path / "test.toml"
        config_path.write_text(sample_toml_config)

        loader = dot.ConfigLoader(config_path)
        config = loader.load()

        # Test basic config (now expanded)
        assert config.source == pathlib.Path.home() / ".dot-config"
        assert config.backup is True

        # Test template vars
        assert config.template_vars["email"] == "test@example.com"
        assert config.template_vars["work_machine"] is True

        # Test file mappings
        assert dot.DestPath(pathlib.Path(".gitconfig")) in config.files
        assert config.files[
            dot.DestPath(pathlib.Path(".gitconfig"))
        ].source == dot.SourcePath(
            pathlib.Path(".gitconfig"),
        )

        # Test provisioners
        assert "rust" in config.provisioners
        rust = config.provisioners["rust"]
        assert rust.type == dot.ProvisionerType.PROVISIONER
        assert rust.install_method == dot.InstallMethod.SCRIPT
        assert "cargo" in rust.provides
        assert rust.priority == 3

        # Test enhancements
        assert "starship" in config.enhancements
        starship = config.enhancements["starship"]
        assert starship.type == dot.ProvisionerType.ENHANCEMENT
        assert starship.stage == dot.ShellStage.LATE

    def test_parse_shell_snippets(
        self,
        tmp_path: pathlib.Path,
        sample_toml_config: str,
    ) -> None:
        """Test parsing shell integration snippets."""
        config_path = tmp_path / "test.toml"
        config_path.write_text(sample_toml_config)

        loader = dot.ConfigLoader(config_path)
        config = loader.load()

        snippets = config.shell_snippets
        assert len(snippets) > 0

        # Find starship snippet
        starship_snippet = next(s for s in snippets if s.name == "starship_init")
        assert starship_snippet.description == "Initialize Starship prompt"
        assert starship_snippet.stage == dot.ShellStage.LATE
        assert starship_snippet.bash == 'eval "$(starship init bash)"'
        assert starship_snippet.fish == "starship init fish | source"

    def test_invalid_toml(self, tmp_path: pathlib.Path) -> None:
        """Test handling invalid TOML syntax."""
        config_path = tmp_path / "invalid.toml"
        config_path.write_text("[invalid toml")

        loader = dot.ConfigLoader(config_path)

        with pytest.raises(tomllib.TOMLDecodeError):
            loader.load()

    def test_parse_packages(self, tmp_path: pathlib.Path) -> None:
        """Test parsing packages section from TOML."""
        config_toml = """
[packages.apt]
packages = ["build-essential", "git", "curl", "zlib1g-dev"]

[packages.apt.groups]
minimal = []
development = ["python3-dev", "llvm"]
full = ["python3-dev", "llvm", "cmake"]

[packages.brew]
packages = ["git", "curl"]
        """
        config_path = tmp_path / "test.toml"
        config_path.write_text(config_toml)

        loader = dot.ConfigLoader(config_path)
        config = loader.load()

        # Test apt packages were loaded
        assert "apt" in config.packages
        assert config.packages["apt"]["packages"] == [
            "build-essential",
            "git",
            "curl",
            "zlib1g-dev",
        ]
        assert config.packages["apt"]["groups"]["minimal"] == []
        assert config.packages["apt"]["groups"]["development"] == [
            "python3-dev",
            "llvm",
        ]
        assert config.packages["apt"]["groups"]["full"] == [
            "python3-dev",
            "llvm",
            "cmake",
        ]

        # Test brew packages were loaded
        assert "brew" in config.packages
        assert config.packages["brew"]["packages"] == ["git", "curl"]


# ═══════════════════════════════════════════════════════════════════════════════
# DEPENDENCY RESOLVER TESTS
# ═══════════════════════════════════════════════════════════════════════════════


class TestDependencyResolver:
    """Test simple priority-based dependency resolution."""

    def test_resolver_init(self, config_with_provisioners) -> None:
        """Test DependencyResolver initialization."""
        all_provisioners = {
            **config_with_provisioners.provisioners,
            **config_with_provisioners.enhancements,
        }
        resolver = dot.DependencyResolver(all_provisioners)

        assert len(resolver.provisioners) == 2  # rust + starship
        assert "cargo" in resolver._provides_map
        assert "starship" in resolver._provides_map

    def test_get_install_order_by_priority(self, config_with_provisioners) -> None:
        """Test installation order respects priority."""
        all_provisioners = {
            **config_with_provisioners.provisioners,
            **config_with_provisioners.enhancements,
        }
        resolver = dot.DependencyResolver(all_provisioners)

        order = resolver.get_install_order()

        # rust (priority 3) should come before starship (priority 7)
        rust_idx = order.index("rust")
        starship_idx = order.index("starship")
        assert rust_idx < starship_idx

    def test_check_requirements(self, config_with_provisioners) -> None:
        """Test requirement checking."""
        all_provisioners = {
            **config_with_provisioners.provisioners,
            **config_with_provisioners.enhancements,
        }
        resolver = dot.DependencyResolver(all_provisioners)

        rust = config_with_provisioners.provisioners["rust"]

        with unittest.mock.patch("shutil.which", return_value="/usr/bin/curl"):
            all_met, missing = resolver.check_requirements(rust)
            assert all_met is True
            assert missing == []

        with unittest.mock.patch("shutil.which", return_value=None):
            all_met, missing = resolver.check_requirements(rust)
            assert all_met is False
            assert "curl" in missing

    def test_find_provider(self, config_with_provisioners: dot.DotfilesConfig) -> None:
        """Test finding provider for a tool."""
        all_provisioners = {
            **config_with_provisioners.provisioners,
            **config_with_provisioners.enhancements,
        }
        resolver = dot.DependencyResolver(all_provisioners)

        assert resolver.find_provider("cargo") == "rust"
        assert resolver.find_provider("starship") == "starship"
        assert resolver.find_provider("nonexistent") is None


# ═══════════════════════════════════════════════════════════════════════════════
# SHELL GENERATOR TESTS
# ═══════════════════════════════════════════════════════════════════════════════


class TestShellGenerator:
    """Test staged shell initialization generation."""

    def test_shell_generator_init(self) -> None:
        """Test ShellGenerator initialization."""
        platform_obj = dot.Platform()
        generator = dot.ShellGenerator(platform_obj)

        assert generator.platform == platform_obj

    def test_generate_staged_init_single_stage(self) -> None:
        """Test generating single stage initialization."""
        platform_obj = dot.Platform()
        generator = dot.ShellGenerator(platform_obj)

        snippets = [
            dot.ShellSnippet(
                name="early_test",
                description="Early stage test",
                stage=dot.ShellStage.EARLY,
                default="export TEST=early",
            ),
            dot.ShellSnippet(
                name="late_test",
                description="Late stage test",
                stage=dot.ShellStage.LATE,
                default="export TEST=late",
            ),
        ]

        early_init = generator.generate_staged_init("zsh", snippets, "early")

        assert "early" in early_init
        assert "late" not in early_init

    def test_generate_complete_init(self) -> None:
        """Test generating complete initialization with all stages."""
        platform_obj = dot.Platform()
        generator = dot.ShellGenerator(platform_obj)

        snippets = [
            dot.ShellSnippet(
                name="early_test",
                description="Early stage",
                stage=dot.ShellStage.EARLY,
                default="export EARLY=1",
            ),
            dot.ShellSnippet(
                name="main_test",
                description="Main stage",
                stage=dot.ShellStage.MAIN,
                default="export MAIN=1",
            ),
            dot.ShellSnippet(
                name="late_test",
                description="Late stage",
                stage=dot.ShellStage.LATE,
                default="export LATE=1",
            ),
        ]

        complete_init = generator.generate_staged_init("zsh", snippets)

        assert "EARLY STAGE" in complete_init
        assert "MAIN STAGE" in complete_init
        assert "LATE STAGE" in complete_init
        assert "EARLY=1" in complete_init
        assert "MAIN=1" in complete_init
        assert "LATE=1" in complete_init

    def test_shell_specific_content(self) -> None:
        """Test shell-specific content generation."""
        platform_obj = dot.Platform()
        generator = dot.ShellGenerator(platform_obj)

        snippet = dot.ShellSnippet(
            name="test",
            description="Test",
            stage=dot.ShellStage.MAIN,
            bash='echo "bash"',
            zsh='echo "zsh"',
            fish='echo "fish"',
            default='echo "{shell}"',
        )

        bash_init = generator.generate_staged_init("bash", [snippet])
        zsh_init = generator.generate_staged_init("zsh", [snippet])
        fish_init = generator.generate_staged_init("fish", [snippet])

        assert 'echo "bash"' in bash_init
        assert 'echo "zsh"' in zsh_init
        assert 'echo "fish"' in fish_init

    def test_condition_wrapping(self) -> None:
        """Test conditional snippet wrapping."""
        platform_obj = dot.Platform()
        generator = dot.ShellGenerator(platform_obj)

        snippet = dot.ShellSnippet(
            name="conditional",
            description="Conditional test",
            stage=dot.ShellStage.MAIN,
            condition="command -v test",
            default="export CONDITIONAL=1",
        )

        bash_init = generator.generate_staged_init("bash", [snippet])
        fish_init = generator.generate_staged_init("fish", [snippet])

        # Should wrap in if/fi for bash
        assert "if command -v test; then" in bash_init
        assert "fi" in bash_init

        # Should wrap in if/end for fish
        assert "if type -q test" in fish_init  # converted condition
        assert "end" in fish_init


# ═══════════════════════════════════════════════════════════════════════════════
# PROVISIONER MANAGER TESTS
# ═══════════════════════════════════════════════════════════════════════════════


class TestProvisionerManager:
    """Test provisioner installation lifecycle management."""

    @pytest.mark.asyncio
    async def test_manager_init(self, config_with_provisioners) -> None:
        """Test ProvisionerManager initialization."""
        runner = dot.AsyncCommandRunner(dry_run=True)
        platform_obj = dot.Platform()
        all_provisioners = {
            **config_with_provisioners.provisioners,
            **config_with_provisioners.enhancements,
        }

        manager = dot.ProvisionerManager(all_provisioners, runner, platform_obj)

        assert manager.provisioners == all_provisioners
        assert manager.runner == runner
        assert manager.platform == platform_obj
        assert isinstance(manager.resolver, dot.DependencyResolver)

    @pytest.mark.asyncio
    async def test_is_installed_check(self, config_with_provisioners) -> None:
        """Test checking if provisioner is installed."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()
        all_provisioners = {
            **config_with_provisioners.provisioners,
            **config_with_provisioners.enhancements,
        }

        manager = dot.ProvisionerManager(all_provisioners, runner, platform_obj)
        rust = config_with_provisioners.provisioners["rust"]

        with patch.object(
            runner,
            "run",
            new_callable=unittest.mock.AsyncMock,
        ) as mock_run:
            # Mock successful verification
            mock_run.return_value = dot.CommandResult(
                success=True,
                stdout="cargo 1.70.0",
            )

            is_installed = await manager._is_installed(rust)

            assert is_installed is True
            mock_run.assert_called_once_with(
                "cargo --version",
                check=False,
                capture=True,
                env=None,
            )

    @pytest.mark.asyncio
    async def test_provision_all_dry_run(self, config_with_provisioners) -> None:
        """Test provisioning all in dry run mode."""
        runner = dot.AsyncCommandRunner(dry_run=True)
        platform_obj = dot.Platform()
        all_provisioners = {
            **config_with_provisioners.provisioners,
            **config_with_provisioners.enhancements,
        }

        manager = dot.ProvisionerManager(all_provisioners, runner, platform_obj)

        with patch.object(
            manager,
            "_is_installed",
            new_callable=unittest.mock.AsyncMock,
        ) as mock_installed:
            mock_installed.return_value = False

            results = await manager.provision_all(dry_run=True)

            assert len(results) == 2  # rust + starship
            assert all(success for success in results.values())

    @pytest.mark.asyncio
    async def test_install_via_script(self, config_with_provisioners) -> None:
        """Test installing provisioner via script."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()
        all_provisioners = {
            **config_with_provisioners.provisioners,
            **config_with_provisioners.enhancements,
        }

        manager = dot.ProvisionerManager(all_provisioners, runner, platform_obj)
        rust = config_with_provisioners.provisioners["rust"]

        with patch.object(
            runner,
            "run",
            new_callable=unittest.mock.AsyncMock,
        ) as mock_run:
            mock_run.return_value = dot.CommandResult(success=True)

            success = await manager._install_via_script(rust)

            assert success is True
            mock_run.assert_called_once_with(
                "curl https://sh.rustup.rs | sh",
                env=None,
                check=False,
                capture=True,
            )

    @pytest.mark.asyncio
    async def test_filter_by_type(self, config_with_provisioners) -> None:
        """Test filtering provisioners by type."""
        runner = dot.AsyncCommandRunner(dry_run=True)
        platform_obj = dot.Platform()
        all_provisioners = {
            **config_with_provisioners.provisioners,
            **config_with_provisioners.enhancements,
        }

        manager = dot.ProvisionerManager(all_provisioners, runner, platform_obj)

        with patch.object(
            manager,
            "_is_installed",
            new_callable=unittest.mock.AsyncMock,
        ) as mock_installed:
            mock_installed.return_value = False

            # Test filtering by provisioner type
            results = await manager.provision_all(
                filter_type=dot.ProvisionerType.PROVISIONER,
            )

            assert "rust" in results  # rust is a provisioner
            assert "starship" not in results  # starship is an enhancement


# ═══════════════════════════════════════════════════════════════════════════════
# DOTFILES APP TESTS
# ═══════════════════════════════════════════════════════════════════════════════


class TestDotfilesApp:
    """Test main application class."""

    def test_app_init(self, tmp_path, sample_toml_config, temp_home) -> None:
        """Test DotfilesApp initialization."""
        config_path = tmp_path / "dot.toml"
        config_path.write_text(sample_toml_config)

        app = dot.DotfilesApp(config_path=config_path, dry_run=True)

        assert app.dry_run is True
        assert isinstance(app.platform, dot.Platform)
        assert isinstance(app.runner, dot.AsyncCommandRunner)
        assert isinstance(app.config, dot.DotfilesConfig)
        assert isinstance(app.shell_generator, dot.ShellGenerator)
        assert isinstance(app.provisioner_manager, dot.ProvisionerManager)

    @pytest.mark.asyncio
    async def test_install_dotfiles(
        self,
        tmp_path,
        sample_toml_config,
        temp_home,
    ) -> None:
        """Test installing dotfiles symlinks."""
        # Create source files
        dot_config = tmp_path / "dot-config"
        dot_config.mkdir()
        (dot_config / ".gitconfig").write_text("git config")
        (dot_config / ".zshrc").write_text("zsh config")
        (dot_config / ".vim").mkdir()

        # Update config to point to our test directory
        config_content = sample_toml_config.replace("~/.dot-config", str(dot_config))
        config_path = tmp_path / "dot.toml"
        config_path.write_text(config_content)

        app = dot.DotfilesApp(config_path=config_path, dry_run=False)

        success = await app.install_dotfiles()

        assert success is True
        assert (temp_home / ".gitconfig").is_symlink()
        assert (temp_home / ".zshrc").is_symlink()
        assert (temp_home / ".vim").is_symlink()

        # Verify symlinks point to the correct source files
        assert (temp_home / ".gitconfig").resolve() == (
            dot_config / ".gitconfig"
        ).resolve()
        assert (temp_home / ".zshrc").resolve() == (dot_config / ".zshrc").resolve()
        assert (temp_home / ".vim").resolve() == (dot_config / ".vim").resolve()

    @pytest.mark.asyncio
    async def test_provision_with_filter(
        self,
        tmp_path,
        sample_toml_config,
        temp_home,
    ) -> None:
        """Test provisioning with type filter."""
        config_path = tmp_path / "dot.toml"
        config_path.write_text(sample_toml_config)

        app = dot.DotfilesApp(config_path=config_path, dry_run=True)

        with patch.object(
            app.provisioner_manager,
            "provision_all",
            new_callable=unittest.mock.AsyncMock,
        ) as mock_provision:
            mock_provision.return_value = {"rust": True}

            success = await app.provision(filter_type=dot.ProvisionerType.PROVISIONER)

            assert success is True
            mock_provision.assert_called_once_with(
                dot.ProvisionerType.PROVISIONER,
                True,
            )

    def test_generate_shell_init(self, tmp_path, sample_toml_config, temp_home) -> None:
        """Test generating shell initialization."""
        config_path = tmp_path / "dot.toml"
        config_path.write_text(sample_toml_config)

        app = dot.DotfilesApp(config_path=config_path, dry_run=True)

        zsh_init = app.generate_shell_init("zsh")
        fish_init = app.generate_shell_init("fish", "early")

        assert "Generated by dot.py v2.0" in zsh_init
        assert "DOT_LOADED" in fish_init  # Early stage content should be present
        assert "MAIN STAGE" not in fish_init  # only early stage requested

    @pytest.mark.asyncio
    async def test_status_reporting(
        self,
        tmp_path,
        sample_toml_config,
        temp_home,
    ) -> None:
        """Test system and provisioning status."""
        config_path = tmp_path / "dot.toml"
        config_path.write_text(sample_toml_config)

        app = dot.DotfilesApp(config_path=config_path, dry_run=True)

        with patch.object(
            app.provisioner_manager,
            "_is_installed",
            new_callable=unittest.mock.AsyncMock,
        ) as mock_installed:
            mock_installed.return_value = True

            status = await app.status()

            assert "platform" in status
            assert "provisioners" in status
            assert "dotfiles" in status
            assert status["platform"]["os"] == app.platform.info.os
            assert "rust" in status["provisioners"]
            assert "starship" in status["provisioners"]

    @pytest.mark.asyncio
    async def test_install_system_packages_apt(self, tmp_path, temp_home) -> None:
        """Test system package installation for apt."""
        config_toml = """
[packages.apt]
packages = ["git", "curl", "build-essential"]
        """
        config_path = tmp_path / "dot.toml"
        config_path.write_text(config_toml)

        app = dot.DotfilesApp(config_path=config_path, dry_run=False)

        # Mock platform to return apt
        with (
            patch.object(app.platform, "get_package_manager", return_value="apt"),
            patch.object(
                app.runner,
                "run",
                new_callable=unittest.mock.AsyncMock,
            ) as mock_run,
        ):
            # First call: check installed packages (none installed)
            mock_run.side_effect = [
                dot.CommandResult(success=True, stdout=""),  # dpkg check
                dot.CommandResult(success=True),  # apt install
            ]

            result = await app._install_system_packages()

            assert result is True
            assert mock_run.call_count == 2

            # Check that dpkg was called to check installed packages
            dpkg_call = mock_run.call_args_list[0]
            assert "dpkg -l" in dpkg_call[0][0]

            # Check that apt install was called with all packages
            apt_call = mock_run.call_args_list[1]
            expected_cmd = (
                "sudo apt-get update && sudo apt-get install -y "
                "git curl build-essential"
            )
            assert expected_cmd in apt_call[0][0]

    @pytest.mark.asyncio
    async def test_apt_package_detection_and_messaging(
        self,
        tmp_path: pathlib.Path,
        temp_home: pathlib.Path,
        caplog: pytest.LogCaptureFixture,
    ) -> None:
        """Test apt package detection with proper messaging."""
        config_toml = """
[packages.apt]
packages = ["git", "curl", "build-essential", "vim", "wget"]
        """
        config_path = tmp_path / "dot.toml"
        config_path.write_text(config_toml)

        app = dot.DotfilesApp(config_path=config_path, dry_run=False)

        with (
            patch.object(app.platform, "get_package_manager", return_value="apt"),
            patch.object(
                app.runner,
                "run",
                new_callable=unittest.mock.AsyncMock,
            ) as mock_run,
        ):
            # dpkg shows git and curl already installed
            mock_run.side_effect = [
                dot.CommandResult(success=True, stdout="git\ncurl"),  # dpkg check
                dot.CommandResult(success=True),  # apt install
            ]

            caplog.clear()
            with caplog.at_level(logging.INFO):
                result = await app._install_system_packages()

            assert result is True

            # Verify correct messaging appears in logs
            log_messages = [record.message for record in caplog.records]

            # Should see "Ensuring X packages" message
            ensuring_msg = next(
                (msg for msg in log_messages if "Ensuring 5 apt packages" in msg), None
            )
            assert ensuring_msg is not None

            # Should see package installation message with specific packages
            install_msg = next(
                (
                    msg
                    for msg in log_messages
                    if "Need to install 3 apt packages" in msg
                ),
                None,
            )
            assert install_msg is not None
            assert "build-essential, vim, wget" in install_msg

    @pytest.mark.asyncio
    async def test_apt_all_packages_installed(
        self,
        tmp_path: pathlib.Path,
        temp_home: pathlib.Path,
        caplog: pytest.LogCaptureFixture,
    ) -> None:
        """Test apt when all packages are already installed."""
        config_toml = """
[packages.apt]
packages = ["git", "curl", "vim"]
        """
        config_path = tmp_path / "dot.toml"
        config_path.write_text(config_toml)

        app = dot.DotfilesApp(config_path=config_path, dry_run=False)

        with (
            patch.object(app.platform, "get_package_manager", return_value="apt"),
            patch.object(
                app.runner,
                "run",
                new_callable=unittest.mock.AsyncMock,
            ) as mock_run,
        ):
            # dpkg shows all packages already installed
            mock_run.side_effect = [
                dot.CommandResult(success=True, stdout="git\ncurl\nvim"),  # dpkg check
            ]

            caplog.clear()
            with caplog.at_level(logging.INFO):
                result = await app._install_system_packages()

            assert result is True
            assert mock_run.call_count == 1  # Only dpkg check, no install

            # Verify correct messaging appears in logs
            log_messages = [record.message for record in caplog.records]

            # Should see "Ensuring X packages" message
            ensuring_msg = next(
                (msg for msg in log_messages if "Ensuring 3 apt packages" in msg), None
            )
            assert ensuring_msg is not None

            # Should see "all packages already installed" message with emoji
            already_installed_msg = next(
                (
                    msg
                    for msg in log_messages
                    if "✅ All 3 apt packages are already installed" in msg
                ),
                None,
            )
            assert already_installed_msg is not None

    @pytest.mark.asyncio
    async def test_apt_many_packages_truncated_list(
        self,
        tmp_path: pathlib.Path,
        temp_home: pathlib.Path,
        caplog: pytest.LogCaptureFixture,
    ) -> None:
        """Test apt messaging with many packages shows truncated list."""
        config_toml = """
[packages.apt]
packages = ["pkg1", "pkg2", "pkg3", "pkg4", "pkg5", "pkg6", "pkg7", "pkg8"]
        """
        config_path = tmp_path / "dot.toml"
        config_path.write_text(config_toml)

        app = dot.DotfilesApp(config_path=config_path, dry_run=False)

        with (
            patch.object(app.platform, "get_package_manager", return_value="apt"),
            patch.object(
                app.runner,
                "run",
                new_callable=unittest.mock.AsyncMock,
            ) as mock_run,
        ):
            # dpkg shows no packages installed
            mock_run.side_effect = [
                dot.CommandResult(success=True, stdout=""),  # dpkg check
                dot.CommandResult(success=True),  # apt install
            ]

            caplog.clear()
            with caplog.at_level(logging.INFO):
                result = await app._install_system_packages()

            assert result is True

            # Verify correct messaging appears in logs
            log_messages = [record.message for record in caplog.records]

            # Should see package installation message with truncated list
            install_msg = next(
                (
                    msg
                    for msg in log_messages
                    if "Need to install 8 apt packages" in msg
                ),
                None,
            )
            assert install_msg is not None
            # Should show first 5 packages + "..."
            assert "pkg1, pkg2, pkg3, pkg4, pkg5..." in install_msg
            # Should not show the last packages in the truncated message
            assert "pkg8" not in install_msg

    @pytest.mark.asyncio
    async def test_install_system_packages_brew(self, tmp_path, temp_home) -> None:
        """Test system package installation for brew."""
        config_toml = """
[packages.brew]
packages = ["git", "curl", "cmake"]
        """
        config_path = tmp_path / "dot.toml"
        config_path.write_text(config_toml)

        app = dot.DotfilesApp(config_path=config_path, dry_run=False)

        # Mock platform to return brew
        with (
            patch.object(app.platform, "get_package_manager", return_value="brew"),
            patch.object(
                app.runner,
                "run",
                new_callable=unittest.mock.AsyncMock,
            ) as mock_run,
        ):
            # First call: check installed packages (git already installed)
            mock_run.side_effect = [
                dot.CommandResult(success=True, stdout="git\nwget\nhtop"),  # brew list
                dot.CommandResult(success=True),  # brew install
            ]

            result = await app._install_system_packages()

            assert result is True
            assert mock_run.call_count == 2

            # Check that brew list was called
            brew_list_call = mock_run.call_args_list[0]
            assert "brew list --formula" in brew_list_call[0][0]

            # Check that brew install was called only with missing packages
            brew_install_call = mock_run.call_args_list[1]
            assert "brew install curl cmake" in brew_install_call[0][0]
            assert "git" not in brew_install_call[0][0]  # git was already installed

    @pytest.mark.asyncio
    async def test_install_system_packages_dry_run(self, tmp_path, temp_home) -> None:
        """Test system package installation in dry run mode."""
        config_toml = """
[packages.apt]
packages = ["git", "curl"]
        """
        config_path = tmp_path / "dot.toml"
        config_path.write_text(config_toml)

        app = dot.DotfilesApp(config_path=config_path, dry_run=True)

        with (
            patch.object(app.platform, "get_package_manager", return_value="apt"),
            patch.object(
                app.runner,
                "run",
                new_callable=unittest.mock.AsyncMock,
            ) as mock_run,
        ):
            result = await app._install_system_packages()

            assert result is True
            mock_run.assert_not_called()

    @pytest.mark.asyncio
    async def test_provision_installs_system_packages(
        self,
        tmp_path,
        sample_toml_config,
        temp_home,
    ) -> None:
        """Test provision command installs system packages first."""
        # Add packages section to config
        config_with_packages = (
            sample_toml_config
            + """
[packages.apt]
packages = ["git", "curl"]
        """
        )
        config_path = tmp_path / "dot.toml"
        config_path.write_text(config_with_packages)

        app = dot.DotfilesApp(config_path=config_path, dry_run=False)

        pkg_patch = patch.object(
            app.platform,
            "get_package_manager",
            return_value="apt",
        )
        install_patch = patch.object(
            app,
            "_install_system_packages",
            new_callable=unittest.mock.AsyncMock,
        )
        provision_patch = patch.object(
            app.provisioner_manager,
            "provision_all",
            new_callable=unittest.mock.AsyncMock,
        )

        with (
            pkg_patch,
            install_patch as mock_install_packages,
            provision_patch as mock_provision,
        ):
            mock_install_packages.return_value = True
            mock_provision.return_value = {"rust": True, "starship": True}

            result = await app.provision()

            assert result is True
            mock_install_packages.assert_called_once()
            mock_provision.assert_called_once()


# ═══════════════════════════════════════════════════════════════════════════════
# CLI INTEGRATION TESTS
# ═══════════════════════════════════════════════════════════════════════════════


class TestCLI:
    """Test command-line interface integration."""

    @pytest.mark.asyncio
    async def test_async_main_install(
        self,
        tmp_path,
        sample_toml_config,
        temp_home,
        monkeypatch,
    ) -> None:
        """Test async_main with install command."""
        config_path = tmp_path / "dot.toml"
        config_path.write_text(sample_toml_config)

        # Mock sys.argv
        monkeypatch.setattr(
            "sys.argv",
            ["dot.py", "--config", str(config_path), "install"],
        )

        with patch.object(
            dot.DotfilesApp,
            "install_dotfiles",
            new_callable=unittest.mock.AsyncMock,
        ) as mock_install:
            mock_install.return_value = True

            result = await dot.async_main()

            assert result == 0
            mock_install.assert_called_once()

    @pytest.mark.asyncio
    async def test_async_main_provision(
        self,
        tmp_path,
        sample_toml_config,
        temp_home,
        monkeypatch,
    ) -> None:
        """Test async_main with provision command."""
        config_path = tmp_path / "dot.toml"
        config_path.write_text(sample_toml_config)

        monkeypatch.setattr(
            "sys.argv",
            [
                "dot.py",
                "--config",
                str(config_path),
                "provision",
                "--type",
                "provisioner",
            ],
        )

        with patch.object(
            dot.DotfilesApp,
            "provision",
            new_callable=unittest.mock.AsyncMock,
        ) as mock_provision:
            mock_provision.return_value = True

            result = await dot.async_main()

            assert result == 0
            mock_provision.assert_called_once_with(dot.ProvisionerType.PROVISIONER)

    @pytest.mark.asyncio
    async def test_async_main_shell_generation(
        self,
        tmp_path,
        sample_toml_config,
        temp_home,
        monkeypatch,
        capsys,
    ) -> None:
        """Test async_main with shell command."""
        config_path = tmp_path / "dot.toml"
        config_path.write_text(sample_toml_config)

        monkeypatch.setattr(
            "sys.argv",
            ["dot.py", "--config", str(config_path), "shell", "--zsh"],
        )

        result = await dot.async_main()

        assert result == 0
        captured = capsys.readouterr()
        assert "Generated by dot.py v2.0" in captured.out

    @pytest.mark.asyncio
    async def test_async_main_status(
        self,
        tmp_path,
        sample_toml_config,
        temp_home,
        monkeypatch,
        capsys,
    ) -> None:
        """Test async_main with status command."""
        config_path = tmp_path / "dot.toml"
        config_path.write_text(sample_toml_config)

        monkeypatch.setattr(
            "sys.argv",
            ["dot.py", "--config", str(config_path), "status"],
        )

        with patch.object(
            dot.DotfilesApp,
            "status",
            new_callable=unittest.mock.AsyncMock,
        ) as mock_status:
            mock_status.return_value = {
                "platform": {"os": "linux"},
                "provisioners": {},
                "dotfiles": {},
            }

            result = await dot.async_main()

            assert result == 0
            captured = capsys.readouterr()
            assert "linux" in captured.out

    def test_main_function(
        self,
        tmp_path,
        sample_toml_config,
        temp_home,
        monkeypatch,
    ) -> None:
        """Test main() function entry point."""
        config_path = tmp_path / "dot.toml"
        config_path.write_text(sample_toml_config)

        monkeypatch.setattr(
            "sys.argv",
            ["dot.py", "--config", str(config_path), "--help"],
        )

        with pytest.raises(SystemExit) as exc_info:
            dot.main()

        assert exc_info.value.code == 0


# ═══════════════════════════════════════════════════════════════════════════════
# INTEGRATION TESTS
# ═══════════════════════════════════════════════════════════════════════════════


class TestIntegration:
    """End-to-end integration tests."""

    @pytest.mark.asyncio
    async def test_full_workflow(self, tmp_path, temp_home) -> None:
        """Test complete workflow from config to installation."""
        # Create realistic directory structure
        dot_config = tmp_path / "dot-config"
        dot_config.mkdir()

        # Create source files
        (dot_config / ".gitconfig").write_text("[user]\n    name = Test User")
        (dot_config / ".zshrc").write_text("export PATH=/usr/local/bin:$PATH")
        (dot_config / ".vim").mkdir()
        (dot_config / "config").mkdir()
        (dot_config / "config" / "starship.toml").write_text("[format]\n$all")

        # Create comprehensive config
        config_content = f"""
[config]
source = "{dot_config}"
backup = true

[home.files]
".gitconfig" = ".gitconfig"
".zshrc" = ".zshrc"
".config/starship.toml" = "config/starship.toml"

[home.dirs]
".vim" = ".vim"

[provisioners.rust]
description = "Rust toolchain"
install_script = "echo 'Installing Rust'"
provides = ["cargo", "rustc"]
requires = ["curl"]
verify_command = "echo 'cargo 1.70.0'"
priority = 3

[shell_integration.snippets.rust_env]
name = "rust_env"
description = "Rust environment"
stage = 5
default = "export CARGO_HOME=~/.cargo"
"""

        config_path = dot_config / "dot.toml"
        config_path.write_text(config_content)

        # Test complete workflow
        app = dot.DotfilesApp(config_path=config_path, dry_run=False)

        # 1. Install dotfiles
        install_success = await app.install_dotfiles()
        assert install_success is True
        assert (temp_home / ".gitconfig").exists()
        assert (temp_home / ".config" / "starship.toml").exists()

        # 2. Generate shell initialization
        shell_init = app.generate_shell_init("zsh")
        assert "Generated by dot.py v2.0" in shell_init
        assert "CARGO_HOME" in shell_init

        # 3. Check status
        status = await app.status()
        assert status["platform"]["os"] in {"linux", "darwin", "windows"}
        assert "rust" in status["provisioners"]
        assert ".gitconfig" in status["dotfiles"]

        # 4. Test dry-run provisioning
        app_dry = dot.DotfilesApp(config_path=config_path, dry_run=True)
        provision_results = await app_dry.provision()
        assert provision_results is True  # Should succeed in dry-run

    def test_pattern_matching_usage(self) -> None:
        """Test that our pattern matching features work correctly."""
        # Test enum pattern matching in platform detection
        platform_obj = dot.Platform()

        # This tests the match statement in get_package_manager
        mock_info = dot.SystemInfo(
            os="darwin",
            hostname="test",
            arch="x86_64",
            distro=None,
            is_linux=False,
            is_macos=True,
            is_wsl=False,
            home=pathlib.Path("/Users/test"),
            user="test",
        )
        platform_obj.info = mock_info
        with unittest.mock.patch("shutil.which", return_value="/usr/local/bin/brew"):
            result = platform_obj.get_package_manager()
            assert result == "brew"

        # Test enum pattern matching in shell content
        snippet = dot.ShellSnippet(
            name="test",
            description="Test",
            stage=dot.ShellStage.MAIN,
            bash="bash_content",
            default="default_{shell}",
        )

        # The get_content method uses match statements
        assert snippet.get_content("bash") == "bash_content"
        assert snippet.get_content("zsh") == "default_zsh"
        assert snippet.get_content("powershell") == "default_powershell"  # type: ignore[arg-type]


# ═══════════════════════════════════════════════════════════════════════════════
# PERFORMANCE TESTS
# ═══════════════════════════════════════════════════════════════════════════════


class TestPerformance:
    """Test performance improvements from v2.0."""

    def test_staged_shell_performance(self) -> None:
        """Test that staged shell generation provides performance benefits."""
        platform_obj = dot.Platform()
        generator = dot.ShellGenerator(platform_obj)

        # Create snippets for different stages
        early_snippets = [
            dot.ShellSnippet(
                name="env_var",
                description="Environment variable",
                stage=dot.ShellStage.EARLY,
                default="export EARLY_VAR=1",
            ),
        ]

        heavy_snippets = [
            dot.ShellSnippet(
                name="heavy_tool",
                description="Heavy tool initialization",
                stage=dot.ShellStage.LATE,
                default="eval $(heavy_tool init)",
            ),
        ]

        all_snippets = early_snippets + heavy_snippets

        # Early stage should only include early snippets
        early_init = generator.generate_staged_init("zsh", all_snippets, "early")
        assert "EARLY_VAR" in early_init
        assert "heavy_tool" not in early_init

        # This demonstrates the performance benefit - shells can load just
        # critical early-stage initialization for faster startup
        assert len(early_init) < len(
            generator.generate_staged_init("zsh", all_snippets),
        )

    @pytest.mark.asyncio
    async def test_async_concurrency(self) -> None:
        """Test async command execution provides concurrency benefits."""
        import time

        runner = dot.AsyncCommandRunner(dry_run=False)

        # Commands that each take ~0.1 seconds
        commands = [f"sleep 0.1 && echo 'cmd{i}'" for i in range(3)]

        # Test sequential vs concurrent execution
        start_time = time.time()
        results = await runner.run_many(commands, max_concurrent=3)
        concurrent_time = time.time() - start_time

        # With proper concurrency, 3 x 0.1s commands should take ~0.1s total
        # (plus overhead), not 0.3s
        assert concurrent_time < 0.25  # Allow for overhead
        assert len(results) == 3
        assert all(result.success for result in results)


# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 1: HIGH PRIORITY TESTS - Platform errors, edge cases
# ═══════════════════════════════════════════════════════════════════════════════


class TestPlatformEdgeCases:
    """Test platform detection error scenarios."""

    def test_wsl_detection_permission_error(self) -> None:
        """Test WSL detection with permission error."""
        with unittest.mock.patch(
            "pathlib.Path.read_text",
            side_effect=PermissionError("No access"),
        ):
            platform_obj = dot.Platform()
            assert platform_obj._detect_wsl() is False

    def test_wsl_detection_file_not_found(self) -> None:
        """Test WSL detection with missing file."""
        with unittest.mock.patch(
            "pathlib.Path.read_text",
            side_effect=FileNotFoundError("Not found"),
        ):
            platform_obj = dot.Platform()
            assert platform_obj._detect_wsl() is False

    def test_distro_detection_permission_error(self) -> None:
        """Test distro detection with permission error."""
        with unittest.mock.patch(
            "pathlib.Path.read_text",
            side_effect=PermissionError("No access"),
        ):
            platform_obj = dot.Platform()
            assert platform_obj._detect_distro() is None

    def test_distro_detection_file_not_found(self) -> None:
        """Test distro detection with missing os-release."""
        with unittest.mock.patch(
            "pathlib.Path.read_text",
            side_effect=FileNotFoundError("Not found"),
        ):
            platform_obj = dot.Platform()
            assert platform_obj._detect_distro() is None

    def test_arch_package_manager(self) -> None:
        """Test Arch Linux package manager detection."""
        platform_obj = dot.Platform()
        mock_info = dot.SystemInfo(
            os="linux",
            hostname="archbox",
            arch="x86_64",
            distro="arch",
            is_linux=True,
            is_macos=False,
            is_wsl=False,
            home=pathlib.Path("/home/user"),
            user="user",
        )
        platform_obj.info = mock_info
        assert platform_obj.get_package_manager() == "pacman"

    def test_manjaro_package_manager(self) -> None:
        """Test Manjaro package manager detection."""
        platform_obj = dot.Platform()
        mock_info = dot.SystemInfo(
            os="linux",
            hostname="manjaro",
            arch="x86_64",
            distro="manjaro",
            is_linux=True,
            is_macos=False,
            is_wsl=False,
            home=pathlib.Path("/home/user"),
            user="user",
        )
        platform_obj.info = mock_info
        assert platform_obj.get_package_manager() == "pacman"

    def test_unknown_distro_package_manager(self) -> None:
        """Test package manager for unknown distro."""
        platform_obj = dot.Platform()
        mock_info = dot.SystemInfo(
            os="linux",
            hostname="unknown",
            arch="x86_64",
            distro="gentoo",  # Not in our supported list
            is_linux=True,
            is_macos=False,
            is_wsl=False,
            home=pathlib.Path("/home/user"),
            user="user",
        )
        platform_obj.info = mock_info
        assert platform_obj.get_package_manager() is None


class TestShellSnippetEdgeCases:
    """Test shell snippet edge cases."""

    def test_shell_snippet_no_content_no_default(self) -> None:
        """Test shell snippet with no content and no default."""
        snippet = dot.ShellSnippet(
            name="empty",
            description="Empty snippet",
            stage=dot.ShellStage.MAIN,
            # No bash, zsh, fish, or default content
        )
        assert snippet.get_content("bash") == ""
        assert snippet.get_content("zsh") == ""
        assert snippet.get_content("fish") == ""


class TestProvisionerEdgeCases:
    """Test provisioner edge cases."""

    @pytest.mark.asyncio
    async def test_provisioner_no_verify_command(self) -> None:
        """Test provisioner without verify command."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        prov = dot.Provisioner(
            name="no-verify",
            description="No verify command",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=frozenset(["tool"]),
            requires=frozenset(),
            verify_command="",  # No verify command
        )

        manager = dot.ProvisionerManager({"no-verify": prov}, runner, platform_obj)
        is_installed = await manager._is_installed(prov)
        assert is_installed is False


class TestCLIVerboseLogging:
    """Test CLI verbose logging."""

    @pytest.mark.asyncio
    async def test_verbose_flag_sets_debug_level(self, monkeypatch) -> None:
        """Test --verbose flag sets DEBUG level."""
        test_args = ["dot.py", "--verbose", "status"]
        monkeypatch.setattr(sys, "argv", test_args)

        with unittest.mock.patch("logging.getLogger") as mock_logger:
            mock_root_logger = mock_logger.return_value
            with patch.object(
                dot.DotfilesApp,
                "status",
                new_callable=unittest.mock.AsyncMock,
            ) as mock_status:
                mock_status.return_value = {"test": "status"}
                await dot.async_main()

            mock_root_logger.setLevel.assert_called_with(logging.DEBUG)


# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 2: MEDIUM PRIORITY TESTS - Package managers, binary install, error handling
# ═══════════════════════════════════════════════════════════════════════════════


class TestPackageManagerInstallation:
    """Test different package manager installation methods."""

    @pytest.mark.asyncio
    async def test_install_via_package_apt(self) -> None:
        """Test package installation via apt."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        # Mock platform to return apt
        mock_info = dot.SystemInfo(
            os="linux",
            hostname="ubuntu",
            arch="x86_64",
            distro="ubuntu",
            is_linux=True,
            is_macos=False,
            is_wsl=False,
            home=pathlib.Path("/home/user"),
            user="user",
        )
        platform_obj.info = mock_info

        prov = dot.Provisioner(
            name="test-pkg",
            description="Test package",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.PACKAGE,
            provides=frozenset(["test"]),
            requires=frozenset(),
            package_name="test-package",
        )

        manager = dot.ProvisionerManager({"test-pkg": prov}, runner, platform_obj)

        with patch.object(
            runner,
            "run",
            new_callable=unittest.mock.AsyncMock,
        ) as mock_run:
            mock_run.return_value = dot.CommandResult(success=True)

            success = await manager._install_via_package(prov)

            assert success is True
            mock_run.assert_called_once_with(
                "sudo apt-get update && sudo apt-get install -y test-package",
                env=None,
                check=False,
                capture=True,
            )

    @pytest.mark.asyncio
    async def test_install_via_package_brew(self) -> None:
        """Test package installation via brew."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        # Mock platform to return brew
        mock_info = dot.SystemInfo(
            os="darwin",
            hostname="mac",
            arch="x86_64",
            distro=None,
            is_linux=False,
            is_macos=True,
            is_wsl=False,
            home=pathlib.Path("/Users/user"),
            user="user",
        )
        platform_obj.info = mock_info

        prov = dot.Provisioner(
            name="test-pkg",
            description="Test package",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.PACKAGE,
            provides=frozenset(["test"]),
            requires=frozenset(),
            package_name="test-package",
        )

        manager = dot.ProvisionerManager({"test-pkg": prov}, runner, platform_obj)

        with (
            patch.object(platform_obj, "get_package_manager", return_value="brew"),
            patch.object(
                runner,
                "run",
                new_callable=unittest.mock.AsyncMock,
            ) as mock_run,
        ):
            mock_run.return_value = dot.CommandResult(success=True)

            success = await manager._install_via_package(prov)

            assert success is True
            mock_run.assert_called_once_with(
                "brew install test-package",
                env=None,
                check=False,
                capture=True,
            )

    @pytest.mark.asyncio
    async def test_install_via_package_dnf(self) -> None:
        """Test package installation via dnf."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        # Mock platform to return dnf
        mock_info = dot.SystemInfo(
            os="linux",
            hostname="fedora",
            arch="x86_64",
            distro="fedora",
            is_linux=True,
            is_macos=False,
            is_wsl=False,
            home=pathlib.Path("/home/user"),
            user="user",
        )
        platform_obj.info = mock_info

        prov = dot.Provisioner(
            name="test-pkg",
            description="Test package",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.PACKAGE,
            provides=frozenset(["test"]),
            requires=frozenset(),
        )

        manager = dot.ProvisionerManager({"test-pkg": prov}, runner, platform_obj)

        with patch.object(
            runner,
            "run",
            new_callable=unittest.mock.AsyncMock,
        ) as mock_run:
            mock_run.return_value = dot.CommandResult(success=True)

            success = await manager._install_via_package(prov)

            assert success is True
            # When no package_name, it uses the provisioner name
            mock_run.assert_called_once_with(
                "sudo dnf install -y test-pkg",
                env=None,
                check=False,
                capture=True,
            )

    @pytest.mark.asyncio
    async def test_install_via_package_pacman(self) -> None:
        """Test package installation via pacman."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        # Mock platform to return pacman
        mock_info = dot.SystemInfo(
            os="linux",
            hostname="arch",
            arch="x86_64",
            distro="arch",
            is_linux=True,
            is_macos=False,
            is_wsl=False,
            home=pathlib.Path("/home/user"),
            user="user",
        )
        platform_obj.info = mock_info

        prov = dot.Provisioner(
            name="test-pkg",
            description="Test package",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.PACKAGE,
            provides=frozenset(["test"]),
            requires=frozenset(),
        )

        manager = dot.ProvisionerManager({"test-pkg": prov}, runner, platform_obj)

        with patch.object(
            runner,
            "run",
            new_callable=unittest.mock.AsyncMock,
        ) as mock_run:
            mock_run.return_value = dot.CommandResult(success=True)

            success = await manager._install_via_package(prov)

            assert success is True
            mock_run.assert_called_once_with(
                "sudo pacman -S --noconfirm test-pkg",
                env=None,
                check=False,
                capture=True,
            )

    @pytest.mark.asyncio
    async def test_install_via_package_no_manager(self) -> None:
        """Test package installation with no package manager."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        prov = dot.Provisioner(
            name="test-pkg",
            description="Test package",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.PACKAGE,
            provides=frozenset(["test"]),
            requires=frozenset(),
        )

        manager = dot.ProvisionerManager({"test-pkg": prov}, runner, platform_obj)

        with patch.object(platform_obj, "get_package_manager", return_value=None):
            success = await manager._install_via_package(prov)
            assert success is False

    @pytest.mark.asyncio
    async def test_install_via_package_unsupported_manager(self) -> None:
        """Test package installation with unsupported package manager."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        prov = dot.Provisioner(
            name="test-pkg",
            description="Test package",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.PACKAGE,
            provides=frozenset(["test"]),
            requires=frozenset(),
        )

        manager = dot.ProvisionerManager({"test-pkg": prov}, runner, platform_obj)

        with patch.object(platform_obj, "get_package_manager", return_value="zypper"):
            success = await manager._install_via_package(prov)
            assert success is False


class TestBinaryInstallation:
    """Test binary download installation."""

    @pytest.mark.asyncio
    async def test_install_via_binary_success(self) -> None:
        """Test successful binary installation."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        prov = dot.Provisioner(
            name="test-bin",
            description="Test binary",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.BINARY,
            provides=frozenset(["test"]),
            requires=frozenset(),
            binary_url="https://example.com/test-bin",
        )

        manager = dot.ProvisionerManager({"test-bin": prov}, runner, platform_obj)

        with patch.object(
            runner,
            "run",
            new_callable=unittest.mock.AsyncMock,
        ) as mock_run:
            # All commands succeed
            mock_run.return_value = dot.CommandResult(success=True)

            success = await manager._install_via_binary(prov)

            assert success is True
            assert mock_run.call_count == 3
            mock_run.assert_any_call(
                "curl -L https://example.com/test-bin -o /tmp/test-bin",
                env=None,
                check=False,
                capture=True,
            )
            mock_run.assert_any_call(
                "chmod +x /tmp/test-bin",
                env=None,
                check=False,
                capture=True,
            )
            mock_run.assert_any_call(
                "sudo mv /tmp/test-bin /usr/local/bin/",
                env=None,
                check=False,
                capture=True,
            )

    @pytest.mark.asyncio
    async def test_install_via_binary_no_url(self) -> None:
        """Test binary installation without URL."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        prov = dot.Provisioner(
            name="test-bin",
            description="Test binary",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.BINARY,
            provides=frozenset(["test"]),
            requires=frozenset(),
            binary_url="",  # No URL
        )

        manager = dot.ProvisionerManager({"test-bin": prov}, runner, platform_obj)

        success = await manager._install_via_binary(prov)
        assert success is False

    @pytest.mark.asyncio
    async def test_install_via_binary_download_fails(self) -> None:
        """Test binary installation when download fails."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        prov = dot.Provisioner(
            name="test-bin",
            description="Test binary",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.BINARY,
            provides=frozenset(["test"]),
            requires=frozenset(),
            binary_url="https://example.com/test-bin",
        )

        manager = dot.ProvisionerManager({"test-bin": prov}, runner, platform_obj)

        with patch.object(
            runner,
            "run",
            new_callable=unittest.mock.AsyncMock,
        ) as mock_run:
            # Download fails
            mock_run.return_value = dot.CommandResult(success=False)

            success = await manager._install_via_binary(prov)

            assert success is False
            mock_run.assert_called_once()  # Only the download attempt

    @pytest.mark.asyncio
    async def test_install_via_binary_chmod_fails(self) -> None:
        """Test binary installation when chmod fails."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        prov = dot.Provisioner(
            name="test-bin",
            description="Test binary",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.BINARY,
            provides=frozenset(["test"]),
            requires=frozenset(),
            binary_url="https://example.com/test-bin",
        )

        manager = dot.ProvisionerManager({"test-bin": prov}, runner, platform_obj)

        with patch.object(
            runner,
            "run",
            new_callable=unittest.mock.AsyncMock,
        ) as mock_run:
            # Download succeeds, chmod fails
            mock_run.side_effect = [
                dot.CommandResult(success=True),  # curl
                dot.CommandResult(success=False),  # chmod
            ]

            success = await manager._install_via_binary(prov)

            assert success is False
            assert mock_run.call_count == 2


class TestAsyncCommandRunnerErrors:
    """Test AsyncCommandRunner error handling."""

    @pytest.mark.asyncio
    async def test_raise_process_error(self) -> None:
        """Test _raise_process_error method."""
        runner = dot.AsyncCommandRunner(dry_run=False)

        result = dot.CommandResult(
            success=False,
            stdout="output",
            stderr="error",
            returncode=1,
            duration=0.1,
        )

        with pytest.raises(subprocess.CalledProcessError) as exc_info:
            runner._raise_process_error(result, "test command")

        assert exc_info.value.returncode == 1
        assert exc_info.value.cmd == "test command"
        assert exc_info.value.stdout == "output"
        assert exc_info.value.stderr == "error"

    @pytest.mark.asyncio
    async def test_run_with_check_raises_on_failure(self) -> None:
        """Test that run with check=True raises on failure."""
        runner = dot.AsyncCommandRunner(dry_run=False)

        with pytest.raises(subprocess.CalledProcessError):
            await runner.run("exit 1", check=True, shell=True)

    @pytest.mark.asyncio
    async def test_run_handles_generic_exception(self) -> None:
        """Test run handles generic exceptions."""
        runner = dot.AsyncCommandRunner(dry_run=False)

        with unittest.mock.patch(
            "asyncio.create_subprocess_shell",
            side_effect=RuntimeError("Test error"),
        ):
            result = await runner.run("echo test", shell=True)

            assert result.success is False
            assert "Test error" in result.stderr
            assert result.returncode == -1

    @pytest.mark.asyncio
    async def test_run_many_with_stop_on_error(self) -> None:
        """Test run_many stops on error when requested."""
        runner = dot.AsyncCommandRunner(dry_run=False)

        # Use 'false' command which reliably returns exit code 1
        commands = [
            ["sh", "-c", "echo ok"],
            ["sh", "-c", "false"],
            ["sh", "-c", "echo should_not_run"],
        ]
        results = await runner.run_many(commands, stop_on_error=True)

        # Should only have 2 results (stopped after failure)
        assert len(results) == 2
        assert results[0].success is True
        assert results[1].success is False

    @pytest.mark.asyncio
    async def test_run_many_exception_handling(self) -> None:
        """Test run_many handles exceptions in task group."""
        runner = dot.AsyncCommandRunner(dry_run=False)

        with patch.object(runner, "run", side_effect=RuntimeError("Test error")):
            results = await runner.run_many(["echo test"])

            # Should return empty results on exception
            assert results == []


class TestConfigLoaderErrors:
    """Test ConfigLoader error handling."""

    def test_config_loader_os_error(self, tmp_path) -> None:
        """Test ConfigLoader handles OS errors."""
        config_path = tmp_path / "unreadable.toml"
        config_path.write_text("[test]")
        config_path.chmod(0o000)  # Remove read permissions

        loader = dot.ConfigLoader(config_path)

        with pytest.raises(OSError):
            loader.load()

        # Cleanup
        config_path.chmod(0o644)

    def test_provisioner_parsing_skips_non_dict(self, tmp_path) -> None:
        """Test provisioner parsing skips non-dict entries."""
        config_path = tmp_path / "test.toml"
        config_path.write_text("""
[provisioners]
valid = { description = "Valid", provides = ["test"] }
invalid = "not a dict"
""")

        loader = dot.ConfigLoader(config_path)
        config = loader.load()

        # Should only have the valid provisioner
        assert "valid" in config.provisioners
        assert "invalid" not in config.provisioners

    def test_provisioner_parsing_unknown_type(self, tmp_path) -> None:
        """Test provisioner parsing with unknown type falls back to default."""
        config_path = tmp_path / "test.toml"
        config_path.write_text("""
[provisioners.test]
description = "Test"
type = "unknown_type"
provides = ["test"]
""")

        loader = dot.ConfigLoader(config_path)
        config = loader.load()

        # Should use default type
        assert config.provisioners["test"].type == dot.ProvisionerType.PROVISIONER

    def test_provisioner_parsing_unknown_install_method(self, tmp_path) -> None:
        """Test provisioner parsing with unknown install method defaults."""
        config_path = tmp_path / "test.toml"
        config_path.write_text("""
[provisioners.test]
description = "Test"
install_method = "unknown_method"
provides = ["test"]
""")

        loader = dot.ConfigLoader(config_path)
        config = loader.load()

        # Should use default install method
        assert config.provisioners["test"].install_method == dot.InstallMethod.SCRIPT


# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 3: LOW PRIORITY TESTS - Cleanup, symlinks, CLI edge cases
# ═══════════════════════════════════════════════════════════════════════════════


class TestCleanupFunctionality:
    """Test cleanup functionality."""

    @pytest.mark.asyncio
    async def test_cleanup_removes_files_and_dirs(self, temp_home) -> None:
        """Test cleanup removes files and directories."""
        # Create test files and directories
        test_file = temp_home / "test.tmp"
        test_file.write_text("test")
        test_dir = temp_home / "test_dir"
        test_dir.mkdir()
        (test_dir / "nested.txt").write_text("nested")

        app = dot.DotfilesApp(dry_run=False)
        app.platform.info = dot.SystemInfo(
            os="linux",
            hostname="test",
            arch="x86_64",
            distro="ubuntu",
            is_linux=True,
            is_macos=False,
            is_wsl=False,
            home=temp_home,
            user="test",
        )

        # Run cleanup with patterns
        success = await app.cleanup(["*.tmp", "test_dir"])

        assert success is True
        assert not test_file.exists()
        assert not test_dir.exists()

    @pytest.mark.asyncio
    async def test_cleanup_no_patterns(self, temp_home) -> None:
        """Test cleanup with no patterns configured."""
        app = dot.DotfilesApp(dry_run=False)
        app.config.cleanup_patterns = []

        success = await app.cleanup()

        assert success is True  # Should succeed with no patterns

    @pytest.mark.asyncio
    async def test_cleanup_dry_run(self, temp_home) -> None:
        """Test cleanup in dry run mode."""
        test_file = temp_home / "test.tmp"
        test_file.write_text("test")

        app = dot.DotfilesApp(dry_run=True)
        app.platform.info = dot.SystemInfo(
            os="linux",
            hostname="test",
            arch="x86_64",
            distro="ubuntu",
            is_linux=True,
            is_macos=False,
            is_wsl=False,
            home=temp_home,
            user="test",
        )

        success = await app.cleanup(["*.tmp"])

        assert success is True
        assert test_file.exists()  # Should not be removed in dry run

    @pytest.mark.asyncio
    async def test_cleanup_handles_errors(self, temp_home) -> None:
        """Test cleanup handles errors gracefully."""
        app = dot.DotfilesApp(dry_run=False)
        app.platform.info = dot.SystemInfo(
            os="linux",
            hostname="test",
            arch="x86_64",
            distro="ubuntu",
            is_linux=True,
            is_macos=False,
            is_wsl=False,
            home=temp_home,
            user="test",
        )

        with unittest.mock.patch(
            "pathlib.Path.glob",
            side_effect=PermissionError("No access"),
        ):
            success = await app.cleanup(["*.tmp"])

            assert success is False  # Should fail on error


class TestSymlinkEdgeCases:
    """Test symlink creation edge cases."""

    @pytest.mark.asyncio
    async def test_symlink_already_correct(self, temp_home) -> None:
        """Test symlink that's already correct is skipped."""
        source = temp_home / "source.txt"
        source.write_text("content")
        dest = temp_home / "dest.txt"
        dest.symlink_to(source)

        app = dot.DotfilesApp(dry_run=False)

        # Should succeed without modification
        success = await app._create_symlink(source, dest)

        assert success is True
        assert dest.is_symlink()
        assert dest.resolve() == source.resolve()

    @pytest.mark.asyncio
    async def test_symlink_replaces_directory(self, temp_home) -> None:
        """Test symlink replaces existing directory."""
        source = temp_home / "source"
        source.mkdir()
        (source / "file.txt").write_text("content")

        dest = temp_home / "dest"
        dest.mkdir()
        (dest / "old.txt").write_text("old")

        app = dot.DotfilesApp(dry_run=False)

        success = await app._create_symlink(source, dest)

        assert success is True
        assert dest.is_symlink()
        assert dest.resolve() == source.resolve()

    @pytest.mark.asyncio
    async def test_symlink_handles_os_error(self, temp_home) -> None:
        """Test symlink handles OS errors."""
        source = temp_home / "source.txt"
        source.write_text("content")
        dest = temp_home / "readonly" / "dest.txt"

        app = dot.DotfilesApp(dry_run=False)

        with unittest.mock.patch(
            "pathlib.Path.symlink_to",
            side_effect=OSError("Permission denied"),
        ):
            success = await app._create_symlink(source, dest)

            assert success is False


class TestStatusEdgeCases:
    """Test status command edge cases."""

    @pytest.mark.asyncio
    async def test_status_file_not_symlink(self, temp_home) -> None:
        """Test status detects file that's not a symlink."""
        app = dot.DotfilesApp(dry_run=False)
        app.config.source = temp_home / "dotfiles"
        app.config.source.mkdir()

        # Create source file
        source = app.config.source / "test.txt"
        source.write_text("source")

        # Create regular file at destination
        dest = temp_home / "test.txt"
        dest.write_text("not a symlink")

        app.config.files[dot.DestPath(pathlib.Path("test.txt"))] = dot.TemplateDef(
            source=dot.SourcePath(pathlib.Path("test.txt")),
        )
        app.platform.info = dot.SystemInfo(
            os="linux",
            hostname="test",
            arch="x86_64",
            distro="ubuntu",
            is_linux=True,
            is_macos=False,
            is_wsl=False,
            home=temp_home,
            user="test",
        )

        status = await app.status()

        assert status["dotfiles"]["test.txt"] == "not_symlink"

    @pytest.mark.asyncio
    async def test_status_symlink_wrong_target(self, temp_home) -> None:
        """Test status detects symlink with wrong target."""
        app = dot.DotfilesApp(dry_run=False)
        app.config.source = temp_home / "dotfiles"
        app.config.source.mkdir()

        # Create source file
        source = app.config.source / "test.txt"
        source.write_text("source")

        # Create wrong file and symlink to it
        wrong = temp_home / "wrong.txt"
        wrong.write_text("wrong")
        dest = temp_home / "test.txt"
        dest.symlink_to(wrong)

        app.config.files[dot.DestPath(pathlib.Path("test.txt"))] = dot.TemplateDef(
            source=dot.SourcePath(pathlib.Path("test.txt")),
        )
        app.platform.info = dot.SystemInfo(
            os="linux",
            hostname="test",
            arch="x86_64",
            distro="ubuntu",
            is_linux=True,
            is_macos=False,
            is_wsl=False,
            home=temp_home,
            user="test",
        )

        status = await app.status()

        assert status["dotfiles"]["test.txt"] == "wrong_target"


class TestCLIEdgeCases:
    """Test CLI edge cases."""

    @pytest.mark.asyncio
    async def test_unknown_command(self, monkeypatch) -> None:
        """Test handling of unknown commands."""
        test_args = ["dot.py", "unknown-command"]
        monkeypatch.setattr(sys, "argv", test_args)

        # argparse exits with code 2 for invalid arguments
        with pytest.raises(SystemExit) as exc_info:
            await dot.async_main()

        assert exc_info.value.code == 2

    @pytest.mark.asyncio
    async def test_cleanup_command(self, monkeypatch, temp_home) -> None:
        """Test cleanup command execution."""
        test_args = ["dot.py", "cleanup", "*.tmp"]
        monkeypatch.setattr(sys, "argv", test_args)

        with patch.object(
            dot.DotfilesApp,
            "cleanup",
            new_callable=unittest.mock.AsyncMock,
        ) as mock_cleanup:
            mock_cleanup.return_value = True

            exit_code = await dot.async_main()

            assert exit_code == 0
            mock_cleanup.assert_called_once_with(["*.tmp"])

    def test_main_keyboard_interrupt(self) -> None:
        """Test main handles KeyboardInterrupt."""
        with unittest.mock.patch("asyncio.run", side_effect=KeyboardInterrupt):
            exit_code = dot.main()

            assert exit_code == 130  # Standard Unix exit code for SIGINT

    def test_main_generic_exception(self) -> None:
        """Test main handles generic exceptions."""
        with unittest.mock.patch("asyncio.run", side_effect=RuntimeError("Test error")):
            exit_code = dot.main()

            assert exit_code == 1

    @pytest.mark.asyncio
    async def test_no_command_shows_help(
        self, monkeypatch: typing.Any, capsys: typing.Any
    ) -> None:
        """Test no command shows help."""
        test_args = ["dot.py"]
        monkeypatch.setattr(sys, "argv", test_args)

        await dot.async_main()

        captured = capsys.readouterr()
        assert "usage:" in captured.out.lower()


class TestProvisionerInstallErrors:
    """Test provisioner installation error cases."""

    @pytest.mark.asyncio
    async def test_install_script_no_script(self) -> None:
        """Test install via script with no script provided."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        prov = dot.Provisioner(
            name="no-script",
            description="No script",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=frozenset(["test"]),
            requires=frozenset(),
            install_script="",  # No script
        )

        manager = dot.ProvisionerManager({"no-script": prov}, runner, platform_obj)

        success = await manager._install_via_script(prov)
        assert success is False

    @pytest.mark.asyncio
    async def test_provision_missing_requirements(
        self,
        config_with_provisioners,
    ) -> None:
        """Test provisioning fails when requirements are missing."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()
        all_provisioners = config_with_provisioners.provisioners

        manager = dot.ProvisionerManager(all_provisioners, runner, platform_obj)

        # Mock that requirements are not met and provisioner is not installed
        with (
            patch.object(
                manager.resolver,
                "check_requirements",
                return_value=(False, ["curl"]),
            ),
            patch.object(manager, "_is_installed", return_value=False),
        ):
            results = await manager.provision_all()

            # Should return dict of results with rust failed
            assert isinstance(results, dict)
            assert "rust" in results
            assert results["rust"] is False


class TestProvisionerDependencies:
    """Test provisioner dependency handling."""

    def test_build_essential_install_order(self) -> None:
        """Test that build_essential has proper priority for installation order."""
        # Create provisioners
        build_essential = dot.Provisioner(
            name="build_essential",
            description="Essential build tools",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.PACKAGE,
            provides=frozenset(["cc", "gcc", "make", "pkg-config", "openssl"]),
            requires=frozenset(),
            package_name="build-essential",
            priority=1,  # Lower priority = installed first
            verify_command="cc --version",
        )

        rust = dot.Provisioner(
            name="rust",
            description="Rust toolchain",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=frozenset(["cargo", "rustc"]),
            requires=frozenset(["curl"]),
            priority=3,
        )

        sheldon = dot.Provisioner(
            name="sheldon",
            description="Zsh plugin manager",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=frozenset(["sheldon"]),
            requires=frozenset(["cargo", "cc"]),  # Requires both cargo and cc
            priority=4,
        )

        provisioners = {
            "build_essential": build_essential,
            "rust": rust,
            "sheldon": sheldon,
        }

        resolver = dot.DependencyResolver(provisioners)

        # Get install order - should be sorted by priority
        install_order = resolver.get_install_order()

        # build_essential (priority 1) should come first
        # rust (priority 3) should come second
        # sheldon (priority 4) should come third
        assert install_order.index("build_essential") == 0
        assert install_order.index("rust") == 1
        assert install_order.index("sheldon") == 2

    def test_sheldon_requires_cc_from_build_essential(self) -> None:
        """Test that sheldon's cc requirement is provided by build_essential."""
        build_essential = dot.Provisioner(
            name="build_essential",
            description="Essential build tools",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.PACKAGE,
            provides=frozenset(["cc", "gcc", "make", "pkg-config", "openssl"]),
            requires=frozenset(),
            priority=1,
        )

        sheldon = dot.Provisioner(
            name="sheldon",
            description="Zsh plugin manager",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=frozenset(["sheldon"]),
            requires=frozenset(["cargo", "cc"]),
            priority=4,
        )

        provisioners = {"build_essential": build_essential, "sheldon": sheldon}
        resolver = dot.DependencyResolver(provisioners)

        # Check that cc is in the provides map
        assert "cc" in resolver._provides_map
        assert resolver._provides_map["cc"] == "build_essential"

        # Find who provides cc for sheldon
        provider = resolver.find_provider("cc")
        assert provider == "build_essential"

    @pytest.mark.asyncio
    async def test_provision_build_essential_enables_sheldon_install(self) -> None:
        """Test that build-essential installation enables sheldon to compile."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        # Create provisioners with proper dependencies
        build_essential = dot.Provisioner(
            name="build_essential",
            description="Essential build tools",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.PACKAGE,
            provides=frozenset(["cc", "gcc", "make", "pkg-config", "openssl"]),
            requires=frozenset(),
            package_name="build-essential",
            priority=1,
            verify_command="cc --version",
        )

        rust = dot.Provisioner(
            name="rust",
            description="Rust toolchain",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=frozenset(["cargo", "rustc"]),
            requires=frozenset(["curl"]),
            priority=2,
            install_script=(
                "curl --proto '=https' --tlsv1.2 -sSf "
                "https://sh.rustup.rs | sh -s -- -y"
            ),
            verify_command="cargo --version",
        )

        sheldon = dot.Provisioner(
            name="sheldon",
            description="Zsh plugin manager",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=frozenset(["sheldon"]),
            requires=frozenset(["cargo", "cc"]),
            install_script="cargo install sheldon",
            priority=3,
            verify_command="sheldon --version",
        )

        provisioners = {
            "build_essential": build_essential,
            "rust": rust,
            "sheldon": sheldon,
        }
        manager = dot.ProvisionerManager(provisioners, runner, platform_obj)

        # Track installation order
        install_order = []

        async def mock_run(cmd, *args, **kwargs):
            # Track installation order
            if "build-essential" in cmd:
                install_order.append("build_essential")
            elif "rustup.rs" in cmd:
                install_order.append("rust")
            elif "cargo install sheldon" in cmd:
                install_order.append("sheldon")
            return dot.CommandResult(success=True)

        # Mock shutil.which to simulate curl is available but not cc/cargo initially
        def mock_which(tool) -> str | None:
            if tool == "curl":
                return "/usr/bin/curl"
            # After build_essential is "installed", cc is available
            if tool in {"cc", "gcc", "make"} and "build_essential" in install_order:
                return f"/usr/bin/{tool}"
            # After rust is "installed", cargo is available
            if tool in {"cargo", "rustc"} and "rust" in install_order:
                return f"/home/user/.cargo/bin/{tool}"
            return None

        with (
            patch.object(runner, "run", side_effect=mock_run),
            patch.object(manager, "_is_installed", return_value=False),
            patch("shutil.which", side_effect=mock_which),
        ):
            results = await manager.provision_all()

        # All should succeed in the right order
        assert results == {
            "build_essential": True,
            "rust": True,
            "sheldon": True,
        }

        # Verify installation order
        assert install_order == ["build_essential", "rust", "sheldon"]


class TestProvisionerPathHandling:
    """Test PATH handling between provisioner installations."""

    @pytest.mark.asyncio
    async def test_detect_path_additions(self, tmp_path) -> None:
        """Test detection of new PATH entries after installation."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        # Create a provisioner that provides cargo
        prov = dot.Provisioner(
            name="rust",
            description="Rust",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=frozenset(["cargo", "rustc"]),
            requires=frozenset(),
        )

        # Create the expected directory
        cargo_bin = tmp_path / ".cargo" / "bin"
        cargo_bin.mkdir(parents=True)

        with patch.dict(os.environ, {"HOME": str(tmp_path)}):
            manager = dot.ProvisionerManager({"rust": prov}, runner, platform_obj)

            # Detect PATH additions
            paths = await manager._detect_path_additions(prov)

            assert str(cargo_bin) in paths

    @pytest.mark.asyncio
    async def test_path_updated_between_provisioners(
        self,
        tmp_path,
        monkeypatch,
    ) -> None:
        """Test that PATH is updated after provisioner installs to new location."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        # Create mock provisioners
        rust = dot.Provisioner(
            name="rust",
            description="Rust toolchain",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=frozenset(["cargo", "rustc"]),
            requires=frozenset(),
            install_script=(
                f"mkdir -p {tmp_path}/.cargo/bin && "
                f"echo '#!/bin/sh\necho mock cargo' > {tmp_path}/.cargo/bin/cargo && "
                f"chmod +x {tmp_path}/.cargo/bin/cargo"
            ),
            priority=3,
        )

        sheldon = dot.Provisioner(
            name="sheldon",
            description="Plugin manager",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=frozenset(["sheldon"]),
            requires=frozenset(["cargo"]),
            install_script="cargo --version",  # Should find the mock cargo
            priority=4,
        )

        provisioners = {"rust": rust, "sheldon": sheldon}

        # Mock home directory and clean PATH
        monkeypatch.setenv("HOME", str(tmp_path))
        monkeypatch.setenv("PATH", "/usr/bin:/bin")

        manager = dot.ProvisionerManager(provisioners, runner, platform_obj)

        # Mock _is_installed to return False for both
        with patch.object(manager, "_is_installed", return_value=False):
            # Run provisioning
            results = await manager.provision_all()

        # Both should succeed if PATH handling works
        assert results["rust"] is True
        assert results["sheldon"] is True

    @pytest.mark.asyncio
    async def test_environment_passed_to_install_commands(self) -> None:
        """Test that updated environment is passed to installation commands."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        # Track environments passed to run()
        environments = []

        async def mock_run(cmd, **kwargs):
            if kwargs.get("env"):
                environments.append(kwargs["env"].get("PATH", ""))
            return dot.CommandResult(success=True)

        with patch.object(runner, "run", side_effect=mock_run):
            prov1 = dot.Provisioner(
                name="tool1",
                description="Tool 1",
                type=dot.ProvisionerType.PROVISIONER,
                install_method=dot.InstallMethod.SCRIPT,
                provides=frozenset(["tool1"]),
                requires=frozenset(),
                install_script="echo installing tool1",
                priority=1,
            )

            prov2 = dot.Provisioner(
                name="tool2",
                description="Tool 2",
                type=dot.ProvisionerType.PROVISIONER,
                install_method=dot.InstallMethod.SCRIPT,
                provides=frozenset(["tool2"]),
                requires=frozenset(["tool1"]),
                install_script="echo installing tool2",
                priority=2,
            )

            manager = dot.ProvisionerManager(
                {"tool1": prov1, "tool2": prov2},
                runner,
                platform_obj,
            )

            # Mock _is_installed and _detect_path_additions
            with (
                patch.object(manager, "_is_installed", return_value=False),
                patch.object(
                    manager,
                    "_detect_path_additions",
                    return_value=["/new/path"],
                ),
            ):
                await manager.provision_all()

            # Should have called run with environments
            assert len(environments) >= 2
            # Second call should have updated PATH
            if len(environments) >= 2:
                assert "/new/path" in environments[1]

    @pytest.mark.asyncio
    async def test_path_additions_with_wildcards(self, tmp_path) -> None:
        """Test PATH detection with wildcard patterns (e.g., ruby gems)."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        # Create a provisioner that provides gem
        prov = dot.Provisioner(
            name="ruby",
            description="Ruby",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=frozenset(["gem"]),
            requires=frozenset(),
        )

        # Create ruby gem directories with version
        gem_path = tmp_path / ".gem" / "ruby" / "3.0.0" / "bin"
        gem_path.mkdir(parents=True)

        with patch.dict(os.environ, {"HOME": str(tmp_path)}):
            manager = dot.ProvisionerManager({"ruby": prov}, runner, platform_obj)

            # Detect PATH additions
            paths = await manager._detect_path_additions(prov)

            # Should find the versioned gem bin directory
            assert any("3.0.0/bin" in path for path in paths)

    @pytest.mark.asyncio
    async def test_dry_run_does_not_update_path(self) -> None:
        """Test that dry run mode doesn't update PATH."""
        runner = dot.AsyncCommandRunner(dry_run=True)
        platform_obj = dot.Platform()

        prov = dot.Provisioner(
            name="test",
            description="Test",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=frozenset(["test"]),
            requires=frozenset(),
            install_script="echo test",
        )

        manager = dot.ProvisionerManager({"test": prov}, runner, platform_obj)

        # Track if _detect_path_additions is called
        detect_called = False

        async def mock_detect(prov):
            nonlocal detect_called
            detect_called = True
            return ["/some/path"]

        with (
            patch.object(manager, "_is_installed", return_value=False),
            patch.object(manager, "_detect_path_additions", side_effect=mock_detect),
        ):
            results = await manager.provision_all(dry_run=True)

        # Should succeed but not call path detection in dry run
        assert results["test"] is True
        assert not detect_called

    @pytest.mark.asyncio
    async def test_multiple_path_patterns_for_single_tool(self, tmp_path) -> None:
        """Test tools with multiple possible PATH locations."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        # npm can install to multiple locations
        prov = dot.Provisioner(
            name="npm",
            description="NPM",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=frozenset(["npm"]),
            requires=frozenset(),
        )

        # Create both possible npm paths
        npm_global = tmp_path / ".npm-global" / "bin"
        npm_packages = tmp_path / ".npm-packages" / "bin"
        npm_global.mkdir(parents=True)
        npm_packages.mkdir(parents=True)

        with patch.dict(os.environ, {"HOME": str(tmp_path)}):
            manager = dot.ProvisionerManager({"npm": prov}, runner, platform_obj)

            # Detect PATH additions
            paths = await manager._detect_path_additions(prov)

            # Should find both npm paths
            assert str(npm_global) in paths
            assert str(npm_packages) in paths


class TestErrorOutputCapture:
    """Test error output capture and logging."""

    @pytest.mark.asyncio
    async def test_script_install_captures_stderr(
        self,
        caplog: pytest.LogCaptureFixture,
    ) -> None:
        """Test that script installation captures and logs stderr."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        prov = dot.Provisioner(
            name="test-fail",
            description="Test failing script",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=frozenset(["test"]),
            requires=frozenset(),
            install_script="echo 'Error: Missing dependency' >&2 && exit 1",
        )

        manager = dot.ProvisionerManager({"test-fail": prov}, runner, platform_obj)

        with caplog.at_level(logging.ERROR):
            success = await manager._install_via_script(prov)

        assert success is False
        assert "Failed to install test-fail" in caplog.text
        assert "Error output:" in caplog.text
        assert "Error: Missing dependency" in caplog.text

    @pytest.mark.asyncio
    async def test_script_install_captures_stdout_in_debug(
        self,
        caplog: pytest.LogCaptureFixture,
    ) -> None:
        """Test that script installation captures stdout to debug log."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        prov = dot.Provisioner(
            name="test-fail",
            description="Test failing script with stdout",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=frozenset(["test"]),
            requires=frozenset(),
            install_script=(
                "echo 'Starting installation...' && echo 'ERROR!' >&2 && exit 1"
            ),
        )

        manager = dot.ProvisionerManager({"test-fail": prov}, runner, platform_obj)

        with caplog.at_level(logging.DEBUG):
            success = await manager._install_via_script(prov)

        assert success is False
        assert "Standard output:" in caplog.text
        assert "Starting installation..." in caplog.text

    @pytest.mark.asyncio
    async def test_package_install_captures_errors(
        self,
        caplog: pytest.LogCaptureFixture,
    ) -> None:
        """Test that package installation captures and logs errors."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        prov = dot.Provisioner(
            name="nonexistent-pkg",
            description="Test nonexistent package",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.PACKAGE,
            provides=frozenset(["test"]),
            requires=frozenset(),
        )

        manager = dot.ProvisionerManager(
            {"nonexistent-pkg": prov},
            runner,
            platform_obj,
        )

        # Mock the package manager command to fail
        with (
            patch.object(platform_obj, "get_package_manager", return_value="apt"),
            patch.object(
                runner,
                "run",
                new_callable=unittest.mock.AsyncMock,
            ) as mock_run,
            caplog.at_level(logging.ERROR),
        ):
            mock_run.return_value = dot.CommandResult(
                success=False,
                stderr="E: Unable to locate package nonexistent-pkg",
                returncode=100,
            )

            success = await manager._install_via_package(prov)

        assert success is False
        assert "Failed to install nonexistent-pkg via apt" in caplog.text
        assert "Error output:" in caplog.text
        assert "Unable to locate package nonexistent-pkg" in caplog.text

    @pytest.mark.asyncio
    async def test_binary_install_download_error(
        self,
        caplog: pytest.LogCaptureFixture,
    ) -> None:
        """Test binary installation captures download errors."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        prov = dot.Provisioner(
            name="test-bin",
            description="Test binary",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.BINARY,
            provides=frozenset(["test"]),
            requires=frozenset(),
            binary_url="https://invalid.example.com/nonexistent",
        )

        manager = dot.ProvisionerManager({"test-bin": prov}, runner, platform_obj)

        with (
            patch.object(
                runner,
                "run",
                new_callable=unittest.mock.AsyncMock,
            ) as mock_run,
            caplog.at_level(logging.ERROR),
        ):
            # First call fails (curl download)
            mock_run.return_value = dot.CommandResult(
                success=False,
                stderr="curl: (6) Could not resolve host: invalid.example.com",
                returncode=6,
            )

            success = await manager._install_via_binary(prov)

        assert success is False
        assert "Failed to download test-bin" in caplog.text
        assert "Error output:" in caplog.text
        assert "Could not resolve host" in caplog.text

    @pytest.mark.asyncio
    async def test_binary_install_permission_error(
        self,
        caplog: pytest.LogCaptureFixture,
    ) -> None:
        """Test binary installation captures permission errors."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        prov = dot.Provisioner(
            name="test-bin",
            description="Test binary",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.BINARY,
            provides=frozenset(["test"]),
            requires=frozenset(),
            binary_url="https://example.com/test-bin",
        )

        manager = dot.ProvisionerManager({"test-bin": prov}, runner, platform_obj)

        with (
            patch.object(
                runner,
                "run",
                new_callable=unittest.mock.AsyncMock,
            ) as mock_run,
            caplog.at_level(logging.ERROR),
        ):
            # Download succeeds, chmod succeeds, mv fails
            mock_run.side_effect = [
                dot.CommandResult(success=True),  # curl
                dot.CommandResult(success=True),  # chmod
                dot.CommandResult(
                    success=False,
                    stderr=(
                        "mv: cannot move '/tmp/test-bin' to "
                        "'/usr/local/bin/': Permission denied"
                    ),
                    returncode=1,
                ),  # mv
            ]

            success = await manager._install_via_binary(prov)

        assert success is False
        assert "Failed to move test-bin to /usr/local/bin/" in caplog.text
        assert "Error output:" in caplog.text
        assert "Permission denied" in caplog.text

    @pytest.mark.asyncio
    async def test_exception_logging(self, caplog: pytest.LogCaptureFixture) -> None:
        """Test that exceptions are logged with traceback."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        prov = dot.Provisioner(
            name="test-exception",
            description="Test exception",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=frozenset(["test"]),
            requires=frozenset(),
            install_script="test",
        )

        manager = dot.ProvisionerManager({"test-exception": prov}, runner, platform_obj)

        with (
            patch.object(runner, "run", side_effect=Exception("Unexpected error")),
            caplog.at_level(logging.ERROR),
        ):
            success = await manager._install_via_script(prov)

        assert success is False
        assert "Failed to install test-exception" in caplog.text
        # logger.exception includes traceback info

    @pytest.mark.asyncio
    async def test_real_command_error(self, caplog: pytest.LogCaptureFixture) -> None:
        """Test with a real command that fails."""
        runner = dot.AsyncCommandRunner(dry_run=False)
        platform_obj = dot.Platform()

        prov = dot.Provisioner(
            name="test-real",
            description="Test real command",
            type=dot.ProvisionerType.PROVISIONER,
            install_method=dot.InstallMethod.SCRIPT,
            provides=frozenset(["test"]),
            requires=frozenset(),
            install_script="ls /nonexistent/directory",
        )

        manager = dot.ProvisionerManager({"test-real": prov}, runner, platform_obj)

        with caplog.at_level(logging.ERROR):
            success = await manager._install_via_script(prov)

        assert success is False
        assert "Failed to install test-real" in caplog.text
        assert "Error output:" in caplog.text
        # The actual error message varies by system but should mention the directory
        assert (
            "nonexistent" in caplog.text or "No such file or directory" in caplog.text
        )


class TestNonInteractiveInstallers:
    """Test non-interactive installation scripts."""

    @pytest.mark.asyncio
    async def test_starship_installer_non_interactive(self) -> None:
        """Test that starship installer includes --yes flag."""
        config_loader = dot.ConfigLoader()
        config = config_loader.load()

        # Find starship enhancement
        starship = config.enhancements.get("starship")
        assert starship is not None
        assert "--yes" in starship.install_script
        assert "sh -s -- --yes" in starship.install_script

    def test_build_essential_includes_pkg_config(self) -> None:
        """Test that build_essential provisioner includes pkg-config."""
        config_loader = dot.ConfigLoader()
        config = config_loader.load()

        # Find build_essential provisioner
        build_essential = config.provisioners.get("build_essential")
        assert build_essential is not None
        assert "pkg-config" in build_essential.provides
        assert "openssl" in build_essential.provides
        # Should use script method to install multiple packages
        assert build_essential.install_method == dot.InstallMethod.SCRIPT
        assert "pkg-config" in build_essential.install_script
        assert "libssl-dev" in build_essential.install_script


class TestSymlinkCorrectness:
    """Test that symlinks are created in the correct direction."""

    @pytest.mark.asyncio
    async def test_symlink_direction(
        self,
        tmp_path: pathlib.Path,
        temp_home: pathlib.Path,
    ) -> None:
        """Test that symlinks are created from home to dot-config, not vice versa."""
        # Create source directory and file
        dot_config = tmp_path / "dot-config"
        dot_config.mkdir()
        source_file = dot_config / ".zshrc"
        source_file.write_text("# zsh config")

        # Create a simple config
        config_content = f"""
[config]
source = "{dot_config}"

[home.files]
".zshrc" = ".zshrc"
"""
        config_path = tmp_path / "dot.toml"
        config_path.write_text(config_content)

        app = dot.DotfilesApp(config_path=config_path, dry_run=False)

        success = await app.install_dotfiles()

        assert success is True

        # The symlink should exist in the home directory
        home_link = temp_home / ".zshrc"
        assert home_link.exists()
        assert home_link.is_symlink()

        # The symlink should point to the source file
        assert home_link.resolve() == source_file.resolve()

        # The source file should NOT be a symlink
        assert not source_file.is_symlink()
        assert source_file.is_file()

        # Reading through the symlink should give us the source content
        assert home_link.read_text() == "# zsh config"


class TestPathExpansionBug:
    """Test that config.source path is properly expanded."""

    async def test_config_source_path_expansion(self, tmp_path: pathlib.Path) -> None:
        """Test that ~/.dot-config is expanded to full path."""
        # Create config with unexpanded path
        config_content = """
[config]
source = "~/.dot-config"

[home.files]
".gitconfig" = ".gitconfig"
"""
        config_file = tmp_path / "dot.toml"
        config_file.write_text(config_content)

        # Load config
        loader = dot.ConfigLoader(config_file)
        config = loader.load()

        # Fixed: config.source should be expanded
        assert config.source == pathlib.Path.home() / ".dot-config"
        assert "~" not in str(config.source)

    async def test_status_reports_ok_with_expanded_paths(
        self,
        tmp_path: pathlib.Path,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """Test that status reports ok when paths are properly expanded."""
        # Setup paths
        home_dir = tmp_path / "home"
        dot_config_dir = home_dir / ".dot-config"
        home_dir.mkdir()
        dot_config_dir.mkdir()

        # Create source file
        source_file = dot_config_dir / ".gitconfig"
        source_file.write_text("[user]\nname = Test")

        # Create symlink (as dot.py would)
        symlink = home_dir / ".gitconfig"
        symlink.symlink_to(dot_config_dir / ".gitconfig")

        # Mock home directory BEFORE creating config
        monkeypatch.setenv("HOME", str(home_dir))

        # Create config
        config_content = """
[config]
source = "~/.dot-config"

[home.files]
".gitconfig" = ".gitconfig"
"""
        config_file = tmp_path / "dot.toml"
        config_file.write_text(config_content)

        # Create app and check status (HOME is already mocked)
        app = dot.DotfilesApp(config_path=config_file)
        status = await app.status()

        # Fixed: status should report "ok" now that paths are expanded
        assert status["dotfiles"][".gitconfig"] == "ok"


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--cov=dot", "--cov-report=term-missing"])
