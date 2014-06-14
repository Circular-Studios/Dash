# Only run on OSX
if [[ $TRAVIS_OS_NAME == "linux" ]]; then
    sudo wget http://netcologne.dl.sourceforge.net/project/d-apt/files/d-apt.list\
        -O/etc/apt/sources.list.d/d-apt.list;
    sudo apt-get update;
    sudo apt-get -y --allow-unauthenticated install --reinstall d-apt-keyring;
    sudo apt-get update;
    sudo apt-get install dmd-bin dub libfreeimage-dev libjpeg62-dev
fi
