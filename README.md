# Red Hat Development Container

Persistent Fedora 43 container for Red Hat virtualization development work (libvirt, libguestfs, virt-v2v, nbdkit, libnbd, hivex, etc.).

## Setup

1. **Build the container** (first time only):
   ```bash
   chmod +x *.sh
   ./build.sh
   ```

2. **Start the container**:
   ```bash
   ./start.sh
   ```
   - Creates container on first run
   - Starts existing container on subsequent runs
   - Automatically attaches to shell

   **If you have high UID (>100000) and get namespace errors:**
   ```bash
   chmod +x start-root.sh
   ./start-root.sh    # Uses root podman, no namespace issues
   ```

3. **Stop the container** (preserves state):
   ```bash
   ./stop.sh
   ```

4. **Remove the container** (keeps volume):
   ```bash
   ./remove.sh
   ```

## What's Persistent

- **Your workspace**: `/home/sparimi/workspace` is mounted at `/workspace` in the container
- **Container home**: Uses named volume `redhat-dev-home` for `/home/<your-username>`
  - Brew configs, shell history, vim settings, etc. persist between restarts
- **Git config**: Your `~/.gitconfig` is mounted (read-only)
- **SSH keys**: Your `~/.ssh` is mounted (read-only) for git operations
- **VDDK (optional)**: If `~/vmware-vix-disklib` exists on host, automatically mounted at `/opt/vmware-vix-disklib` (read-only)

## User ID Matching

The container user is created with **your username** from the host:
- **High UIDs (>100000)**: Container uses UID 1000, podman maps to your host UID automatically (`--userns=keep-id`)
- **Normal UIDs (<100000)**: Container uses your exact host UID/GID
- Files created in `/workspace` will have correct ownership on the host
- No permission conflicts between host and container
- Your username inside container matches your host username
- Build args are automatically detected from `id -u`, `id -g`, `id -un`

**Note:** Enterprise environments (LDAP/Active Directory) often use high UIDs (>1000000). The container automatically handles this with user namespace mapping.

## Installed Tools

### Development Infrastructure
- **Brew/Koji**: `koji` (always), `brewkoji` (Red Hat internal only)
- **Package tools**: `fedpkg` (always), `rhpkg` (Red Hat internal only), `rpm-build`, `mock`
- **Build tools**: autotools, gcc, make, OCaml (with libguestfs generator support)
- **Debugging tools**: gdb, valgrind, strace, ltrace, perf, systemtap
- **Utilities**: git, vim, tmux, git-send-email
- **Kerberos**: `kinit` for Red Hat authentication
- **Network tools**: iproute, iputils, net-tools, tcpdump, bind-utils, traceroute, ncat, telnet

**Note:** `brewkoji` and `rhpkg` require Red Hat's internal repositories. If you're not on Red Hat's network, the build will skip these packages and you can use `koji` and `fedpkg` instead for similar functionality.

### Virtualization Stack
- **libguestfs**: Library + tools for VM disk image access/modification
- **virt-v2v**: VM conversion tool (installed as runtime)
- **nbdkit**: NBD server with plugin architecture
- **libnbd**: NBD client library
- **hivex**: Windows Registry hive library
- **libvirt**: Virtualization API (installed as runtime)
- **QEMU/KVM**: For libguestfs appliance
- **supermin**: Appliance builder

### Build Dependencies
All development headers and dependencies for building from source:
- OCaml packages (gettext, fileutils, libvirt, augeas, hivex bindings)
- Filesystem tools (e2fsprogs, xfsprogs, btrfs-progs, ntfs-3g)
- Disk utilities (LVM, mdadm, cryptsetup, parted)
- Language bindings (Perl, Python, Ruby, Lua, Tcl)
- Libraries (augeas, libxml2, readline, gnutls, libcurl)

## First Time Setup (Inside Container)

### 1. Configure Kerberos (for Brew access)
```bash
# Get a Kerberos ticket
kinit your.username@REDHAT.COM

# Verify
klist
```

### 2. Test Brew access (Red Hat internal only)
```bash
# If you have brewkoji installed (Red Hat employees on internal network)
brew hello
brew list-builds --package=libvirt --type=rpm | head

# Otherwise, use koji for Fedora builds
koji list-builds --package=libvirt --type=rpm | head
```

### 3. Clone dist-git repos
```bash
cd /workspace

# Red Hat internal (if rhpkg is installed)
rhpkg clone libvirt
rhpkg clone virt-v2v
rhpkg clone libguestfs
rhpkg clone nbdkit
rhpkg clone libnbd
rhpkg clone hivex

# Or use Fedora dist-git (if using fedpkg)
fedpkg clone libvirt
fedpkg clone virt-v2v
# etc.
```

## Common Workflows

### Brew/Koji Scratch Build

**Red Hat internal (with rhpkg/brewkoji):**
```bash
# From dist-git
cd /workspace/libvirt
rhpkg switch-branch rhel-9.5.0
rhpkg scratch-build --srpm

# Or manually with brew
brew build --scratch rhel-9.5-candidate /path/to/package.src.rpm
```

**Fedora (with fedpkg/koji):**
```bash
# From dist-git
cd /workspace/libvirt
fedpkg switch-branch rawhide
fedpkg scratch-build --srpm

# Or manually with koji
koji build --scratch rawhide /path/to/package.src.rpm
```

### Building from Source

**libguestfs (requires generator step):**
```bash
cd /workspace/libguestfs
git submodule update --init  # For common/ submodule
autoreconf -i
./configure
make -C generator            # CRITICAL: Generate code first
make
./run guestfish              # Test without installing
make check
make check-valgrind          # Run tests under valgrind
```

**virt-v2v:**
```bash
cd /workspace/virt-v2v
git submodule update --init
autoreconf -i
./configure
make
./run virt-v2v --help
```

**nbdkit:**
```bash
cd /workspace/nbdkit
autoreconf -i
./configure
make
./nbdkit memory 1G -f -v     # Test: run in foreground
make check
```

**libnbd:**
```bash
cd /workspace/libnbd
autoreconf -i
./configure
make
./run nbdsh                  # Interactive NBD shell
make check
```

**hivex:**
```bash
cd /workspace/hivex
autoreconf -i
./configure
make
./run hivexsh               # Windows registry shell
make check
```

**libvirt:**
```bash
cd /workspace/libvirt
meson setup build
ninja -C build
sudo ninja -C build install  # Or use run wrapper if available
ninja -C build test
```

### Git Send-Email
```bash
# Already configured for Red Hat internal relay (no auth needed)
git send-email --to=libvir-list@redhat.com patches/*.patch

# For libguestfs/nbdkit projects
git send-email --to=libguestfs@redhat.com patches/*.patch
```

### Testing with ./run Scripts
Most projects provide a `./run` script to test without installing:
```bash
cd /workspace/libguestfs
./run guestfish -a /path/to/disk.img

cd /workspace/nbdkit
./run nbdkit memory 1G

cd /workspace/libnbd
./run nbdsh -c 'print(h.get_version())'

cd /workspace/virt-v2v
./run virt-v2v --help
```

## Shell Aliases

Container includes helpful aliases for safety and convenience:
- **Safety**: `rm -i`, `cp -i`, `mv -i` (prompts before overwriting/deleting)
- **Listing**: `ll` (ls -lah)
- **Git shortcuts**: `gits` (git status), `gitb` (git status)

## Tips

- **Multiple terminals**: Run `./start.sh` in multiple terminals to get multiple shells in the same container
- **Kerberos tickets**: Run `kinit` when ticket expires (usually 24h)
- **Volume cleanup**: To completely reset, run `podman volume rm redhat-dev-home`
- **Rebuilding**: If you update the Dockerfile, remove the old container first with `./remove.sh` then rebuild
- **libguestfs generator**: Always run `make -C generator` first when building libguestfs
- **Git submodules**: Many projects use `common/` submodule - run `git submodule update --init`
- **Debug output**: Use `LIBGUESTFS_DEBUG=1` or `LIBNBD_DEBUG=1` for verbose logging
- **VDDK**: Place VMware VDDK at `~/vmware-vix-disklib` - it will auto-mount when starting container
- **Debugging**: Use `gdb`, `valgrind`, `strace` for debugging - projects support `make check-valgrind`
- **Core dumps**: Enable with `ulimit -c unlimited` before running programs

## Troubleshooting

**Container won't start:**
```bash
podman ps -a  # Check container status
podman logs redhat-dev  # Check logs
```

**Permission issues:**
```bash
# Inside container, you have sudo access
sudo dnf install something

# If you get UID mismatch errors, rebuild the container
# (this can happen if you built on a different machine)
./remove.sh
./build.sh
./start.sh
```

**High UID issues (>100000):**
```bash
# If you get "crun: setgroups: Invalid argument" or namespace errors:

# Option 1: Configure subuid/subgid (permanent fix)
sudo usermod --add-subuids 1000-165536 $(whoami)
sudo usermod --add-subgids 1000-165536 $(whoami)
# Logout/login, then: ./start.sh

# Option 2: Use root podman (quick workaround)
chmod +x start-root.sh
./start-root.sh

# Verify after starting container:
id
# Shows: uid=1000(sparimi) inside container

# On host, files still have your ownership:
ls -l ~/workspace/
# Shows: your-uid:your-gid (4243080:4243080)
```

**Kerberos issues:**
```bash
# Renew ticket
kinit -R

# Get new ticket (Red Hat internal)
kinit your.username@REDHAT.COM

# For Fedora koji
kinit your.username@FEDORAPROJECT.ORG
```

**Missing brewkoji or rhpkg:**
```bash
# These are Red Hat internal tools
# If you see "brewkoji/rhpkg not available" during build, that's expected
# Use alternatives:
#   brewkoji → koji (for Fedora builds)
#   rhpkg → fedpkg (for Fedora dist-git)

# To manually install Red Hat internal tools (requires Red Hat network):
sudo dnf install brewkoji rhpkg
```

**libguestfs appliance issues:**
```bash
# Check if appliance can be built
libguestfs-test-tool

# Set appliance path (if needed)
export LIBGUESTFS_PATH=/usr/local/lib/guestfs/appliance
```

**Missing OCaml dependencies:**
```bash
# Install additional OCaml packages if needed
sudo dnf install ocaml-<package>-devel
```

**Network diagnostics:**
```bash
# Modern tools (iproute)
ip addr show
ip route
ss -tulpn

# Legacy tools
ifconfig
netstat -tulpn

# Diagnostics
ping -c 4 redhat.com
dig redhat.com
traceroute redhat.com
sudo tcpdump -i any  # Requires sudo

# Connection testing
nc -zv hostname 443
```

**Debugging with gdb:**
```bash
# Debug a program
cd /workspace/nbdkit
gdb --args ./nbdkit memory 1G

# Attach to running process
gdb -p <pid>

# Debug with core dump
gdb ./nbdkit core.12345
```

**Memory debugging with valgrind:**
```bash
# Check for memory leaks
cd /workspace/libguestfs
make check-valgrind

# Or manually
valgrind --leak-check=full ./run guestfish --version

# For nbdkit
valgrind --leak-check=full ./nbdkit memory 1G
```

**System call tracing:**
```bash
# Trace system calls
strace ./run guestfish --version

# Trace library calls
ltrace ./nbdkit memory 1G

# Follow child processes
strace -f ./run virt-v2v --help
```

**Performance profiling:**
```bash
# Record performance data
perf record ./nbdkit memory 1G
perf report

# Monitor live
perf top
```

**VDDK not found:**
```bash
# Download VDDK and place on host
tar xzf VMware-vix-disklib-*.tar.gz
mv vmware-vix-disklib-distrib ~/vmware-vix-disklib

# Recreate container to mount VDDK
./remove.sh
./start.sh

# Inside container - verify VDDK
ls /opt/vmware-vix-disklib
./configure --with-vddk=/opt/vmware-vix-disklib
```

## Project-Specific Notes

### libguestfs
- Generator in `generator/` must be run before building
- Uses supermin to build appliance (cached in `/var/tmp/.guestfs-<UID>/`)
- Requires OCaml for generator (not just for bindings)
- Test with `./run guestfish` before `make check`

### nbdkit
- Plugin architecture - each plugin is separate shared library
- Test plugins: `./nbdkit --dump-plugin <plugin-name>`
- Run in foreground with `-f`, verbose with `-v`
- **VDDK plugin**: Requires VMware VDDK SDK
  - Download from VMware: https://developer.vmware.com/web/sdk/8.0/vddk
  - Extract to `~/vmware-vix-disklib` on host
  - Restart container (./remove.sh && ./start.sh) to mount VDDK
  - Build with: `./configure --with-vddk=/opt/vmware-vix-disklib`

### libnbd
- Python bindings autogenerated from generator/
- `nbdsh` is interactive Python NBD shell
- Can test against nbdkit: `nbdkit memory 1G & ./run nbdsh`

### virt-v2v
- Depends on libguestfs, nbdkit, libnbd
- Requires running libvirt daemon for some conversions
- Test conversions: use `-o local -os /tmp/output` for local testing

### hivex
- Reads Windows Registry hive files
- `hivexsh` is interactive shell for exploring registry
- Perl/Python bindings available
