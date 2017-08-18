#!/bin/bash

# Dr. Rob Hutchinson, University of Puget Sound
# Music Theory for the 21st Century

# Source a custom file with three path names
# See paths.sh.template, copy to paths.sh
DIR="$(dirname "$0")"
. ${DIR}/paths.sh

# following depend on paths source'd above
declare PTXXSL=${PTX}/xsl
declare PTXSCRIPT=${PTX}/script/mbx
declare SOURCE=${SRC}/src
declare IMAGES=${SRC}/images

# Root XML File, also assume that this is filename of generated LaTeX
declare ROOT=MusicTheory

# convenience for rsync command, hopefully not OS dependent
# DOES NOT includes --delete switch at end due to PDF in directory
# If switch is included this could be an *exact* mirror of build directory
declare RSYNC="rsync --verbose  --progress --stats --compress --rsh=/usr/bin/ssh --recursive"

# website upload parameterized by username
declare UNAME="$2"

# Common setup
function setup {
    # not necessary, but always build scratch directory first
    echo
    echo "BUILD: Setup Scratch Directory :BUILD"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    install -d ${SCRATCH}
}

# Validation using RELAX-NG
function validate {
    echo
    echo "VALIDATE: Validating XML Against RELAX-NG Schema :VALIDATE"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    java\
        -classpath ${JINGTRANG}\
        -Dorg.apache.xerces.xni.parser.XMLParserConfiguration=org.apache.xerces.parsers.XIncludeParserConfiguration\
        -jar ${JINGTRANG}/jing.jar\
        ${PTX}/Schema/pretext.rng ${SOURCE}/${ROOT}.xml\
    > ${SCRATCH}/errors.txt
}

# Subroutine to build the PDF/print Version
function build_pdf {
    echo
    echo "BUILD: Building Print Version :BUILD"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    install -d ${SCRATCH}/pdf ${SCRATCH}/pdf/images
    cd ${SCRATCH}/pdf
    rm ${ROOT}.tex
    cp -a ${IMAGES}/* ./images/
    xsltproc --xinclude ${PTXXSL}/mathbook-latex.xsl ${SOURCE}/${ROOT}.xml
    echo
    xelatex ${ROOT}.tex
    echo
    xelatex ${ROOT}.tex
}

# Subroutine to build the HTML Version
function build_html {
    echo
    echo "BUILD: Building HTML Version :BUILD"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    install -d\
        ${SCRATCH}/html\
        ${SCRATCH}/html/images\
        ${SCRATCH}/html/knowl
    cd ${SCRATCH}/html
    rm *.html
    rm -rf knowl/* images/*
    cp -a ${IMAGES}/* ./images/
    xsltproc --xinclude ${PTXXSL}/mathbook-html.xsl ${SOURCE}/${ROOT}.xml
}

function view_errors {
    less ${SCRATCH}/errors.txt
}

function view_pdf {
    ${PDFVIEWER} ${SCRATCH}/pdf/${ROOT}.pdf
}

function view_html {
    ${HTMLVIEWER} ${SCRATCH}/html/index.html
}

# $2 is a username with priviliges at
# /var/www/html/musictheory.pugetsound.edu/ on musictheory.pugetsound.edu
function website {
    # test for zero string as account name and exit with message
    if [ -z "${UNAME}" ] ; then
        echo
        echo "BUILD: Website upload needs an account username, quitting... :BUILD"
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        exit
    fi
    echo
    echo "BUILD: rsync entire web version...                      :BUILD"
    echo "BUILD: username as parameter 2, then supply password... :BUILD"
    echo
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ${RSYNC} ${SCRATCH}/html/*  ${UNAME}@musictheory.pugetsound.edu:/var/www/html/musictheory.pugetsound.edu/mt21c
}

# Main command-line interpreter
case "$1" in
    "validate")
    setup
    validate
    ;;
    "viewerrors")
    view_errors
    ;;
    "pdf")
    setup
    build_pdf
    ;;
    "viewpdf")
    view_pdf
    ;;
    "html")
    setup
    build_html
    ;;
    "viewhtml")
    view_html
    ;;
    "website")
    setup
    build_html
    website
    ;;
    *)
    echo "Supply an option: validate|viewerrors|pdf|viewpdf|html|viewhtml|website <username>"
    ;;
esac
