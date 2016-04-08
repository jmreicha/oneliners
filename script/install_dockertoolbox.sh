#!/usr/bin/env bash

# This is a helper script for installing the Docker toolbox

echo_info () {
  printf "\033[1;34m[INFO] \033[0m$1"
}

_setup_toolbox() {
    # Install brew
    if ! which "brew" > /dev/null; then
        echo "Homebrew doesn't look like it is installed"
        read -rn1 -p "Do you want to install it? [y] " ans
        echo
        local ans
        ans=$(echo "$ans" | tr Y y)
        if [ -n "$ans" ] && [ "$ans" != "y" ]; then
            echo "Aborting."
            exit 1
        else
            xcode-select --install || true
            ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        fi
    fi

    # Unlink old brew-cask
    if which "brew-cask" > /dev/null; then
        echo_info "Unlinking old brew-cask..."
        echo
        brew unlink brew-cask
        echo
    fi

    echo
    echo_info "Updating brew..."
    echo

    brew update

    if ! which node > /dev/null; then
        echo
        echo_info "Installing node..."
        brew install node
    fi

    echo
    echo_info "Updating brew cask..."
    echo

    # This doesn't actually do anything except activate `brew cask` if it
    # hasn't already been tapped. Otherwise `brew update` also does these
    # updates.
    brew cask update

    # Check the installed docker version vs. the available version on berw cask
    local docker_version
    local dockertoolbox_version
    # Get the current version of the docker command and strip trailing commas
    docker_version=$(docker --version 2>/dev/null | awk '{print $3}' | sed 's/,$//' || true)
    # Get the current version of the docker toolbox cask and strip trailing letters
    dockertoolbox_version=$(brew cask info dockertoolbox | head -1 | awk '{print $2}' | sed 's/[a-z]*$//')

    # If we don't have matching versions, either it's not installed or it's out
    # of date, so we'll install or upgrade (it's the same)
    if [[ ! "$docker_version" = "$dockertoolbox_version" ]]; then
        echo
        if [ -z "$docker_version" ]; then
            echo_info "Installing Docker Toolbox..."
        else
            echo_info "Updating Docker Toolbox..."
            echo_info "Stopping running VMs..."
            echo
            _stop_vms
        fi
        echo

        # Attempt to get the currenet VirtualBox version
        local vbox_version
        vbox_version=$(vboxmanage -v 2>/dev/null || true)

        # Do the install/upgrade
        brew cask install dockertoolbox

        # Check if we need to upgrade the VBox guest additions
        if [[ "$vbox_version" != "$(vboxmanage -v)" ]]; then
            _install_vbox_additions
        fi

        if [ -n "$docker_version" ]; then
            echo
            echo_info "Starting VMs..."
            echo
            _start_vms
        fi
    else
        echo
        echo_info "Docker Toolbox up to date, skipping..."
    fi
}

_install_vbox_additions() {
    echo
    echo_info "Installing VBox Guest Additions..."
    echo
    full_version=$(vboxmanage -v)
    version=$(echo "$full_version" | cut -d 'r' -f 1)
    revision=$(echo "$full_version" | cut -d 'r' -f 2)
    file="Oracle_VM_VirtualBox_Extension_Pack-$version-$revision.vbox-extpack"

    # Download the extension pack
    curl -sL http://download.virtualbox.org/virtualbox/"$version"/"$file" > /tmp/"$file"

    # Install the Guest Additions
    sudo VBoxManage extpack install /tmp/"$file" --replace

    # Remove downloaded files
    rm /tmp/"$file"
}

_setup_toolbox
