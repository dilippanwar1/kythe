#!/bin/bash -e

# Copyright 2016 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# bundle_case test-file clang-standard indexer-argument1 indexer-argument2
#             verifier-argument1 verifier-argument2
#             [expectfailindex | expectfailverify]

VERIFIER="kythe/cxx/verifier/verifier"
INDEXER="kythe/cxx/indexer/cxx/indexer"
EXTRACTOR="kythe/cxx/extractor/cxx_extractor"
BASE_DIR="$TEST_SRCDIR/kythe/cxx/indexer/cxx/testdata"
OUT_DIR="$TEST_TMPDIR"
TEST_FILE="${1}"
RESULTS_EXPECTED="${7}"
BUNDLE_SHA="$(sha1sum "$TEST_FILE" | cut -f1 -d" ")"
TEMP_PREFIX="${OUT_DIR}"/"${BUNDLE_SHA}"

# Call the first lines in the bundle 'test.cc' for consistency.
BUNDLE_COPY="${TEMP_PREFIX}"/bundle.hcc
rm -rf -- "${TEMP_PREFIX}"
mkdir -p "${TEMP_PREFIX}"/test_bundle
echo "#example test.cc" > "${BUNDLE_COPY}"
cat "${TEST_FILE}" >> "${BUNDLE_COPY}"

# Split the bundle into files via "#example file.name" delimiter lines.
pushd "${TEMP_PREFIX}" > /dev/null
awk '/#example .*/{x="test_bundle/"$2;next}{print > x;}' bundle.hcc
popd > /dev/null

# Extract the split bundle.
KYTHE_ROOT_DIRECTORY="$PWD" KYTHE_OUTPUT_DIRECTORY="${TEMP_PREFIX}" \
    KYTHE_VNAMES="${BASE_DIR}"/test_vnames.json "${EXTRACTOR}" \
    -c -std="$2" "${TEMP_PREFIX}"/test_bundle/test.cc
KINDEX_FILE="$(find "${TEMP_PREFIX}" -iname '*.kindex')"

# Run the indexer on the resulting .kindex.
set +e
"${INDEXER}" -claim_unknown=false "${KINDEX_FILE}" "$3" "$4" \
    | "${VERIFIER}" "$5" "$6" "${TEMP_PREFIX}"/test_bundle/*
RESULTS=( ${PIPESTATUS[0]} ${PIPESTATUS[1]} )
source kythe/cxx/indexer/cxx/testdata/handle_results.sh
