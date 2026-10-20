#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

TAG=$1
PREFIX="rules_wine-${TAG:1}"
ARCHIVE="rules_wine-$TAG.tar.gz"

git archive --format=tar --prefix="${PREFIX}/" "${TAG}" | gzip > "${ARCHIVE}"
INTEGRITY="sha256-$(openssl dgst -sha256 -binary "${ARCHIVE}" | openssl base64 -A)"

cat << EOF
## Using Bzlmod

Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "rules_wine", version = "${TAG:1}")
\`\`\`

## Using an archive override

\`\`\`starlark
archive_override(
    module_name = "rules_wine",
    integrity = "${INTEGRITY}",
    strip_prefix = "${PREFIX}",
    urls = ["https://github.com/hermeticbuild/rules_wine/releases/download/${TAG}/${ARCHIVE}"],
)
\`\`\`
EOF
