#!/bin/bash

# Run all the experiments.

INFERENCE_DATASETS='lastfm yelp'

function main() {
    trap exit SIGINT

    local datasetPaths=''
    for dataset in $INFERENCE_DATASETS; do
        datasetPaths="${datasetPaths} datasets/${dataset}"
    done

    echo "Running inference experiments on datasets: [${INFERENCE_DATASETS}]."
    ./scripts/run_inference_experiments.sh $datasetPaths
}

main "$@"