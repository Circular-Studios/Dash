dub fetch --system derelict-util --version=1.0.0
dub fetch --system derelict-gl3 --version=~master
dub fetch --system derelict-fi --version=~master
dub fetch --system dyaml --version=~master

$doc = Read-Host "Would you like to install ddox? [yes|no]"

if( $doc -eq "yes" )
{
	dub fetch --system ddox --version=~master
	dub fetch --system libevent --version=~master
	dub fetch --system libev --version=~master
	dub fetch --system openssl --version=~master
	dub fetch --system vibe-d --version=~master
	dub build ddox
}

dub generate visuald
