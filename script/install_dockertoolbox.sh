#!/usr/bin/env bash

# This is a helper script for installing the Docker toolbox

echo_info () {
  printf "\033[1;34m[INFO] \033[0m$1"
}

_setup_toolbox() {
    if ! which "brew" > /dev/null; then
        echo_info "Please install brew first!\n"
        exit 1
    fi

    # Unlink old brew-cask
    if which "brew-cask" > /dev/null; then
        echo_info "Unlinking old brew-cask...\n"
        echo
        brew unlink brew-cask
        echo
    fi

    # Install cask
    if [ ! -d /opt/homebrew-cask ]; then
        echo "Brew cask doesn't look like it is installed"
        echo -n "Do you want to install it? [y]"
        read n1 ans
        echo
        ans=$(echo $ans | tr Y y)
        if [ -n "$ans" ] && [ "$ans" != "y" ]; then
            echo "Aborting."
            exit 1
        else
            brew tap caskroom/cask
        fi
    fi

    echo
    echo_info "Updating brew...\n"
    echo
    brew update
    echo

    echo_info "Adding brew cask for Docker Toolbox...\n"
    echo
    brew install caskroom/cask/brew-cask
    brew link brew-cask
    echo

    echo_info "Installing Docker Toolbox...\n"
    echo
    brew cask install dockertoolbox
    echo
}

_setup_toolbox
