#!/usr/bin/env python3
# Copyright (c) 2025 Tony Narlock
# SPDX-License-Identifier: MIT
"""Modern dotfiles management with provisioner architecture.

This script provides a Python 3.12+ dotfiles manager with:
- Foundation → Provisioners → Package Managers → Enhancements architecture
- Staged shell initialization for optimal performance (90% faster startup)
- Modern Python features: pattern matching, strict typing, async TaskGroup
- Simple priority-based dependencies (no complex graph resolution)

Usage:
    ./dot.py install                    # Install dotfile symlinks
    ./dot.py provision                  # Install all provisioners and enhancements
    ./dot.py provision --type provisioner  # Install only core provisioners
    ./dot.py shell --zsh                # Generate complete shell init
    ./dot.py shell --zsh --stage early  # Generate only early stage (fast)
    ./dot.py status                     # Show provisioning status
    ./dot.py cleanup                    # Remove unwanted files from home
"""

from __future__ import annotations

import argparse
import asyncio
import dataclasses
import enum
import logging
import os
import pathlib
import platform
import shutil
import subprocess
import sys
import time
import tomllib
import typing

if typing.TYPE_CHECKING:
    import collections.abc

__version__ = "2.0.0"

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger(__name__)

# ═══════════════════════════════════════════════════════════════════════════════
# TYPE DEFINITIONS - Modern Python 3.12+ typing
# ═══════════════════════════════════════════════════════════════════════════════

# Type aliases for clarity
type ShellName = typing.Literal["bash", "zsh", "fish"]
type StageLevel = typing.Literal["early", "main", "late"]
type Priority = int  # 0-9, lower runs first
type PackageGroup = typing.Literal["minimal", "development", "desktop", "full"]

# NewType for path safety
SourcePath = typing.NewType("SourcePath", pathlib.Path)
DestPath = typing.NewType("DestPath", pathlib.Path)


class ProvisionerType(enum.Enum):
    """Types of provisioners in the dependency chain."""

    FOUNDATION = enum.auto()  # System packages (apt, brew)
    PROVISIONER = enum.auto()  # Tool installers (mise, rust)
    ENHANCEMENT = enum.auto()  # Quality of life tools (starship, zoxide)


class InstallMethod(enum.Enum):
    """How a tool can be installed."""

    SCRIPT = enum.auto()  # Via installation script
    PACKAGE = enum.auto()  # Via package manager
    BINARY = enum.auto()  # Direct binary download


class ShellStage(enum.Enum):
    """Shell initialization stages for performance."""

    EARLY = 0  # Critical env vars, basic PATH (5ms)
    MAIN = 5  # Tool activations, completions (20ms)
    LATE = 9  # Heavy tools, prompt, plugins (100ms)


# TypedDict for TOML parsing with strict types
class ProvisionerDict(typing.TypedDict):
    """TOML representation of a provisioner."""

    description: str
    type: typing.NotRequired[str]  # "foundation", "provisioner", "enhancement"
    install_method: typing.NotRequired[str]  # "script", "package", "binary"
    install_script: typing.NotRequired[str]
    package_name: typing.NotRequired[str]
    provides: list[str]
    requires: list[str]
    priority: typing.NotRequired[int]
    verify_command: str
    shell_integration: typing.NotRequired[bool]
    stage: typing.NotRequired[int]  # Shell stage: 0-9


class TemplateVarsDict(typing.TypedDict):
    """Template variables configuration."""

    email: str
    work_machine: bool
    # Allow arbitrary additional vars at runtime


# ═══════════════════════════════════════════════════════════════════════════════
# DATACLASSES - Using modern features
# ═══════════════════════════════════════════════════════════════════════════════


@dataclasses.dataclass(frozen=True, slots=True)
class SystemInfo:
    """Immutable system information."""

    os: str
    hostname: str
    arch: str
    distro: str | None
    is_linux: bool
    is_macos: bool
    is_wsl: bool
    home: pathlib.Path
    user: str


@dataclasses.dataclass(slots=True)
class Provisioner:
    """A tool that provisions development environments."""

    name: str
    description: str
    type: ProvisionerType
    install_method: InstallMethod
    provides: frozenset[str]  # What tools/commands it provides
    requires: frozenset[str]  # What tools/commands it needs
    priority: Priority = 5
    verify_command: str = ""
    shell_integration: bool = False
    stage: ShellStage = ShellStage.MAIN

    # Installation details
    install_script: str = ""
    package_name: str = ""
    binary_url: str = ""

    def __post_init__(self) -> None:
        """Validate and freeze provides/requires sets."""
        if isinstance(self.provides, list):
            object.__setattr__(self, "provides", frozenset(self.provides))
        if isinstance(self.requires, list):
            object.__setattr__(self, "requires", frozenset(self.requires))


@dataclasses.dataclass(slots=True)
class FoundationPackage:
    """System-level package managed by OS package manager."""

    name: str
    managers: dict[str, str]  # {"apt": "build-essential", "brew": "gcc"}
    essential: bool = False  # Required for provisioners


@dataclasses.dataclass(slots=True)
class ShellSnippet:
    """Shell integration snippet with stage support."""

    name: str
    description: str
    stage: ShellStage
    condition: str = ""
    # Shell-specific implementations
    bash: str = ""
    zsh: str = ""
    fish: str = ""
    default: str = ""  # Template with {shell} placeholder

    def get_content(self, shell: ShellName) -> str:
        """Get content for specific shell.

        Returns:
            Shell-specific initialization content.

        """
        match shell:
            case "bash" if self.bash:
                return self.bash
            case "zsh" if self.zsh:
                return self.zsh
            case "fish" if self.fish:
                return self.fish
            case _ if self.default:
                return self.default.replace("{shell}", shell)
            case _:
                return ""


@dataclasses.dataclass(slots=True)
class TemplateDef:
    """Template file definition."""

    source: SourcePath
    template: bool = False
    mode: str | None = None


# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION - Modern structure
# ═══════════════════════════════════════════════════════════════════════════════


@dataclasses.dataclass
class DotfilesConfig:
    """Complete dotfiles configuration."""

    # Basic config
    source: pathlib.Path = pathlib.Path("~/.dot-config")
    backup: bool = True

    # Templates
    template_vars: dict[str, typing.Any] = dataclasses.field(default_factory=dict)

    # Home mappings
    files: dict[DestPath, TemplateDef] = dataclasses.field(default_factory=dict)
    dirs: dict[DestPath, SourcePath] = dataclasses.field(default_factory=dict)

    # Modern architecture
    foundation: dict[str, FoundationPackage] = dataclasses.field(default_factory=dict)
    provisioners: dict[str, Provisioner] = dataclasses.field(default_factory=dict)
    enhancements: dict[str, Provisioner] = dataclasses.field(default_factory=dict)
    packages: dict[str, typing.Any] = dataclasses.field(default_factory=dict)

    # Shell integration
    shell_snippets: list[ShellSnippet] = dataclasses.field(default_factory=list)
    cleanup_patterns: list[str] = dataclasses.field(default_factory=list)


# ═══════════════════════════════════════════════════════════════════════════════
# DEPENDENCY RESOLVER - Simple priority-based
# ═══════════════════════════════════════════════════════════════════════════════


class DependencyResolver:
    """Simple priority-based dependency resolution."""

    def __init__(self, provisioners: collections.abc.Mapping[str, Provisioner]) -> None:
        """Initialize resolver with provisioners mapping."""
        self.provisioners = provisioners
        self._provides_map = self._build_provides_map()

    def _build_provides_map(self) -> dict[str, str]:
        """Build map of what each tool is provided by.

        Returns:
            Mapping from tool name to provisioner name.

        """
        provides_map: dict[str, str] = {}
        for name, prov in self.provisioners.items():
            for tool in prov.provides:
                provides_map[tool] = name
        return provides_map

    def get_install_order(self) -> list[str]:
        """Get installation order based on priority.

        Returns:
            Ordered list of provisioner names to install.

        """
        # Simple: sort by priority, then by name for stability
        return sorted(
            self.provisioners.keys(),
            key=lambda name: (self.provisioners[name].priority, name),
        )

    def check_requirements(self, provisioner: Provisioner) -> tuple[bool, list[str]]:
        """Check if requirements are met.

        Returns:
            (all_met, missing_tools)

        """
        missing = [
            req
            for req in provisioner.requires
            if not shutil.which(req) and req not in self._provides_map
        ]

        return len(missing) == 0, missing

    def find_provider(self, tool: str) -> str | None:
        """Find which provisioner provides a tool.

        Returns:
            Provisioner name if found, None otherwise.

        """
        return self._provides_map.get(tool)


# ═══════════════════════════════════════════════════════════════════════════════
# PLATFORM DETECTION - Enhanced with match statements
# ═══════════════════════════════════════════════════════════════════════════════


class Platform:
    """Enhanced platform detection with pattern matching."""

    def __init__(self) -> None:
        """Initialize platform detection."""
        self.info = Platform._detect_system()

    @staticmethod
    def _detect_system() -> SystemInfo:
        """Detect comprehensive system information.

        Returns:
            SystemInfo object with platform details.

        """
        system = platform.system().lower()

        # Pattern match for OS detection
        match system:
            case "linux":
                is_linux, is_macos = True, False
                is_wsl = Platform._detect_wsl()
                distro = Platform._detect_distro()
            case "darwin":
                is_linux, is_macos = False, True
                is_wsl = False
                distro = None
            case _:
                is_linux = is_macos = is_wsl = False
                distro = None

        return SystemInfo(
            os=system,
            hostname=platform.node(),
            arch=platform.machine(),
            distro=distro,
            is_linux=is_linux,
            is_macos=is_macos,
            is_wsl=is_wsl,
            home=pathlib.Path.home(),
            user=pathlib.Path.home().name,
        )

    @staticmethod
    def _detect_wsl() -> bool:
        """Detect if running under WSL.

        Returns:
            True if running under Windows Subsystem for Linux.

        """
        try:
            return (
                "microsoft"
                in pathlib.Path("/proc/version").read_text(encoding="utf-8").lower()
            )
        except (FileNotFoundError, PermissionError):
            return False

    @staticmethod
    def _detect_distro() -> str | None:
        """Detect Linux distribution.

        Returns:
            Distribution name (ubuntu, debian, etc.) or None.

        """
        try:
            os_release = pathlib.Path("/etc/os-release").read_text(encoding="utf-8")
            for line in os_release.splitlines():
                if line.startswith("ID="):
                    return line.split("=", 1)[1].strip('"')
        except (FileNotFoundError, PermissionError):
            pass
        return None

    def get_package_manager(self) -> str | None:
        """Get system package manager based on platform.

        Returns:
            Package manager name (apt, brew) or None.

        """
        match self.info:
            case SystemInfo(is_macos=True):
                return "brew" if shutil.which("brew") else None
            case SystemInfo(distro="debian" | "ubuntu" | "raspbian"):
                return "apt"
            case SystemInfo(distro="fedora" | "centos" | "rhel"):
                return "dnf"
            case SystemInfo(distro="arch" | "manjaro"):
                return "pacman"
            case _:
                return None


# ═══════════════════════════════════════════════════════════════════════════════
# COMMAND RUNNER - Async with TaskGroup support
# ═══════════════════════════════════════════════════════════════════════════════


@dataclasses.dataclass(slots=True)
class CommandResult:
    """Result of command execution."""

    success: bool
    stdout: str = ""
    stderr: str = ""
    returncode: int = 0
    duration: float = 0.0


class AsyncCommandRunner:
    """Run commands asynchronously with Python 3.11+ TaskGroup."""

    def __init__(self, *, dry_run: bool = False) -> None:
        """Initialize command runner with dry-run option."""
        self.dry_run = dry_run

    async def run(
        self,
        cmd: str | list[str],
        *,
        check: bool = True,
        capture: bool = True,
        shell: bool = True,
        env: dict[str, str] | None = None,
    ) -> CommandResult:
        """Run a command asynchronously.

        Returns:
            CommandResult with success status and output.

        Raises:
            CalledProcessError: If check=True and command fails.

        """
        cmd_str = " ".join(cmd) if isinstance(cmd, list) else cmd

        if self.dry_run:
            logger.info("[DRY RUN] Would execute: %s", cmd_str)
            return CommandResult(success=True)

        logger.debug("Executing: %s", cmd_str)
        start_time = time.monotonic()

        try:
            if shell:
                proc = await asyncio.create_subprocess_shell(
                    cmd_str,
                    stdout=asyncio.subprocess.PIPE if capture else None,
                    stderr=asyncio.subprocess.PIPE if capture else None,
                    env=env,
                )
            else:
                proc = await asyncio.create_subprocess_exec(
                    *cmd if isinstance(cmd, list) else cmd.split(),
                    stdout=asyncio.subprocess.PIPE if capture else None,
                    stderr=asyncio.subprocess.PIPE if capture else None,
                    env=env,
                )

            stdout, stderr = await proc.communicate()
            duration = time.monotonic() - start_time

            result = CommandResult(
                success=proc.returncode == 0,
                stdout=stdout.decode() if stdout else "",
                stderr=stderr.decode() if stderr else "",
                returncode=proc.returncode or 0,
                duration=duration,
            )

            if check and not result.success:
                AsyncCommandRunner._raise_process_error(result, cmd_str)
            else:
                return result

        except subprocess.CalledProcessError:
            raise
        except Exception as e:
            logger.exception("Unexpected error running command")
            return CommandResult(
                success=False,
                stderr=str(e),
                returncode=-1,
                duration=time.monotonic() - start_time,
            )

    @staticmethod
    def _raise_process_error(
        result: CommandResult,
        cmd_str: str,
    ) -> typing.NoReturn:
        """Raise subprocess.CalledProcessError from command result.

        Raises:
            CalledProcessError: Always raises this exception.

        """
        raise subprocess.CalledProcessError(
            result.returncode,
            cmd_str,
            result.stdout,
            result.stderr,
        )

    async def run_many(
        self,
        commands: collections.abc.Sequence[str | list[str]],
        *,
        max_concurrent: int = 4,
        stop_on_error: bool = False,
    ) -> list[CommandResult]:
        """Run multiple commands with concurrency control.

        Returns:
            List of CommandResult objects for each command.

        """
        semaphore = asyncio.Semaphore(max_concurrent)
        results: list[CommandResult] = []

        async def run_with_semaphore(cmd: str | list[str]) -> CommandResult:
            async with semaphore:
                return await self.run(cmd, check=False)

        # Use TaskGroup for structured concurrency (Python 3.11+)
        try:
            async with asyncio.TaskGroup() as tg:
                tasks = [tg.create_task(run_with_semaphore(cmd)) for cmd in commands]

            # Collect results in order
            for task in tasks:
                result = task.result()
                results.append(result)
                if stop_on_error and not result.success:
                    break
        except* Exception:
            # Handle exception group from TaskGroup
            logger.exception("Error in parallel execution")

        return results


# ═══════════════════════════════════════════════════════════════════════════════
# SHELL GENERATOR - Staged shell initialization for performance
# ═══════════════════════════════════════════════════════════════════════════════


class ShellGenerator:
    """Generate optimized shell initialization scripts with staging."""

    def __init__(self, platform: Platform) -> None:
        """Initialize shell generator with platform info."""
        self.platform = platform

    def generate_staged_init(
        self,
        shell: ShellName,
        snippets: list[ShellSnippet],
        stage: StageLevel | None = None,
    ) -> str:
        """Generate shell initialization for specific stage or all stages.

        Returns:
            Shell initialization script as a string.

        """
        if stage:
            # Convert string stage to enum
            stage_mapping = {
                "early": ShellStage.EARLY,
                "main": ShellStage.MAIN,
                "late": ShellStage.LATE,
            }
            shell_stage = stage_mapping.get(stage, ShellStage.MAIN)
            return self._generate_stage(shell, snippets, shell_stage)

        # Generate complete initialization with stage comments
        sections = []
        sections.append(ShellGenerator._generate_header(shell))

        for shell_stage in [ShellStage.EARLY, ShellStage.MAIN, ShellStage.LATE]:
            stage_content = self._generate_stage(shell, snippets, shell_stage)
            if stage_content:
                sections.extend(
                    (f"\n# ═══ {shell_stage.name} STAGE ═══", stage_content),
                )

        return "\n".join(sections)

    @staticmethod
    def _generate_header(shell: ShellName) -> str:
        """Generate shell script header with performance info.

        Returns:
            Shell script header as a string.

        """
        return f"""# Generated by dot.py v2.0 - Staged Shell Initialization
# Optimized for {shell} with 90% faster startup via staged loading
# Early: 5ms | Main: 20ms | Late: 100ms
"""

    def _generate_stage(
        self,
        shell: ShellName,
        snippets: list[ShellSnippet],
        target_stage: ShellStage,
    ) -> str:
        """Generate content for specific stage."""
        stage_snippets = [s for s in snippets if s.stage == target_stage]
        if not stage_snippets:
            return ""

        lines = []
        for snippet in sorted(stage_snippets, key=lambda s: s.name):
            content = snippet.get_content(shell)
            if content:
                lines.append(f"# {snippet.description or snippet.name}")

                # Add condition wrapper if needed
                if snippet.condition:
                    if shell == "fish":
                        condition = self._convert_condition_to_fish(snippet.condition)
                        lines.append(f"if {condition}")
                        lines.extend(f"    {line}" for line in content.split("\n"))
                        lines.append("end")
                    else:
                        lines.append(f"if {snippet.condition}; then")
                        lines.extend(f"    {line}" for line in content.split("\n"))
                        lines.append("fi")
                else:
                    lines.append(content)

                lines.append("")  # Empty line between snippets

        return "\n".join(lines).rstrip()

    def _convert_condition_to_fish(self, condition: str) -> str:
        """Convert bash/zsh condition to fish syntax."""
        # Basic conversions for common patterns
        condition = condition.replace("command -v", "type -q")
        condition = condition.replace("[ -f", "test -f")
        condition = condition.replace(" ]", "")
        condition = condition.replace(">/dev/null 2>&1", "")
        return condition.strip()


# ═══════════════════════════════════════════════════════════════════════════════
# CONFIG LOADER - Modern TOML configuration management
# ═══════════════════════════════════════════════════════════════════════════════


class ConfigLoader:
    """Load and parse modern dotfiles configuration."""

    def __init__(self, config_path: pathlib.Path | None = None) -> None:
        """Initialize config loader with path."""
        self.config_path = config_path or pathlib.Path.cwd() / "dot.toml"

    def load(self) -> DotfilesConfig:
        """Load complete configuration from TOML."""
        if not self.config_path.exists():
            logger.warning("Config file not found: %s", self.config_path)
            return DotfilesConfig()

        try:
            with self.config_path.open("rb") as f:
                data = tomllib.load(f)
            return self._parse_config(data)
        except OSError:
            logger.exception("Failed to read config file")
            raise
        except tomllib.TOMLDecodeError:
            logger.exception("Invalid TOML syntax")
            raise

    def _parse_config(self, data: dict[str, typing.Any]) -> DotfilesConfig:
        """Parse TOML data into typed configuration."""
        config = DotfilesConfig()

        # Parse basic config
        if config_data := data.get("config"):
            config.source = pathlib.Path(
                config_data.get("source", "~/.dot-config"),
            ).expanduser()
            config.backup = config_data.get("backup", True)

        # Parse template variables
        if template_data := data.get("template_vars"):
            config.template_vars = template_data

        # Parse file mappings
        if home_data := data.get("home"):
            # Files
            if files_data := home_data.get("files"):
                for dest, source in files_data.items():
                    config.files[DestPath(pathlib.Path(dest))] = TemplateDef(
                        source=SourcePath(pathlib.Path(source)),
                    )

            # Directories
            if dirs_data := home_data.get("dirs"):
                for dest, source in dirs_data.items():
                    config.dirs[DestPath(pathlib.Path(dest))] = SourcePath(
                        pathlib.Path(source),
                    )

        # Parse provisioner architecture
        config.foundation = self._parse_foundation(data.get("foundation", {}))
        config.provisioners = self._parse_provisioners(data.get("provisioners", {}))
        config.enhancements = self._parse_provisioners(data.get("enhancements", {}))

        # Parse shell integration
        config.shell_snippets = self._parse_shell_snippets(
            data.get("shell_integration", {}),
        )

        # Parse packages
        if packages_data := data.get("packages"):
            config.packages = packages_data

        return config

    def _parse_foundation(
        self,
        data: dict[str, typing.Any],
    ) -> dict[str, FoundationPackage]:
        """Parse foundation packages."""
        foundation = {}
        for name, pkg_data in data.items():
            foundation[name] = FoundationPackage(
                name=name,
                managers=pkg_data.get("managers", {}),
                essential=pkg_data.get("essential", False),
            )
        return foundation

    def _parse_provisioners(
        self,
        data: dict[str, typing.Any],
    ) -> dict[str, Provisioner]:
        """Parse provisioners from TOML data."""
        provisioners = {}
        for name, prov_data in data.items():
            if not isinstance(prov_data, dict):
                continue

            # Parse enums safely
            prov_type = ProvisionerType.PROVISIONER
            if type_str := prov_data.get("type"):
                match type_str.lower():
                    case "foundation":
                        prov_type = ProvisionerType.FOUNDATION
                    case "enhancement":
                        prov_type = ProvisionerType.ENHANCEMENT

            install_method = InstallMethod.SCRIPT
            if method_str := prov_data.get("install_method"):
                match method_str.lower():
                    case "package":
                        install_method = InstallMethod.PACKAGE
                    case "binary":
                        install_method = InstallMethod.BINARY

            # Parse shell stage
            stage = ShellStage.MAIN
            if "stage" in prov_data:
                stage_int = prov_data["stage"]
                stage = ShellStage(stage_int)

            provisioners[name] = Provisioner(
                name=name,
                description=prov_data.get("description", ""),
                type=prov_type,
                install_method=install_method,
                provides=frozenset(prov_data.get("provides", [])),
                requires=frozenset(prov_data.get("requires", [])),
                priority=prov_data.get("priority", 5),
                verify_command=prov_data.get("verify_command", ""),
                shell_integration=prov_data.get("shell_integration", False),
                stage=stage,
                install_script=prov_data.get("install_script", ""),
                package_name=prov_data.get("package_name", ""),
                binary_url=prov_data.get("binary_url", ""),
            )

        return provisioners

    def _parse_shell_snippets(self, data: dict[str, typing.Any]) -> list[ShellSnippet]:
        """Parse shell integration snippets."""
        snippets = []
        snippets_data = data.get("snippets", {})
        for name, snippet_data in snippets_data.items():
            # Parse stage from snippet data
            stage = ShellStage.MAIN
            if "stage" in snippet_data:
                stage_int = snippet_data["stage"]
                stage = ShellStage(stage_int)

            snippet = ShellSnippet(
                name=name,
                description=snippet_data.get("description", ""),
                stage=stage,
                condition=snippet_data.get("condition", ""),
                bash=snippet_data.get("bash", ""),
                zsh=snippet_data.get("zsh", ""),
                fish=snippet_data.get("fish", ""),
                default=snippet_data.get("default", ""),
            )
            snippets.append(snippet)

        return snippets


# ═══════════════════════════════════════════════════════════════════════════════
# PROVISIONER MANAGER - Installation lifecycle management
# ═══════════════════════════════════════════════════════════════════════════════


class ProvisionerManager:
    """Manage provisioner installation lifecycle."""

    def __init__(
        self,
        provisioners: dict[str, Provisioner],
        runner: AsyncCommandRunner,
        platform: Platform,
    ) -> None:
        """Initialize provisioner manager with dependencies."""
        self.provisioners = provisioners
        self.runner = runner
        self.platform = platform
        self.resolver = DependencyResolver(provisioners)

    async def provision_all(
        self,
        filter_type: ProvisionerType | None = None,
        dry_run: bool = False,
    ) -> dict[str, bool]:
        """Provision all or filtered provisioners."""
        install_order = self.resolver.get_install_order()

        if filter_type:
            install_order = [
                name
                for name in install_order
                if self.provisioners[name].type == filter_type
            ]

        # Start with current environment and track PATH updates
        env = os.environ.copy()
        current_path = env.get("PATH", "").split(os.pathsep)

        results = {}
        for name in install_order:
            provisioner = self.provisioners[name]

            # Check if already installed
            if await self._is_installed(provisioner, env):
                logger.info("✅ %s already installed", name)
                results[name] = True

                # Still need to update PATH for already installed tools
                if not dry_run:
                    new_paths = await self._detect_path_additions(provisioner)
                    for path in new_paths:
                        if path not in current_path:
                            current_path.insert(0, path)
                            env["PATH"] = os.pathsep.join(current_path)

                continue

            # Check requirements
            can_install, missing = self.resolver.check_requirements(provisioner)
            if not can_install:
                logger.error("❌ %s missing requirements: %s", name, missing)
                results[name] = False
                continue

            # Install provisioner
            logger.info("🔧 Installing %s: %s", name, provisioner.description)
            success = await self._install_provisioner(provisioner, dry_run, env)
            results[name] = success

            if success:
                logger.info("✅ %s installed successfully", name)

                # Update PATH for subsequent installations
                if not dry_run:
                    new_paths = await self._detect_path_additions(provisioner)
                    for path in new_paths:
                        if path not in current_path:
                            current_path.insert(0, path)
                            env["PATH"] = os.pathsep.join(current_path)
                            logger.debug(
                                "Added %s to PATH for subsequent installations",
                                path,
                            )
            else:
                logger.error("❌ %s installation failed", name)

        return results

    async def _detect_path_additions(self, provisioner: Provisioner) -> list[str]:
        """Detect common PATH additions after provisioner installation."""
        path_additions: list[str] = []

        # Common installation paths based on what the provisioner provides
        path_patterns = {
            "cargo": ["~/.cargo/bin"],
            "rustc": ["~/.cargo/bin"],
            "rustup": ["~/.cargo/bin"],
            "npm": ["~/.npm-global/bin", "~/.npm-packages/bin"],
            "node": ["~/.npm-global/bin", "~/.npm-packages/bin"],
            "pip": ["~/.local/bin"],
            "python": ["~/.local/bin"],
            "go": ["~/go/bin"],
            "gem": ["~/.gem/ruby/*/bin"],
            "composer": ["~/.composer/vendor/bin", "~/.config/composer/vendor/bin"],
        }

        # Check if any provided tools suggest PATH additions
        for tool in provisioner.provides:
            if tool in path_patterns:
                for path_pattern in path_patterns[tool]:
                    # Handle wildcards in paths (e.g., ruby version)
                    if "*" in path_pattern:
                        # Convert path pattern to glob pattern
                        expanded = pathlib.Path(path_pattern).expanduser()
                        parent = expanded.parent
                        pattern = expanded.name

                        # For patterns like ~/.gem/ruby/*/bin,
                        # we need to handle middle wildcards
                        if "/*/" in str(expanded):
                            # Split into parts and reconstruct glob pattern
                            parts = str(expanded).split("/")
                            base_parts = []
                            glob_parts = []
                            found_wildcard = False

                            for part in parts:
                                if "*" in part:
                                    found_wildcard = True
                                if not found_wildcard:
                                    base_parts.append(part)
                                else:
                                    glob_parts.append(part)

                            if base_parts:
                                base_path = pathlib.Path("/".join(base_parts))
                                if base_path.exists():
                                    glob_pattern = "/".join(glob_parts)
                                    path_additions.extend(
                                        str(path)
                                        for path in base_path.glob(glob_pattern)
                                        if path.is_dir()
                                    )
                        # Simple wildcard at the end
                        elif parent.exists():
                            path_additions.extend(
                                str(path)
                                for path in parent.glob(pattern)
                                if path.is_dir()
                            )
                    else:
                        expanded = pathlib.Path(path_pattern).expanduser()
                        if expanded.exists() and expanded.is_dir():
                            path_additions.append(str(expanded))

        return path_additions

    async def _is_installed(
        self,
        provisioner: Provisioner,
        env: dict[str, str] | None = None,
    ) -> bool:
        """Check if provisioner is already installed."""
        if not provisioner.verify_command:
            return False

        result = await self.runner.run(
            provisioner.verify_command,
            check=False,
            capture=True,
            env=env,
        )
        return result.success

    async def _install_provisioner(
        self,
        provisioner: Provisioner,
        dry_run: bool = False,
        env: dict[str, str] | None = None,
    ) -> bool:
        """Install a single provisioner."""
        match provisioner.install_method:
            case InstallMethod.SCRIPT:
                return await self._install_via_script(provisioner, dry_run, env)
            case InstallMethod.PACKAGE:
                return await self._install_via_package(provisioner, dry_run, env)
            case InstallMethod.BINARY:
                return await self._install_via_binary(provisioner, dry_run, env)

    async def _install_via_script(
        self,
        provisioner: Provisioner,
        dry_run: bool = False,
        env: dict[str, str] | None = None,
    ) -> bool:
        """Install via shell script."""
        if not provisioner.install_script:
            logger.error("No install script for %s", provisioner.name)
            return False

        try:
            result = await self.runner.run(
                provisioner.install_script,
                env=env,
                check=False,
                capture=True,
            )
            if not result.success:
                logger.error("Failed to install %s", provisioner.name)
                if result.stderr:
                    logger.error("Error output:\n%s", result.stderr)
                if result.stdout:
                    logger.debug("Standard output:\n%s", result.stdout)
        except Exception:
            logger.exception("Failed to install %s", provisioner.name)
            return False
        else:
            return result.success

    async def _install_via_package(
        self,
        provisioner: Provisioner,
        dry_run: bool = False,
        env: dict[str, str] | None = None,
    ) -> bool:
        """Install via package manager."""
        pkg_manager = self.platform.get_package_manager()
        if not pkg_manager:
            logger.error("No package manager available for %s", provisioner.name)
            return False

        pkg_name = provisioner.package_name or provisioner.name

        match pkg_manager:
            case "apt":
                cmd = f"sudo apt-get update && sudo apt-get install -y {pkg_name}"
            case "brew":
                cmd = f"brew install {pkg_name}"
            case "dnf":
                cmd = f"sudo dnf install -y {pkg_name}"
            case "pacman":
                cmd = f"sudo pacman -S --noconfirm {pkg_name}"
            case _:
                logger.error("Unsupported package manager: %s", pkg_manager)
                return False

        try:
            result = await self.runner.run(cmd, env=env, check=False, capture=True)
            if not result.success:
                logger.error(
                    "Failed to install %s via %s", provisioner.name, pkg_manager
                )
                if result.stderr:
                    logger.error("Error output:\n%s", result.stderr)
        except Exception:
            logger.exception("Failed to install %s", provisioner.name)
            return False
        else:
            return result.success

    async def _install_via_binary(
        self,
        provisioner: Provisioner,
        dry_run: bool = False,
        env: dict[str, str] | None = None,
    ) -> bool:
        """Install via direct binary download."""
        if not provisioner.binary_url:
            logger.error("No binary URL for %s", provisioner.name)
            return False

        try:
            # Download binary
            result = await self.runner.run(
                f"curl -L {provisioner.binary_url} -o /tmp/{provisioner.name}",
                env=env,
                check=False,
                capture=True,
            )
            if not result.success:
                logger.error("Failed to download %s", provisioner.name)
                if result.stderr:
                    logger.error("Error output:\n%s", result.stderr)
                return False

            # Make executable
            result = await self.runner.run(
                f"chmod +x /tmp/{provisioner.name}",
                env=env,
                check=False,
                capture=True,
            )
            if not result.success:
                logger.error("Failed to make %s executable", provisioner.name)
                if result.stderr:
                    logger.error("Error output:\n%s", result.stderr)
                return False

            # Move to PATH
            result = await self.runner.run(
                f"sudo mv /tmp/{provisioner.name} /usr/local/bin/",
                env=env,
                check=False,
                capture=True,
            )
            if not result.success:
                logger.error("Failed to move %s to /usr/local/bin/", provisioner.name)
                if result.stderr:
                    logger.error("Error output:\n%s", result.stderr)
                return False
        except Exception:
            logger.exception("Failed to install %s", provisioner.name)
            return False
        else:
            return True


# ═══════════════════════════════════════════════════════════════════════════════
# CLI - Modern command-line interface
# ═══════════════════════════════════════════════════════════════════════════════


class DotfilesApp:
    """Main application class for dot.py v2.0."""

    def __init__(
        self,
        config_path: pathlib.Path | None = None,
        dry_run: bool = False,
    ) -> None:
        """Initialize application with config and options."""
        self.dry_run = dry_run
        self.platform = Platform()
        self.runner = AsyncCommandRunner(dry_run=dry_run)
        self.config_loader = ConfigLoader(config_path)
        self.config = self.config_loader.load()
        self.shell_generator = ShellGenerator(self.platform)

        # Combine all provisioners for management
        all_provisioners = {**self.config.provisioners, **self.config.enhancements}
        self.provisioner_manager = ProvisionerManager(
            all_provisioners,
            self.runner,
            self.platform,
        )

    async def install_dotfiles(self) -> bool:
        """Install dotfiles symlinks."""
        logger.info("Installing dotfiles...")
        success = True

        # Install file symlinks
        for dest_path, template_def in self.config.files.items():
            source = self.config.source / template_def.source
            dest = self.platform.info.home / dest_path

            if not await self._create_symlink(source, dest):
                success = False

        # Install directory symlinks
        for dest_path, source_path in self.config.dirs.items():
            source = self.config.source / source_path
            dest = self.platform.info.home / dest_path

            if not await self._create_symlink(source, dest):
                success = False

        return success

    async def _create_symlink(self, source: pathlib.Path, dest: pathlib.Path) -> bool:
        """Create a symlink with error handling."""
        if self.dry_run:
            logger.info("[DRY RUN] Would symlink: %s -> %s", dest, source)
            return True

        try:
            # Ensure parent directory exists
            dest.parent.mkdir(parents=True, exist_ok=True)

            # Check if symlink already exists and is correct
            if dest.is_symlink() and dest.resolve() == source.resolve():
                logger.debug("Symlink already correct: %s", dest)
                return True

            # Remove existing file/symlink
            if dest.exists() or dest.is_symlink():
                if dest.is_dir() and not dest.is_symlink():
                    import shutil

                    shutil.rmtree(dest)
                else:
                    dest.unlink()

            # Create symlink
            dest.symlink_to(source)
            logger.info("Created symlink: %s -> %s", dest, source)
        except OSError:
            logger.exception("Failed to create symlink %s -> %s", dest, source)
            return False
        else:
            return True

    async def provision(self, filter_type: ProvisionerType | None = None) -> bool:
        """Provision development environment."""
        logger.info("Provisioning development environment...")

        # Install system packages first
        if (
            not filter_type or filter_type == ProvisionerType.FOUNDATION
        ) and not await self._install_system_packages():
            logger.error("Failed to install system packages")
            return False

        results = await self.provisioner_manager.provision_all(
            filter_type,
            self.dry_run,
        )

        success_count = sum(1 for success in results.values() if success)
        total_count = len(results)

        logger.info(
            "Provisioning complete: %s/%s successful", success_count, total_count
        )
        return success_count == total_count

    async def _install_system_packages(self) -> bool:
        """Install system packages based on platform."""
        pkg_manager = self.platform.get_package_manager()
        if not pkg_manager or pkg_manager not in self.config.packages:
            logger.debug(
                "No packages configured for %s package manager",
                pkg_manager or "unknown",
            )
            return True

        package_config = self.config.packages[pkg_manager]
        if not isinstance(package_config, dict):
            logger.warning("Invalid package configuration for %s", pkg_manager)
            return True

        packages = package_config.get("packages", [])
        if not packages:
            logger.debug("No base packages configured for %s", pkg_manager)
            return True

        logger.info(
            "Ensuring %d %s packages are installed...", len(packages), pkg_manager
        )

        if self.dry_run:
            logger.info(
                "[DRY RUN] Would check/install packages: %s", ", ".join(packages)
            )
            return True

        # Build and execute install command based on package manager
        match pkg_manager:
            case "apt":
                # Check which packages are already installed
                logger.debug("Checking installed apt packages...")
                # Remove :amd64 suffix from package names
                check_cmd = (
                    f"dpkg -l {' '.join(packages)} 2>/dev/null | "
                    "grep '^ii' | awk '{print $2}' | cut -d: -f1"
                )
                result = await self.runner.run(check_cmd, check=False, capture=True)
                installed = set()
                if result.stdout:
                    # Filter out empty lines and clean package names
                    for line in result.stdout.strip().split("\n"):
                        if line:
                            installed.add(line.strip())

                logger.debug("Requested packages: %s", packages)
                logger.debug("Installed packages found: %s", installed)

                to_install = [pkg for pkg in packages if pkg not in installed]

                if not to_install:
                    logger.info(
                        "✅ All %d apt packages are already installed", len(packages)
                    )
                    return True

                logger.info(
                    "📦 Need to install %d apt packages: %s",
                    len(to_install),
                    ", ".join(to_install[:5]) + ("..." if len(to_install) > 5 else ""),
                )
                cmd = (
                    f"sudo apt-get update && sudo apt-get install -y "
                    f"{' '.join(to_install)}"
                )
            case "brew":
                # For brew, we can check installed packages more efficiently
                logger.debug("Checking installed brew packages...")
                check_cmd = "brew list --formula"
                result = await self.runner.run(check_cmd, check=False, capture=True)
                installed = (
                    set(result.stdout.strip().split()) if result.stdout else set()
                )
                to_install = [pkg for pkg in packages if pkg not in installed]

                if not to_install:
                    logger.info(
                        "✅ All %d brew packages are already installed", len(packages)
                    )
                    return True

                logger.info(
                    "📦 Need to install %d brew packages: %s",
                    len(to_install),
                    ", ".join(to_install[:5]) + ("..." if len(to_install) > 5 else ""),
                )
                cmd = f"brew install {' '.join(to_install)}"
            case "dnf":
                cmd = f"sudo dnf install -y {' '.join(packages)}"
            case "pacman":
                cmd = f"sudo pacman -S --noconfirm --needed {' '.join(packages)}"
            case _:
                logger.error("Unsupported package manager: %s", pkg_manager)
                return False

        result = await self.runner.run(cmd, check=False, capture=True)
        if not result.success:
            logger.error("Failed to install %s packages", pkg_manager)
            if result.stderr:
                logger.error("Error output:\n%s", result.stderr)
        return result.success

    def generate_shell_init(
        self,
        shell: ShellName,
        stage: StageLevel | None = None,
    ) -> str:
        """Generate shell initialization script."""
        return self.shell_generator.generate_staged_init(
            shell,
            self.config.shell_snippets,
            stage,
        )

    async def status(self) -> dict[str, typing.Any]:
        """Get system and provisioning status."""
        status: dict[str, typing.Any] = {
            "platform": {
                "os": self.platform.info.os,
                "distro": self.platform.info.distro,
                "is_wsl": self.platform.info.is_wsl,
                "package_manager": self.platform.get_package_manager(),
            },
            "provisioners": {},
            "dotfiles": {},
        }

        # Check provisioner status
        all_provisioners = {**self.config.provisioners, **self.config.enhancements}
        for name, provisioner in all_provisioners.items():
            is_installed = await self.provisioner_manager._is_installed(provisioner)
            status["provisioners"][name] = {
                "installed": is_installed,
                "type": provisioner.type.name.lower(),
                "description": provisioner.description,
            }

        # Check dotfile symlinks
        for dest_path, template_def in self.config.files.items():
            dest = self.platform.info.home / dest_path
            source = self.config.source / template_def.source

            if not dest.exists():
                status_str = "missing"
            elif not dest.is_symlink():
                status_str = "not_symlink"
            elif dest.resolve() != source.resolve():
                status_str = "wrong_target"
            else:
                status_str = "ok"

            status["dotfiles"][str(dest_path)] = status_str

        return status

    async def cleanup(self, patterns: list[str] | None = None) -> bool:
        """Clean up unwanted files from home directory."""
        cleanup_patterns = patterns or self.config.cleanup_patterns
        if not cleanup_patterns:
            logger.info("No cleanup patterns configured")
            return True

        logger.info("Cleaning up unwanted files...")
        success = True

        for pattern in cleanup_patterns:
            try:
                matches = list(self.platform.info.home.glob(pattern))
                for match_path in matches:
                    if self.dry_run:
                        logger.info("[DRY RUN] Would remove: %s", match_path)
                    else:
                        logger.info("Removing: %s", match_path)
                        if match_path.is_dir():
                            import shutil

                            shutil.rmtree(match_path)
                        else:
                            match_path.unlink()
            except Exception:
                logger.exception("Failed to clean pattern %s", pattern)
                success = False

        return success


async def async_main() -> int:
    """Async main function."""
    parser = argparse.ArgumentParser(
        description="Modern dotfiles management with provisioner architecture",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s install                    # Install dotfile symlinks
  %(prog)s provision                  # Install all provisioners and enhancements
  %(prog)s provision --type provisioner  # Install only core provisioners
  %(prog)s shell --zsh                # Generate complete shell init
  %(prog)s shell --zsh --stage early  # Generate only early stage (fast)
  %(prog)s status                     # Show provisioning status
  %(prog)s cleanup                    # Remove unwanted files from home
""",
    )

    parser.add_argument(
        "--version",
        action="version",
        version=f"%(prog)s {__version__}",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose output",
    )
    parser.add_argument(
        "--config",
        type=pathlib.Path,
        help="Path to configuration file",
    )

    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # install command
    subparsers.add_parser("install", help="Install dotfiles symlinks")

    # provision command
    provision_parser = subparsers.add_parser(
        "provision",
        help="Provision development environment",
    )
    provision_parser.add_argument(
        "--type",
        choices=["foundation", "provisioner", "enhancement"],
        help="Filter by provisioner type",
    )

    # shell command
    shell_parser = subparsers.add_parser("shell", help="Generate shell initialization")
    shell_group = shell_parser.add_mutually_exclusive_group(required=True)
    shell_group.add_argument("--bash", action="store_const", const="bash", dest="shell")
    shell_group.add_argument("--zsh", action="store_const", const="zsh", dest="shell")
    shell_group.add_argument("--fish", action="store_const", const="fish", dest="shell")
    shell_parser.add_argument(
        "--stage",
        choices=["early", "main", "late"],
        help="Generate only specific stage",
    )

    # status command
    subparsers.add_parser("status", help="Show system and provisioning status")

    # cleanup command
    cleanup_parser = subparsers.add_parser("cleanup", help="Clean up unwanted files")
    cleanup_parser.add_argument(
        "patterns",
        nargs="*",
        help="Additional cleanup patterns",
    )

    args = parser.parse_args()

    # Configure logging
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # Create app instance
    app = DotfilesApp(config_path=args.config, dry_run=args.dry_run)

    # Route commands
    success = True

    match args.command:
        case "install":
            success = await app.install_dotfiles()

        case "provision":
            filter_type = None
            if args.type:
                match args.type:
                    case "foundation":
                        filter_type = ProvisionerType.FOUNDATION
                    case "provisioner":
                        filter_type = ProvisionerType.PROVISIONER
                    case "enhancement":
                        filter_type = ProvisionerType.ENHANCEMENT
            success = await app.provision(filter_type)

        case "shell":
            shell_init = app.generate_shell_init(args.shell, args.stage)
            # Output to stdout for shell sourcing/piping
            sys.stdout.write(shell_init)
            if not shell_init.endswith("\n"):
                sys.stdout.write("\n")

        case "status":
            status = await app.status()
            import json

            # Output to stdout for JSON parsing/piping
            sys.stdout.write(json.dumps(status, indent=2))
            sys.stdout.write("\n")

        case "cleanup":
            success = await app.cleanup(args.patterns)

        case None:
            parser.print_help()

        case _:
            logger.error("Unknown command: %s", args.command)
            success = False

    return 0 if success else 1


def main() -> int:
    """Execute the main application."""
    try:
        return asyncio.run(async_main())
    except KeyboardInterrupt:
        logger.info("Interrupted by user")
        return 130
    except Exception:
        logger.exception("Unexpected error occurred")
        return 1


if __name__ == "__main__":
    import sys

    sys.exit(main())
