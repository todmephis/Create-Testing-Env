#!/usr/bin/env fish

# install_pt_tools.fish
# Bootstrap pentesting/dev tooling for Kali / Debian / Ubuntu.
#
# Installs:
# - apt update / upgrade
# - kali-linux-default
# - tmux, vim, chromium, default-jdk, ffuf, seclists
# - fresh Go from go.dev
# - ProjectDiscovery tools: dnsx, httpx, nuclei, katana, mapcidr, subfinder, cvemap
# - gowitness
# - np
# - nmap, masscan
# - shodan via pipx
# - sn0int via apt.vulns.sexy repo
# - ~/config
# - ~/pTools/{tools,scripts,lists}
# - ~/pTools/lists/SecLists -> /usr/share/seclists
# - persistent Fish functions:
#     times => date '+%m%d%y%H%M%S'
#     ls    => command ls -lh
#
# Notes:
# - Designed for fresh systems.
# - Go is installed fresh on every run unless --skip-go is used.
# - Supports Linux amd64, arm64, and armv6l/armv7l Go tarballs.

set -g SCRIPT_NAME (status filename)

# Flags
set -g FLAG_SKIP_GO 0
set -g FLAG_SKIP_PD 0
set -g FLAG_SKIP_GOWITNESS 0
set -g FLAG_SKIP_NP 0
set -g FLAG_SKIP_NETWORK 0
set -g FLAG_SKIP_SHODAN 0
set -g FLAG_SKIP_SN0INT 0
set -g FLAG_SKIP_CONFIG 0
set -g FLAG_SKIP_FISH_CONFIG 0
set -g FLAG_ONLY_PD 0
set -g FLAG_NON_INTERACTIVE 0
set -g FLAG_DRY_RUN 0
set -g FLAG_VERBOSE 0

# Timing
set -g TIMING_NAMES
set -g TIMING_VALUES

function log_info
    echo (set_color cyan)"[INFO]"(set_color normal) $argv
end

function log_ok
    echo (set_color green)"[OK]"(set_color normal) $argv
end

function log_warn
    echo (set_color yellow)"[WARN]"(set_color normal) $argv
end

function log_err
    echo (set_color red)"[ERR]"(set_color normal) $argv
end

function print_cmd
    echo (set_color magenta)"[CMD]"(set_color normal) (string join " " -- $argv)
end

function show_examples
    echo "Examples:"
    echo "  Dry run with command preview:"
    echo "    ./$SCRIPT_NAME --dry-run --verbose"
    echo
    echo "  Full install:"
    echo "    ./$SCRIPT_NAME --verbose"
    echo
    echo "  Full install without prompts:"
    echo "    ./$SCRIPT_NAME --non-interactive --verbose"
    echo
    echo "  Only ProjectDiscovery tools:"
    echo "    ./$SCRIPT_NAME --only-pd --verbose"
    echo
    echo "  Skip Shodan and sn0int:"
    echo "    ./$SCRIPT_NAME --skip-shodan --skip-sn0int --verbose"
    echo
    echo "  Skip network scanners:"
    echo "    ./$SCRIPT_NAME --skip-network --verbose"
end

function usage
    echo "Usage: $SCRIPT_NAME [flags]"
    echo
    echo "Flags:"
    echo "  --skip-go"
    echo "      Skip Go installation."
    echo "      Example: ./$SCRIPT_NAME --skip-go --verbose"
    echo
    echo "  --skip-pd"
    echo "      Skip ProjectDiscovery tools: dnsx, httpx, nuclei, katana, mapcidr, subfinder, cvemap."
    echo "      Example: ./$SCRIPT_NAME --skip-pd --verbose"
    echo
    echo "  --skip-gowitness"
    echo "      Skip gowitness installation."
    echo "      Example: ./$SCRIPT_NAME --skip-gowitness --verbose"
    echo
    echo "  --skip-np"
    echo "      Skip np installation."
    echo "      Example: ./$SCRIPT_NAME --skip-np --verbose"
    echo
    echo "  --skip-network"
    echo "      Skip nmap and masscan."
    echo "      Example: ./$SCRIPT_NAME --skip-network --verbose"
    echo
    echo "  --skip-shodan"
    echo "      Skip shodan CLI installation."
    echo "      Example: ./$SCRIPT_NAME --skip-shodan --verbose"
    echo
    echo "  --skip-sn0int"
    echo "      Skip sn0int installation."
    echo "      Example: ./$SCRIPT_NAME --skip-sn0int --verbose"
    echo
    echo "  --skip-config"
    echo "      Skip ~/config, ~/pTools, and SecLists link creation."
    echo "      Example: ./$SCRIPT_NAME --skip-config --verbose"
    echo
    echo "  --skip-fish-config"
    echo "      Skip persistent Fish functions (times and ls)."
    echo "      Example: ./$SCRIPT_NAME --skip-fish-config --verbose"
    echo
    echo "  --only-pd"
    echo "      Install only ProjectDiscovery tooling and supporting dependencies."
    echo "      Automatically skips gowitness, np, network tools, shodan, sn0int, and workspace config."
    echo "      Example: ./$SCRIPT_NAME --only-pd --verbose"
    echo
    echo "  --non-interactive"
    echo "      Use DEBIAN_FRONTEND=noninteractive for apt operations."
    echo "      Example: ./$SCRIPT_NAME --non-interactive --verbose"
    echo
    echo "  --dry-run"
    echo "      Print what would run, without executing commands."
    echo "      Example: ./$SCRIPT_NAME --dry-run --verbose"
    echo
    echo "  --verbose"
    echo "      Print commands before executing them."
    echo "      Example: ./$SCRIPT_NAME --verbose"
    echo
    echo "  --help, -h"
    echo "      Show this help and examples."
    echo
    show_examples
end

function add_timing
    set -ga TIMING_NAMES $argv[1]
    set -ga TIMING_VALUES $argv[2]
end

function format_duration
    set total $argv[1]
    set mins (math "floor($total / 60)")
    set secs (math "$total % 60")
    printf "%02dm:%02ds\n" $mins $secs
end

function timed_step
    set step_name $argv[1]
    set fn_name $argv[2]

    log_info "Starting step: $step_name"
    set start_ts (date +%s)

    $fn_name
    set rc $status

    set end_ts (date +%s)
    set elapsed (math "$end_ts - $start_ts")
    add_timing "$step_name" "$elapsed"

    if test $rc -eq 0
        log_ok "Finished step: $step_name in "(format_duration $elapsed)
    else
        log_err "Step failed: $step_name after "(format_duration $elapsed)
        return $rc
    end
end

function print_timing_summary
    echo
    log_info "Timing summary"
    for i in (seq (count $TIMING_NAMES))
        printf "  %-28s %s\n" $TIMING_NAMES[$i] (format_duration $TIMING_VALUES[$i])
    end
end

function parse_args
    for arg in $argv
        switch $arg
            case --skip-go
                set -g FLAG_SKIP_GO 1
            case --skip-pd
                set -g FLAG_SKIP_PD 1
            case --skip-gowitness
                set -g FLAG_SKIP_GOWITNESS 1
            case --skip-np
                set -g FLAG_SKIP_NP 1
            case --skip-network
                set -g FLAG_SKIP_NETWORK 1
            case --skip-shodan
                set -g FLAG_SKIP_SHODAN 1
            case --skip-sn0int
                set -g FLAG_SKIP_SN0INT 1
            case --skip-config
                set -g FLAG_SKIP_CONFIG 1
            case --skip-fish-config
                set -g FLAG_SKIP_FISH_CONFIG 1
            case --only-pd
                set -g FLAG_ONLY_PD 1
            case --non-interactive
                set -g FLAG_NON_INTERACTIVE 1
            case --dry-run
                set -g FLAG_DRY_RUN 1
            case --verbose
                set -g FLAG_VERBOSE 1
            case --help -h
                usage
                exit 0
            case '*'
                log_err "Unknown argument: $arg"
                echo
                usage
                exit 1
        end
    end

    if test $FLAG_ONLY_PD -eq 1
        set -g FLAG_SKIP_GOWITNESS 1
        set -g FLAG_SKIP_NP 1
        set -g FLAG_SKIP_NETWORK 1
        set -g FLAG_SKIP_SHODAN 1
        set -g FLAG_SKIP_SN0INT 1
        set -g FLAG_SKIP_CONFIG 1
    end
end

function require_linux
    if test (uname -s) != "Linux"
        log_err "This script only supports Linux."
        exit 1
    end
end

function require_apt
    if not command -v apt-get >/dev/null 2>&1
        log_err "apt-get not found. This script supports Kali/Debian/Ubuntu only."
        exit 1
    end
end

function ensure_sudo
    if test (id -u) -ne 0
        if not command -v sudo >/dev/null 2>&1
            log_err "sudo is required when not running as root."
            exit 1
        end
    end
end

function run_cmd
    if test $FLAG_VERBOSE -eq 1 -o $FLAG_DRY_RUN -eq 1
        print_cmd $argv
    end

    if test $FLAG_DRY_RUN -eq 1
        return 0
    end

    command $argv
end

function run_root_cmd
    if test (id -u) -eq 0
        if test $FLAG_VERBOSE -eq 1 -o $FLAG_DRY_RUN -eq 1
            print_cmd $argv
        end
        if test $FLAG_DRY_RUN -eq 1
            return 0
        end
        command $argv
    else
        if test $FLAG_VERBOSE -eq 1 -o $FLAG_DRY_RUN -eq 1
            print_cmd sudo $argv
        end
        if test $FLAG_DRY_RUN -eq 1
            return 0
        end
        command sudo $argv
    end
end

function apt_update_upgrade
    log_info "Updating package lists..."
    run_root_cmd apt-get update
    or begin
        log_err "apt-get update failed"
        return 1
    end

    log_info "Upgrading installed packages..."
    if test $FLAG_NON_INTERACTIVE -eq 1
        run_root_cmd env DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
    else
        run_root_cmd apt-get upgrade -y
    end
    or begin
        log_err "apt-get upgrade failed"
        return 1
    end
end

function apt_install_if_missing
    for pkg in $argv
        if dpkg -s $pkg >/dev/null 2>&1
            log_ok "$pkg already installed"
        else
            log_info "Installing $pkg..."
            if test $FLAG_NON_INTERACTIVE -eq 1
                run_root_cmd env DEBIAN_FRONTEND=noninteractive apt-get install -y $pkg
            else
                run_root_cmd apt-get install -y $pkg
            end
            or begin
                log_err "Failed to install $pkg"
                return 1
            end
        end
    end
end

function ensure_core_packages
    if test $FLAG_ONLY_PD -eq 1
        apt_install_if_missing \
            ca-certificates \
            curl \
            tar \
            gzip \
            python3 \
            python3-pip \
            python3-venv \
            pipx \
            git \
            tmux \
            vim
    else
        apt_install_if_missing \
            kali-linux-default \
            ca-certificates \
            curl \
            tar \
            gzip \
            python3 \
            python3-pip \
            python3-venv \
            pipx \
            git \
            tmux \
            vim \
            chromium \
            default-jdk \
            seclists \
            ffuf
    end
end

function ensure_network_packages
    if test $FLAG_SKIP_NETWORK -eq 1
        log_warn "Skipping nmap and masscan"
        return 0
    end

    apt_install_if_missing nmap masscan
end

function fish_add_path_once_safe
    for p in $argv
        if test -d $p
            if not contains -- $p $fish_user_paths
                if test $FLAG_DRY_RUN -eq 1
                    print_cmd fish_add_path -g $p
                else
                    fish_add_path -g $p
                end
                log_ok "Added to Fish PATH: $p"
            else
                log_ok "Already in Fish PATH: $p"
            end
        end
    end
end

function ensure_path_now
    for p in $argv
        if test -d $p
            if not contains -- $p $PATH
                set -gx PATH $p $PATH
            end
        end
    end
end

function detect_go_arch
    set machine (uname -m)

    switch $machine
        case x86_64 amd64
            echo "amd64"
            return 0
        case aarch64 arm64
            echo "arm64"
            return 0
        case armv7l armv7 armhf
            echo "armv6l"
            return 0
        case armv6l
            echo "armv6l"
            return 0
        case '*'
            return 1
    end
end

function ensure_standard_paths
    if test $FLAG_DRY_RUN -eq 0
        mkdir -p $HOME/go/bin
    else
        print_cmd mkdir -p $HOME/go/bin
    end

    fish_add_path_once_safe /usr/local/go/bin $HOME/go/bin $HOME/.local/bin
    ensure_path_now /usr/local/go/bin $HOME/go/bin $HOME/.local/bin
end

function install_go_latest
    if test $FLAG_SKIP_GO -eq 1
        log_warn "Skipping Go installation"
        ensure_standard_paths
        return 0
    end

    set go_arch (detect_go_arch)
    if test $status -ne 0 -o -z "$go_arch"
        log_err "Unsupported architecture for Go installer: "(uname -m)
        return 1
    end

    log_info "Fetching latest Go release metadata..."
    set json_url "https://go.dev/dl/?include=stable&mode=json"
    set go_meta (curl -fsSL $json_url)
    if test $status -ne 0
        log_err "Failed to fetch Go release metadata"
        return 1
    end

    set go_file (printf '%s\n' "$go_meta" | env GOARCH_TARGET="$go_arch" python3 -c '
import json, os, sys
arch = os.environ["GOARCH_TARGET"]
data = json.load(sys.stdin)
for rel in data:
    for f in rel.get("files", []):
        if f.get("os") == "linux" and f.get("arch") == arch and f.get("kind") == "archive":
            print(f["filename"])
            raise SystemExit(0)
raise SystemExit(1)
')

    if test $status -ne 0 -o -z "$go_file"
        log_err "Could not determine latest Go linux-$go_arch archive"
        return 1
    end

    set go_url "https://go.dev/dl/$go_file"
    set tmp_file "/tmp/$go_file"

    log_info "Downloading $go_url ..."
    run_cmd curl -fL $go_url -o $tmp_file
    or begin
        log_err "Failed to download Go archive"
        return 1
    end

    log_info "Installing fresh Go to /usr/local/go ..."
    run_root_cmd rm -rf /usr/local/go
    or begin
        log_err "Failed to remove old /usr/local/go"
        return 1
    end

    run_root_cmd tar -C /usr/local -xzf $tmp_file
    or begin
        log_err "Failed to extract Go archive"
        return 1
    end

    if test $FLAG_DRY_RUN -eq 0
        rm -f $tmp_file
    else
        print_cmd rm -f $tmp_file
    end

    ensure_standard_paths

    if test $FLAG_DRY_RUN -eq 1
        log_ok "Dry run complete for Go install"
        return 0
    end

    if command -v go >/dev/null 2>&1
        log_ok "Installed Go: "(go version)
    else
        log_warn "Go installed, but you may need to restart Fish or source your Fish config"
    end
end

function go_install_tool
    set module $argv[1]
    set bin_name $argv[2]

    if test $FLAG_DRY_RUN -eq 1
        log_info "Would install $bin_name via go install ($module)"
        print_cmd go install -v $module
        return 0
    end

    if command -v $bin_name >/dev/null 2>&1
        log_ok "$bin_name already installed"
        return 0
    end

    if not command -v go >/dev/null 2>&1
        log_err "go is not available, cannot install $bin_name"
        return 1
    end

    log_info "Installing $bin_name via go install ($module)"
    run_cmd go install -v $module
    or begin
        log_err "Failed to install $bin_name"
        return 1
    end

    if command -v $bin_name >/dev/null 2>&1
        log_ok "Installed $bin_name"
    else
        log_warn "$bin_name installed but not visible yet; PATH may need refresh"
    end
end

function install_projectdiscovery_tools
    if test $FLAG_SKIP_PD -eq 1
        log_warn "Skipping ProjectDiscovery tools"
        return 0
    end

    ensure_standard_paths

    set modules \
        github.com/projectdiscovery/dnsx/cmd/dnsx@latest dnsx \
        github.com/projectdiscovery/httpx/cmd/httpx@latest httpx \
        github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest nuclei \
        github.com/projectdiscovery/katana/cmd/katana@latest katana \
        github.com/projectdiscovery/mapcidr/cmd/mapcidr@latest mapcidr \
        github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest subfinder \
        github.com/projectdiscovery/cvemap/cmd/cvemap@latest cvemap

    for i in (seq 1 2 (count $modules))
        set module $modules[$i]
        set bin_name $modules[(math $i + 1)]
        go_install_tool $module $bin_name
        or return 1
    end
end

function install_gowitness
    if test $FLAG_SKIP_GOWITNESS -eq 1
        log_warn "Skipping GoWitness"
        return 0
    end

    ensure_standard_paths
    go_install_tool github.com/sensepost/gowitness@latest gowitness
end

function install_np
    if test $FLAG_SKIP_NP -eq 1
        log_warn "Skipping np"
        return 0
    end

    ensure_standard_paths
    go_install_tool github.com/leesoh/np/cmd/np@latest np
end

function install_shodancli
    if test $FLAG_SKIP_SHODAN -eq 1
        log_warn "Skipping shodan CLI"
        return 0
    end

    if not command -v pipx >/dev/null 2>&1
        log_info "Installing pipx..."
        apt_install_if_missing pipx python3-venv
        or begin
            log_err "Failed to install pipx"
            return 1
        end
    end

    if test $FLAG_DRY_RUN -eq 1
        log_info "Would ensure shodan CLI is installed/upgraded via pipx"
        print_cmd pipx list
        print_cmd pipx install shodan
        print_cmd pipx upgrade shodan
        return 0
    end

    set pipx_has_shodan 0
    pipx list 2>/dev/null | string match -rq 'package shodan '
    and set pipx_has_shodan 1

    if test $pipx_has_shodan -eq 1
        log_info "Upgrading shodan CLI with pipx"
        run_cmd pipx upgrade shodan
        or log_warn "pipx upgrade shodan failed; existing install may still be usable"
    else
        log_info "Installing shodan CLI with pipx"
        run_cmd pipx install shodan
        or begin
            log_err "Failed to install shodan with pipx"
            return 1
        end
    end

    fish_add_path_once_safe $HOME/.local/bin
    ensure_path_now $HOME/.local/bin

    if command -v shodan >/dev/null 2>&1
        log_ok "Installed shodan CLI"
    else
        log_warn "shodan installed but not visible yet; PATH may need refresh"
    end
end

function install_sn0int
    if test $FLAG_SKIP_SN0INT -eq 1
        log_warn "Skipping sn0int"
        return 0
    end

    if command -v sn0int >/dev/null 2>&1
        log_ok "sn0int already installed"
        return 0
    end

    log_info "Installing sn0int repository prerequisites..."
    apt_install_if_missing curl gnupg
    or begin
        log_err "Failed to install prerequisites"
        return 1
    end

    set repo_file "/etc/apt/sources.list.d/apt-vulns-sexy.list"
    set key_file "/etc/apt/trusted.gpg.d/apt-vulns-sexy.gpg"

    log_info "Installing sn0int repository key..."
    if test $FLAG_DRY_RUN -eq 1
        print_cmd "curl -fsSL https://apt.vulns.sexy/kpcyrd.pgp | sudo gpg --dearmor -o $key_file"
    else
        curl -fsSL https://apt.vulns.sexy/kpcyrd.pgp | sudo gpg --dearmor -o $key_file
        or begin
            log_err "Failed to install repository key"
            return 1
        end
    end

    log_info "Adding sn0int repository..."
    if test $FLAG_DRY_RUN -eq 1
        print_cmd "echo 'deb http://apt.vulns.sexy stable main' | sudo tee $repo_file"
    else
        echo 'deb http://apt.vulns.sexy stable main' | sudo tee $repo_file > /dev/null
        or begin
            log_err "Failed to add repository"
            return 1
        end
    end

    log_info "Updating package lists..."
    run_root_cmd apt-get update
    or begin
        log_err "apt-get update failed"
        return 1
    end

    log_info "Installing sn0int..."
    if test $FLAG_NON_INTERACTIVE -eq 1
        run_root_cmd env DEBIAN_FRONTEND=noninteractive apt-get install -y sn0int
    else
        run_root_cmd apt-get install -y sn0int
    end
    or begin
        log_err "Failed to install sn0int"
        return 1
    end

    if command -v sn0int >/dev/null 2>&1
        log_ok "Installed sn0int"
    else
        log_warn "sn0int install completed but binary not found in current PATH"
    end
end

function create_workspace_dirs
    if test $FLAG_SKIP_CONFIG -eq 1
        log_warn "Skipping ~/config and ~/pTools creation"
        return 0
    end

    set cfg "$HOME/config"
    set ptools "$HOME/pTools"
    set ptools_tools "$HOME/pTools/tools"
    set ptools_scripts "$HOME/pTools/scripts"
    set ptools_lists "$HOME/pTools/lists"
    set seclists_link "$HOME/pTools/lists/SecLists"
    set seclists_target "/usr/share/seclists"

    for dir in $cfg $ptools $ptools_tools $ptools_scripts $ptools_lists
        if test -d $dir
            log_ok "Directory already exists: $dir"
        else
            if test $FLAG_DRY_RUN -eq 1
                print_cmd mkdir -p $dir
            else
                mkdir -p $dir
            end
            log_ok "Created directory: $dir"
        end
    end

    if test -L $seclists_link
        set current_target (readlink $seclists_link)
        if test "$current_target" = "$seclists_target"
            log_ok "SecLists symlink already exists: $seclists_link -> $seclists_target"
        else
            if test $FLAG_DRY_RUN -eq 1
                print_cmd rm -f $seclists_link
                print_cmd ln -s $seclists_target $seclists_link
            else
                rm -f $seclists_link
                ln -s $seclists_target $seclists_link
            end
            log_ok "Updated SecLists symlink: $seclists_link -> $seclists_target"
        end
    else if test -e $seclists_link
        log_warn "$seclists_link exists and is not a symlink; leaving it unchanged"
    else
        if test -d $seclists_target
            if test $FLAG_DRY_RUN -eq 1
                print_cmd ln -s $seclists_target $seclists_link
            else
                ln -s $seclists_target $seclists_link
            end
            log_ok "Created SecLists symlink: $seclists_link -> $seclists_target"
        else
            log_warn "SecLists target does not exist yet: $seclists_target"
        end
    end
end

function install_fish_functions
    if test $FLAG_SKIP_FISH_CONFIG -eq 1
        log_warn "Skipping persistent Fish functions"
        return 0
    end

    log_info "Installing persistent Fish functions"

    set fn_dir "$HOME/.config/fish/functions"

    if test $FLAG_DRY_RUN -eq 1
        print_cmd mkdir -p $fn_dir
        print_cmd funcsave times
        print_cmd funcsave ls
        return 0
    end

    mkdir -p $fn_dir

    function times
        date '+%m%d%y%H%M%S'
    end
    funcsave times

    function ls
        command ls -lh $argv
    end
    funcsave ls

    log_ok "Saved Fish function: times"
    log_ok "Saved Fish function: ls"
end

function print_summary
    echo
    log_info "Summary"
    echo "  dry-run:           $FLAG_DRY_RUN"
    echo "  verbose:           $FLAG_VERBOSE"
    echo "  non-interactive:   $FLAG_NON_INTERACTIVE"
    echo

    if test $FLAG_ONLY_PD -eq 0
        if dpkg -s kali-linux-default >/dev/null 2>&1
            echo "  [OK] kali-linux-default package installed"
        else
            echo "  [--] kali-linux-default package not installed"
        end
        echo
    end

    for cmd in chromium vim java javac tmux go ffuf dnsx httpx nuclei katana mapcidr subfinder cvemap gowitness np sn0int masscan nmap shodan
        if command -v $cmd >/dev/null 2>&1
            echo "  [OK] $cmd -> "(command -s $cmd)
        else
            echo "  [--] $cmd not found in current PATH"
        end
    end

    echo
    echo "  config dir: $HOME/config"
    echo "  workspace dir: $HOME/pTools"
    echo "  tools dir: $HOME/pTools/tools"
    echo "  scripts dir: $HOME/pTools/scripts"
    echo "  lists dir: $HOME/pTools/lists"
    echo "  SecLists link: $HOME/pTools/lists/SecLists"
    echo "  fish function dir: $HOME/.config/fish/functions"
end

function main
    parse_args $argv

    set total_start (date +%s)

    require_linux
    require_apt
    ensure_sudo

    timed_step "apt update/upgrade" apt_update_upgrade; or exit 1
    timed_step "core packages" ensure_core_packages; or exit 1
    timed_step "network packages" ensure_network_packages; or exit 1
    timed_step "go install" install_go_latest; or exit 1
    timed_step "projectdiscovery tools" install_projectdiscovery_tools; or exit 1
    timed_step "gowitness" install_gowitness; or exit 1
    timed_step "np" install_np; or exit 1
    timed_step "shodan" install_shodancli; or exit 1
    timed_step "sn0int" install_sn0int; or exit 1
    timed_step "workspace dirs" create_workspace_dirs; or exit 1
    timed_step "fish functions" install_fish_functions; or exit 1

    set total_end (date +%s)
    set total_elapsed (math "$total_end - $total_start")
    add_timing "total runtime" "$total_elapsed"

    print_summary
    print_timing_summary

    echo
    show_examples

    log_ok "Done."
end

main $argv