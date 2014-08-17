# Only run on Linux
if [[ $TRAVIS_OS_NAME == "linux" ]]; then
    # Install DMD
    DMD_DEB=dmd_${DMD_VER}-0_amd64.deb
    wget ftp://ftp.dlang.org/${DMD_DEB}
    sudo dpkg -i ${DMD_DEB} || true
    sudo apt-get update
    sudo apt-get install -f
    sudo dpkg -i ${DMD_DEB}

    # Install other dependencies
    sudo apt-get install libfreeimage-dev libjpeg62-dev
fi
