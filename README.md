# install_pt_tools.fish

Bootstrap script for Kali / Debian / Ubuntu to install pentesting tooling, development environment, and workspace structure.

## Usage

```bash
./install_pt_tools.fish [flags]
```

## Flags

### Core behavior

- `--skip-go`  
  Skip Go installation.

- `--skip-pd`  
  Skip ProjectDiscovery tools:
  - dnsx
  - httpx
  - nuclei
  - katana
  - mapcidr
  - subfinder
  - cvemap

- `--skip-gowitness`  
  Skip GoWitness installation.

- `--skip-np`  
  Skip np installation.

- `--skip-network`  
  Skip installing:
  - nmap
  - masscan

- `--skip-shodan`  
  Skip Shodan CLI installation.

- `--skip-sn0int`  
  Skip sn0int installation.

### Config / environment

- `--skip-config`  
  Skip creation of:
  - `~/config`
  - `~/pTools/tools`
  - `~/pTools/scripts`
  - `~/pTools/lists`
  - SecLists symlink

- `--skip-fish-config`  
  Skip persistent Fish functions:
  - `times`
  - `ls`

### Modes

- `--only-pd`  
  Install only ProjectDiscovery tools + Go.

  Automatically skips:
  - GoWitness
  - np
  - network tools
  - shodan
  - sn0int
  - workspace config

- `--non-interactive`  
  Run apt without prompts:

  ```text
  DEBIAN_FRONTEND=noninteractive
  ```

### Debug / control

- `--dry-run`  
  Print commands without executing them.

- `--verbose`  
  Print commands before execution.

- `--help`, `-h`  
  Show usage and examples.

## Examples

### 1. Dry run (recommended first)

```bash
./install_pt_tools.fish --dry-run --verbose
```

### 2. Full install

```bash
./install_pt_tools.fish --verbose
```

### 3. Full install (non-interactive / CI / EC2)

```bash
./install_pt_tools.fish --non-interactive --verbose
```

### 4. Only ProjectDiscovery tools

```bash
./install_pt_tools.fish --only-pd --verbose
```

### 5. Skip heavy or optional tools

```bash
./install_pt_tools.fish --skip-shodan --skip-sn0int --verbose
```

### 6. Minimal network footprint

```bash
./install_pt_tools.fish --skip-network --verbose
```

### 7. Skip local config setup

```bash
./install_pt_tools.fish --skip-config --skip-fish-config --verbose
```

## What gets installed

### System packages

- kali-linux-default
- tmux
- vim
- chromium
- default-jdk
- ffuf
- seclists
- nmap
- masscan

### Go tooling

- dnsx
- httpx
- nuclei
- katana
- mapcidr
- subfinder
- cvemap
- gowitness
- np

### Other tools

- shodan (via pipx)
- sn0int (via apt repo)

## Workspace structure

```text
~/config

~/pTools/
├── tools/
├── scripts/
└── lists/
    └── SecLists -> /usr/share/seclists
```

## Fish functions installed

```fish
times => date '+%m%d%y%H%M%S'
ls    => command ls -lh
```

## Post-install step

Initialize Shodan:

```bash
shodan init YOUR_API_KEY
```

## Notes

- Designed for fresh systems (for example, EC2 and fresh Kali installs)
- Go is always installed fresh from official binaries
- Handles ARM and AMD64 architectures
- Safe to re-run where practical
- Includes per-step timing statistics at the end

## Download

- Script: `install_pt_tools.fish`
- Documentation: `README.md`
