#!/bin/bash

# todo ask all questions up-front
# todo silent / defaulted installs where possible

# Configuration
CONDA_X64=https://repo.anaconda.com/archive/Anaconda3-2021.05-Linux-x86_64.sh

ask_user() {
    USER_PROMPT=$*
    echo "$USER_PROMPT?"
    select yn in "Yes" "No"; do
        case $yn in
        Yes)
            return 0
            ;;
        No)
            return 1
            ;;
        esac
    done
}

echo_confirmation() {
    # Python
    version=$(python -V 2>&1 | grep -Po '(?<=Python )(.+)')
    if [[ -z "$version" ]]; then
        echo "No Python!"
    fi

    echo "Found Python $version"
}

################################################################################

# ------------------------------------------------------------------------------
# Update
#
ask_user "Update first"
UPDATE_FIRST=$?
if test "$UPDATE_FIRST" -eq "0"; then
    sudo apt-get update -y
fi

# ------------------------------------------------------------------------------
# Basics
#
ask_user "Install build-essential++"
INSTALL_ESSENTIALS=$?
if test "$INSTALL_ESSENTIALS" -eq "0"; then
    apt-get install -y build-essential

    apt-get install -y autoconf automake
    apt-get install -y gdb

    # https://askubuntu.com/questions/796600/difference-between-installing-git-vs-installing-git-all
    # https://packages.debian.org/sid/git
    apt-get install -y git git-gui gitk

    # https://github.com/libffi/libffi
    apt-get install -y libffi-dev
    apt-get install -y zlib1g-dev
    apt-get install -y libssl-dev

    apt-get install -y valgrind
    echo "Installed basics"
    gcc --version
    make --version
    make --version
fi

# ------------------------------------------------------------------------------
# LLVMM
# https://apt.llvm.org/
#
ask_user "Install LLVM"
INSTALL_LLVM=$?
if test "$INSTALL_LLVM" -eq "0"; then
    bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"
fi

# ------------------------------------------------------------------------------
# Rust
# https://www.rust-lang.org/tools/install
#
ask_user "Install Rust"
INSTALL_RUST=$?
if test "$INSTALL_RUST" -eq "0"; then
    # download and install rustup
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

    # shellcheck source=/dev/null
    . ~/.cargo/env

    # verify
    cargo --version
    rustc --version
fi

# ------------------------------------------------------------------------------
# Anaconda
# https://docs.anaconda.com/anaconda/install/linux/
#
ask_user "Install Anaconda"
INSTALL_CONDA=$?
if test "$INSTALL_CONDA" -eq "0"; then
    wget -P ~/Downloads $CONDA_X64
    bash Anaconda3-2021.05-Linux-x86_64.sh
fi

# ------------------------------------------------------------------------------
# Ruby & Jekyll
# https://jekyllrb.com/docs/installation/ubuntu/
#
ask_user "Install Ruby & Jekyll"
INSTALL_RUBY=$?
if test "$INSTALL_RUBY" -eq "0"; then
    # Install Ruby & dependencies
    sudo apt-get install -y ruby-full build-essential zlib1g-dev

    # Avoid installing RubyGems packages (called gems) as the root user. Instead,
    # set up a gem installation directory for your user account. The following
    # commands will add environment variables to your ~/.bashrc file to configure
    # the gem installation path

    # shellcheck disable=SC2016
    {
        echo '# Install Ruby Gems to ~/gems'
        echo 'export GEM_HOME="$HOME/gems"'
        echo 'export PATH="$HOME/gems/bin:$PATH"'
    } >>~/.bashrc

    # shellcheck source=/dev/null
    source ~/.bashrc

    gem install jekyll bundler
fi

# ------------------------------------------------------------------------------
# VSCode
# https://code.visualstudio.com/docs/setup/linux
#
ask_user "Install VSCode"
INSTALL_VSCODE=$?
if test "$INSTALL_VSCODE" -eq "0"; then
    # Install the repository and key
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >packages.microsoft.gpg
    sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg

    # Update the package cache and install
    sudo apt install -y apt-transport-https
    sudo apt update
    sudo apt install -y code # or code-insiders
fi
