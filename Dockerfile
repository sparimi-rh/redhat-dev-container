FROM fedora:43

# Install Red Hat development tools
# RUN dnf install -y \
RUN echo "ip_resolve=4" >> /etc/dnf/dnf.conf && dnf install -y \
    # Brew/Koji tools (koji and fedpkg are in standard repos)
    koji fedpkg \
    # Build tools
    rpm-build rpmdevtools mock \
    # Development essentials
    git vim tmux bash-completion \
    # Kerberos for authentication
    krb5-workstation \
    # Useful utilities
    wget curl jq tree \
    # Network diagnostic tools
    iproute iputils net-tools tcpdump \
    bind-utils traceroute nmap-ncat telnet \
    # Debugging and profiling tools
    gdb valgrind strace ltrace \
    perf gdb-gdbserver systemtap \
    # Autotools for building from source
    autoconf automake libtool make gcc gcc-c++ \
    gperf \
    # Git send-email
    git-email \
    && dnf clean all

# Install Red Hat internal tools if repos are available (brewkoji, rhpkg)
# These require Red Hat internal network/repos - will fail gracefully if not available
RUN dnf install -y brewkoji rhpkg 2>/dev/null || echo "Red Hat internal tools (brewkoji, rhpkg) not available - skip if not on Red Hat network"

# Install OCaml and dependencies for libguestfs generator
RUN dnf install -y \
    ocaml ocaml-findlib ocaml-compiler-libs \
    ocaml-gettext-devel ocaml-ounit-devel \
    ocaml-fileutils-devel ocaml-libvirt-devel \
    ocaml-augeas-devel ocaml-hivex-devel \
    && dnf clean all

# Install libguestfs build dependencies
RUN dnf install -y \
    # Core runtime
    qemu-kvm supermin \
    # Filesystem tools
    e2fsprogs xfsprogs btrfs-progs ntfs-3g dosfstools \
    # LVM and disk tools
    lvm2 mdadm cryptsetup parted gdisk \
    # Libraries and development headers
    augeas-devel libvirt-devel hivex-devel \
    libxml2-devel readline-devel \
    pcre2-devel libconfig-devel \
    jansson-devel libcap-devel \
    ncurses-devel libtool-ltdl-devel \
    # Perl for legacy bindings
    perl-devel perl-Test-Simple perl-Module-Build \
    perl-libintl-perl perl-Sys-Virt perl-hivex \
    # Python development
    python3-devel python3-libvirt python3-libxml2 \
    # Other utilities
    file-devel genisoimage icoutils \
    libosinfo virt-install \
    && dnf clean all

# Install nbdkit build dependencies
RUN dnf install -y \
    # Core libraries
    gnutls-devel libcurl-devel \
    zlib-devel xz-devel libzstd-devel lz4-devel \
    libssh-devel \
    # Plugin dependencies
    lua-devel ruby-devel tcl-devel \
    && dnf clean all

# Install libnbd build dependencies
RUN dnf install -y \
    libxml2-devel glib2-devel \
    bash-completion \
    && dnf clean all

# Install virt-v2v specific dependencies
RUN dnf install -y \
    libguestfs libguestfs-tools \
    libguestfs-devel \
    nbdkit \
    libnbd \
    libnbd-devel \
    libosinfo \
    libosinfo-devel \
    ocaml-libnbd-devel \
    edk2-ovmf \
    perl-IPC-Run3 \
    && dnf clean all

# Install optional nbdkit plugins (may not be available in all repos)
RUN dnf install -y nbdkit-plugin-vddk 2>/dev/null || echo "nbdkit-plugin-vddk not available - VDDK plugin must be built from source"

# Install documentation tools
RUN dnf install -y \
    po4a gettext-devel \
    pod2man pod2html \
    && dnf clean all

# Install XDR, json-c
RUN dnf install -y \
    libtirpc-devel rpcgen \
    json-c-devel \
    && dnf clean all

# Create workspace directory
RUN mkdir -p /workspace

# Accept build arguments for user/group IDs and username
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USERNAME=developer

# Expand UID/GID range for enterprise environments (LDAP/AD)
RUN sed -i 's/^UID_MAX.*/UID_MAX 100000000/' /etc/login.defs && \
    sed -i 's/^GID_MAX.*/GID_MAX 100000000/' /etc/login.defs && \
    sed -i 's/^UID_MIN.*/UID_MIN 1000/' /etc/login.defs && \
    sed -i 's/^GID_MIN.*/GID_MIN 1000/' /etc/login.defs

# Create group and user with matching IDs from host
# Note: High UIDs (>60000) may cause "Invalid argument" warnings during build - these are harmless
RUN set -x && \
    (groupadd -g ${GROUP_ID} ${USERNAME} 2>/dev/null || \
     groupmod -n ${USERNAME} $(getent group ${GROUP_ID} | cut -d: -f1) 2>/dev/null || \
     true) && \
    (useradd -m -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash ${USERNAME} 2>&1 || true) && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    (mkdir -p /home/${USERNAME} || true) && \
    (chown -R ${USER_ID}:${GROUP_ID} /home/${USERNAME} 2>/dev/null || true)

# Set up some helpful aliases (as root to avoid ownership issues with high UIDs)
RUN { echo 'alias ll="ls -lah"'; \
      echo 'alias rm="rm -i"'; \
      echo 'alias cp="cp -i"'; \
      echo 'alias mv="mv -i"'; \
      echo 'alias gits="git status"'; \
      echo 'alias gitb="git branch"'; \
      echo 'export PS1="\[\e[1;32m\][redhat-dev]\[\e[0m\] \w $ "'; \
    } >> /home/${USERNAME}/.bashrc || true

# Set working directory
WORKDIR /workspace

# Switch to user
USER ${USERNAME}

CMD ["/bin/bash"]
