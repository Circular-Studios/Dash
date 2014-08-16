# Only run on OSX
if [[ $TRAVIS_OS_NAME == "osx" ]]; then
    # Install DMD
    DMD_DMG=dmd.${DMD_VER}.dmg
    wget ftp://ftp.dlang.org/${DMD_DMG}
    sudo hdiutil mount ${DMD_DMG}
    sudo installer -package /Volumes/DMD2/DMD2.pkg -target /

    brew update
    brew install freeimage
fi
