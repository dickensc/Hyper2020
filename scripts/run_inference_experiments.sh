#!/bin/bash

# Run experiments using different inference methods.

readonly THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly BASE_OUT_DIR="${THIS_DIR}/../results/inference"

readonly NUM_FOLDS=5

readonly STANDARD_PSL_OPTIONS='-D parallel.numthreads=1'

readonly INFERENCE_METHODS='admm'

readonly WEIGHT_LEARNING_METHODS='gpp uniform'
readonly RULETYPES='-linear -original -quadratic'

# Options specific to each method (missing keys yield empty strings).
declare -A INFERENCE_METHOD_OPTIONS
INFERENCE_METHOD_OPTIONS[sgd]='-D inference.termgenerator=SGDTermGenerator -D inference.termstore=SGDMemoryTermStore -D inference.reasoner=SGDReasoner -D sgd.tolerance=0.000001 -D sgd.maxiterations=500'
INFERENCE_METHOD_OPTIONS[ti]='--infer SGDStreamingInference -D sgd.tolerance=0.000001 -D sgd.maxiterations=500 -D sgd.truncateeverystep=false -D sgdstreaming.randomizepageaccess=false -D sgdstreaming.shufflepage=false'


function run() {
    local cliDir=$1
    local outDir=$2
    local fold=$3
    local wl_method=$4
    local rule_type=$5
    local extraOptions=$6

    mkdir -p "${outDir}"

    local outPath="${outDir}/out.txt"
    local errPath="${outDir}/out.err"
    local timePath="${outDir}/time.txt"

    if [[ -e "${outPath}" ]]; then
        echo "Output file already exists, skipping: ${outPath}"
        return 0
    fi

    pushd . > /dev/null
        cd "${cliDir}"
        /usr/bin/time -v --output="${timePath}" ./run.sh "${fold}" "${wl_method}" "${rule_type}" "${extraOptions}" > "${outPath}" 2> "${errPath}"
    popd > /dev/null
}

function run_example() {
    local exampleDir=$1
    local inference_method=$2
    local wl_method=$3

    local exampleName=`basename "${exampleDir}"`
    local cliDir="$exampleDir/cli"

    local nfolds=NUM_FOLDS
    local outDir
    local options="${STANDARD_PSL_OPTIONS} ${INFERENCE_METHOD_OPTIONS[${inference_method}]}"

   for ruletype in $RULETYPES; do
      for ((fold=0; fold<"${nfolds}"; fold++)) do
        echo "Running ${exampleName} (#${fold}) -- ${method}."
        outDir="${BASE_OUT_DIR}/${exampleName}/${inference_method}/${wl_method}/${ruletype}/${fold}"
        run  "${cliDir}" "${outDir}" "${fold}" "${wl_method}" "${ruletype}" "${options}"
      done
    done
}

function main() {
    if [[ $# -eq 0 ]]; then
        echo "USAGE: $0 <example dir> ..."
        exit 1
    fi

    trap exit SIGINT

    for exampleDir in "$@"; do
        for inference_method in ${INFERENCE_METHODS}; do
            for wl_method in ${WEIGHT_LEARNING_METHODS}; do
              run_example "${exampleDir}" "${inference_method}" "${wl_method}"
            done
        done
    done
}

main "$@"