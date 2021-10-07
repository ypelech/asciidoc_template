#!/bin/bash

NULL=
PROG="$0"

die() {
    local m="$1"
    echo "FATAL: ${m}" >&2
    exit 1
}

usage() {
    cat << __EOF__
Usage: ${PROG} [--local] --attr=a=v

__EOF__
    exit 0
}

cd "$(dirname "$0")"

LOCAL=
EXTRA_ATTRIBUTES=
while [ -n "$1" ]; do
    p="${1%%=*}"
    v="${1#*=}"
    case "${p}" in
        --local)
            LOCAL=1
            ;;
        --attr)
            EXTRA_ATTRIBUTES="${EXTRA_ATTRIBUTES} -A ${v}"
            ;;
        --help)
            usage
            ;;
        --)
            break
            ;;
        --*)
            die "Bad paramter '${p}'"
            ;;
        *)
            break
            ;;
    esac
    shift
done

[ -n "${ASCIIDOCTORJ_HOME}" ] || die "Please set ASCIIDOCTORJ_HOME"

OUT="Template_name.zip"

rm -f "${OUT}"
rm -fr build.tmp 

if [ -z "${LOCAL}" ]; then
    mkdir build.tmp
    stash="$(git stash create)"
    [ -n "${stash}" ] || stash="HEAD"
    git archive --format=tar "${stash}" | tar -C build.tmp -x || die "Cannot archive git repo"
    cd build.tmp
fi

for format in html5:.html pdf:.pdf; do
old_IFS="${IFS}"
IFS=":"
set -- ${format}
backend="$1"
suffix="$2"
IFS="${old_IFS}"

ASCIIDOCTORJ_OPTS='"-Xmn128m" "-Xms1024m" "-Xmx1024m"' "${ASCIIDOCTORJ_HOME}/bin/asciidoctorj" \
    -a allow-uri-read=1 \
    -r asciidoctor-diagram \
    -r asciidoctor-pdf \
    --backend "${backend}" \
    -a 'customer_ALL!' \
    -a customer_"${CUSTOMER}"=1 \
    -a "doclinksuffix=${suffix}" \
    ${EXTRA_ATTRIBUTES} \
    *.adoc \
    */*.adoc \
    || die "Failed to generate files"
done

find . \
        -type f \
        -not -name '*.swp' \
        -not -name '*.tmp' \
        -not -name '*.zip' \
        -not -name '*~' \
        -not -name '*.git*' \
        -not -name '*.puml' \
        -not -name '*.adoc' \
        -not -name '*.adoci' \
        -not -name 'build.sh' \
        -not -regex '.*/\.git.*' \
        -not -regex './docinfo.*' \
        -not -regex '.*/.asciidoctor/.*' \
        -not -regex '.*/seqs/.*\.png' \
        -not -regex './asciidoc-temp.*' \
        | \
    zip \
        -qq \
        -S \
        -r \
        -@ \
        "${OUT}" \
        || die "Cannot zip"
    
if [ -z "${LOCAL}" ]; then
    mv "${OUT}" ..
    cd ..
    rm -fr build.tmp
fi

echo "${OUT}" is ready


