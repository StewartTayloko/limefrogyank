# `before_deploy` phase: here we package the build artifacts

set -ex

. $(dirname $0)/utils.sh

# Generate artifacts for release
mk_artifacts() {
    if is_ssse3_target; then
        RUSTFLAGS="-C target-feature=+ssse3" \
        cargo build --target $TARGET --release --features simd-accel
    else
        cargo build --target $TARGET --release
    fi
}

mk_tarball() {
    # create a "staging" directory
    local td=$(mktempd)
    local out_dir=$(pwd)
    local name="${PROJECT_NAME}-${TRAVIS_TAG}-${TARGET}"
    local gcc_prefix="$(gcc_prefix)"
    mkdir "${td:?}/${name}"
    mkdir "$td/$name/complete"

    cp target/$TARGET/release/rg "$td/$name/rg"
    ${gcc_prefix}strip "$td/$name/rg"
    cp {doc/rg.1,README.md,UNLICENSE,COPYING,LICENSE-MIT} "$td/$name/"
    cp \
      target/$TARGET/release/build/ripgrep-*/out/{rg.bash-completion,rg.fish,_rg.ps1} \
      "$td/$name/complete/"
    cp complete/_rg "$td/$name/complete/"

    pushd $td
    tar czf "$out_dir/$name.tar.gz" *
    popd
    rm -r $td
}

main() {
    mk_artifacts
    mk_tarball
}

main
