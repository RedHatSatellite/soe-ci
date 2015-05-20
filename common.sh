#!/bin/bash 

# common stuff

# Error states
NOARGS=1
GITVER_ERR=2
GITREV_ERR=3
RPMBUILD_ERR=4
WORKSPACE_ERR=5
SRPMBUILD_ERR=6
MODBUILD_ERR=7

function tell() {
	echo "${@} [$(date)]" | fold -s
}

function info() {
	tell "INFO:    ${@}"
}

function usage() {
	tell "USAGE:   ${@}"
}

function warn() {
	tell "WARNING: ${@}" >&2
}

function err() {
	tell "ERROR:   ${@}" >&2
}
