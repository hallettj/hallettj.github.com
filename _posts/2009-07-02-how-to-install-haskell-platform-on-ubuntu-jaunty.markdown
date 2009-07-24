---
layout: post
title: How to install Haskell "Batteries Included" Platform on Ubuntu Jaunty
---

Just for kicks I thought I would take another shot at some Haskell programming.
To get all of the common libraries and the automated package installer, cabal,
I set up the [Haskell Platform][]. Here is how I did it.

[Haskell Platform]: http://hackage.haskell.org/platform/

Ubuntu Jaunty includes a package for the Haskell compiler, ghc, at version 6.8.
The Haskell Platform installer will roll its eyes at you if you try to proceed
with this version of ghc. So the first step is to install ghc 6.10.

Paste these lines into `/etc/apt/sources.list.d/haskell.list`:

    deb http://ppa.launchpad.net/someone561/ppa/ubuntu jaunty main
    deb-src http://ppa.launchpad.net/someone561/ppa/ubuntu jaunty main

To get the key to verify packages from that PPA, run this optional command:

    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E51D9310

Then update your package list and install Haskell:

    sudo apt-get update
    sudo apt-get install ghc6 ghc6-prof ghc6-doc haddock

The Haskell Platform website does not list a package for Ubuntu yet. So
[download the source installer][source installer].

[source installer]: http://hackage.haskell.org/platform/

Before you run the installer you will want to install the necessary build
dependencies:

    sudo apt-get install libglut-dev happy alex libedit-dev zlib1g-dev

Please leave a comment if you discover that I have left out any dependencies.

Unpack the source installer wherever you like:

    tar -xzf haskell-platform-2009.2.0.1.tar.gz

Finally `cd` into the installer directory and run the generic installation
procedure:

    ./configure
    make
    sudo checkinstall -y

If all of the above worked, you should be good to go. You compile Haskell code
with `ghc`. You can run an interactive read-eval-print-loop with `ghci`. And
you can install Haskell libraries with `cabal`.

*Updated 2009-07-23*: Added zlib1g-dev to list of build dependencies.
