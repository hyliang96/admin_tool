#!/usr/bin/env bash


# when run `sudo apt update` and get return
# W: GPG error: http://archive.ubuntu.com trusty Release: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 40976EAF437D05B5 NO_PUBKEY 3B4FE6ACC0B21F32
# notice the <key> is '3B4FE6ACC0B21F32', which is not registed in local apt
# to fix this, please run this `fix_apt_key <key>`
alias fix_apt_key='sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys'
