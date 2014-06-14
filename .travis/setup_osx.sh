# Only run on OSX
if [[ $TRAVIS_OS_NAME == "osx" ]]; then
    brew update;
    brew install dmd;
    brew install dub;
    brew install freeimage
fi
