#!/bin/bash

# Run experiments using different inference methods.

readonly THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly BASE_OUT_DIR="${THIS_DIR}/../results/inference"

readonly NUM_RUNS=1

readonly STANDARD_PSL_OPTIONS='-D parallel.numthreads=1'

readonly METHODS='admm'

# Options specific to each method (missing keys yield empty strings).
declare -A METHOD_OPTIONS
METHOD_OPTIONS[sgd]='-D inference.termgenerator=SGDTermGenerator -D inference.termstore=SGDMemoryTermStore -D inference.reasoner=SGDReasoner -D sgd.tolerance=0.000001 -D sgd.maxiterations=500'
METHOD_OPTIONS[ti]='--infer SGDStreamingInference -D sgd.tolerance=0.000001 -D sgd.maxiterations=500 -D sgd.truncateeverystep=false -D sgdstreaming.randomizepageaccess=false -D sgdstreaming.shufflepage=false'

function run() {
    local cliDir=$1
    local outDir=$2
    local extraOptions=$3

    mkdir -p "${outDir}"

    local outPath="${outDir}/out.txt"
    local errPath="${outDir}/out.err"
    local timePath="${outDir}/time.txt"

    if [[ -e "${outPath}" ]]; then
        echo "Output file already exists, skipping: ${outPath}"
        return 0
    fi

    pushd . > /dev/null
        cd "${clidir}/../data"
        folds="$(ls -l | grep "^d" | wc -l)"
    popd > /dev/null

    pushd . > /dev/null
        cd "${cliDir}"
        /usr/bin/time -v --output="${timePath}" ./run.sh ${folds} ${extraOptions} > "${outPath}" 2> "${errPath}"
    popd > /dev/null
}

function run_example() {
    local exampleDir=$1
    local method=$2
    local iteration=$3

    local exampleName=`basename "${exampleDir}"`
    local cliDir="$exampleDir/cli"

    local outDir="${BASE_OUT_DIR}/${iteration}/${exampleName}/${method}"
    local options="${STANDARD_PSL_OPTIONS} ${EXAMPLE_OPTIONS[${exampleName}]} ${METHOD_OPTIONS[${method}]}"

    echo "Running ${exampleName} (#${iteration}) -- ${method}."
    run  "${cliDir}" "${outDir}" "${options}"
}

function main() {
    if [[ $# -eq 0 ]]; then
        echo "USAGE: $0 <example dir> ..."
        exit 1
    fi

    trap exit SIGINT

    for i in `seq -w 1 ${NUM_RUNS}`; do
        for exampleDir in "$@"; do
            for method in ${METHODS}; do
                run_example "${exampleDir}" "${method}" "${i}"
            done
        done
    done
}

main "$@"