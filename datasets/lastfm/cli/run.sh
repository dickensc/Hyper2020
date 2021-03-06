#!/bin/bash

# Options can also be passed on the command line.
# These options are blind-passed to the CLI.
# Ex: ./run.sh -D log4j.threshold=DEBUG

readonly PSL_VERSION='2.2.1'
readonly JAR_PATH="./psl-cli-${PSL_VERSION}.jar"
readonly FETCH_DATA_SCRIPT='../data/fetchData.sh'
readonly BASE_NAME='lastfm'

readonly ADDITIONAL_PSL_OPTIONS='-int-ids --postgres psl -D log4j.threshold=TRACE persistedatommanager.throwaccessexception=false'
#readonly ADDITIONAL_PSL_OPTIONS='-int-ids -D log4j.threshold=TRACE persistedatommanager.throwaccessexception=false'
readonly ADDITIONAL_EVAL_OPTIONS='--infer --eval org.linqs.psl.evaluation.statistics.ContinuousEvaluator'

declare -A WEIGHT_LEARNING_METHODS
WEIGHT_LEARNING_METHODS[uniform]=''
WEIGHT_LEARNING_METHODS[gpp]='org.linqs.psl.application.learning.weight.bayesian.GaussianProcessPrior'
WEIGHT_LEARNING_METHODS[maxPiecewisePseudoLikelihood]='org.linqs.psl.application.learning.weight.maxlikelihood.MaxPiecewisePseudoLikelihood'

declare -A WEIGHT_LEARNING_METHOD_OPTIONS
WEIGHT_LEARNING_METHOD_OPTIONS[uniform]=''
WEIGHT_LEARNING_METHOD_OPTIONS[gpp]=''
WEIGHT_LEARNING_METHOD_OPTIONS[maxPiecewisePseudoLikelihood]='-D votedperceptron.stepsize=10 -D votedperceptron.numsteps=100'

readonly AVAILABLE_MEM_KB=$(cat /proc/meminfo | grep 'MemTotal' | sed 's/^[^0-9]\+\([0-9]\+\)[^0-9]\+$/\1/')
# Floor by multiples of 5 and then reserve an additional 5 GB.
readonly JAVA_MEM_GB=$((${AVAILABLE_MEM_KB} / 1024 / 1024 / 5 * 5 - 5))

function main() {
   trap exit SIGINT

   local fold=$1
   local wl_method=$2
   local ruletype=$3
   local pruneMethod=$4
   shift 4

   # Get the data
   getData

   # Make sure we can run PSL.
   check_requirements
   fetch_psl

   # Modify data file
   modifyDataFile "0" "${fold}"

   # Run PSL
   runRulePruning "$ruletype" "$pruneMethod" "$@"
   runWeightLearning "../${BASE_NAME}${ruletype}/cli/${BASE_NAME}-pruned.psl" "$wl_method" "$@"
   runEvaluation "$ruletype" "$wl_method" "$@"

   # Modify data file
   modifyDataFile "${fold}" "0"
}

function modifyDataFile() {
  old_fold=$1
  new_fold=$2

  sed -i "s/\/${old_fold}\//\/${new_fold}\//g" lastfm-learn.data
  sed -i "s/\/${old_fold}\//\/${new_fold}\//g" lastfm-eval.data
}

function getData() {
   pushd . > /dev/null

   cd "$(dirname $FETCH_DATA_SCRIPT)"
   bash "$(basename $FETCH_DATA_SCRIPT)"

   popd > /dev/null
}

function runRulePruning() {
   local ruletype=$1
   local pruneMethod=$2

   # check if rule pruning for this iteration
   if [[ "${pruneMethod}" != "NotPrune" ]]; then

     echo "Running PSL Rule Pruning"
     echo "Pruning Additional Options: $3"

     # Run MPPL Weight Learning
     runWeightLearning "../${BASE_NAME}${ruletype}/cli/${BASE_NAME}.psl" "maxPiecewisePseudoLikelihood" "$3"

     # Move / rename learned weights to ../${BASE_NAME}${ruletype}/cli/${BASE_NAME}-mppl-learned.psl
     mv "../${BASE_NAME}${ruletype}/cli/${BASE_NAME}-learned.psl" "../${BASE_NAME}${ruletype}/cli/${BASE_NAME}-mppl-learned.psl"

     # prune the rules
     python3 psl_rule_prune.py "../${BASE_NAME}${ruletype}/cli/${BASE_NAME}-mppl-learned.psl" "${pruneMethod}" "../${BASE_NAME}${ruletype}/cli/${BASE_NAME}-pruned.psl"

   else
      # copy the original .psl file to -pruned.psl
      cp "../${BASE_NAME}${ruletype}/cli/${BASE_NAME}.psl" "../${BASE_NAME}${ruletype}/cli/${BASE_NAME}-pruned.psl"
   fi
}

function runWeightLearning() {
   local modelPath=$1
   local wl_method=$2

   echo "Running PSL Weight Learning"
   echo "Weight Learning options: $3"

   echo "Weight learning Method: $wl_method"

   echo "${WEIGHT_LEARNING_METHODS[${wl_method}]}"
   wl_method_class="${WEIGHT_LEARNING_METHODS[${wl_method}]}"

   echo "Weight learning Class: $wl_method_class"

   echo "${WEIGHT_LEARNING_METHOD_OPTIONS[${wl_method}]}"
   wl_options="${WEIGHT_LEARNING_METHOD_OPTIONS[${wl_method}]}"

   if [[ "uniform" != "${wl_method}" ]]; then
     java -Xmx${JAVA_MEM_GB}G -Xms${JAVA_MEM_GB}G -jar "${JAR_PATH}" --model "${modelPath}" --data "${BASE_NAME}-learn.data" --learn "${wl_method_class}" "${wl_options}" ${ADDITIONAL_PSL_OPTIONS} "$3"
     if [[ "$?" -ne 0 ]]; then
        echo 'ERROR: Failed to run weight learning'
        exit 60
     fi
   fi
}

function runEvaluation() {
   local ruletype=$1
   local wl_method=$2

   echo "Running PSL Inference"
   echo "Evaluation options: $3"

   if [[ "${wl_method}" != "uniform" ]]; then
     java -Xmx${JAVA_MEM_GB}G -Xms${JAVA_MEM_GB}G -jar "${JAR_PATH}" --model "../${BASE_NAME}${ruletype}/cli/${BASE_NAME}-pruned-learned.psl" --data "${BASE_NAME}-eval.data" --output inferred-predicates ${ADDITIONAL_EVAL_OPTIONS} ${ADDITIONAL_PSL_OPTIONS} "$3"
     if [[ "$?" -ne 0 ]]; then
        echo 'ERROR: Failed to run infernce'
        exit 70
     fi
   else
     java -Xmx${JAVA_MEM_GB}G -Xms${JAVA_MEM_GB}G -jar "${JAR_PATH}" --model "../${BASE_NAME}${ruletype}/cli/${BASE_NAME}-pruned.psl" --data "${BASE_NAME}-eval.data" --output inferred-predicates ${ADDITIONAL_EVAL_OPTIONS} ${ADDITIONAL_PSL_OPTIONS} "$3"
     if [[ "$?" -ne 0 ]]; then
        echo 'ERROR: Failed to run infernce'
        exit 70
     fi
   fi
}

function check_requirements() {
   local hasWget
   local hasCurl
   local hasPython

   type wget > /dev/null 2> /dev/null
   hasWget=$?

   type curl > /dev/null 2> /dev/null
   hasCurl=$?

   if [[ "${hasWget}" -ne 0 ]] && [[ "${hasCurl}" -ne 0 ]]; then
      echo 'ERROR: wget or curl required to download dataset'
      exit 10
   fi

   type java > /dev/null 2> /dev/null
   if [[ "$?" -ne 0 ]]; then
      echo 'ERROR: java required to run project'
      exit 13
   fi

   type python > /dev/null 2> /dev/null
   if [[ "$?" -ne 0 ]]; then
      echo 'ERROR: python required to run project'
      exit 13
   fi
}

function get_fetch_command() {
   type curl > /dev/null 2> /dev/null
   if [[ "$?" -eq 0 ]]; then
      echo "curl -o"
      return
   fi

   type wget > /dev/null 2> /dev/null
   if [[ "$?" -eq 0 ]]; then
      echo "wget -O"
      return
   fi

   echo 'ERROR: wget or curl not found'
   exit 20
}

function fetch_file() {
   local url=$1
   local path=$2
   local name=$3

   if [[ -e "${path}" ]]; then
      echo "${name} file found cached, skipping download."
      return
   fi

   echo "Downloading ${name} file located at: '${url}'."
   `get_fetch_command` "${path}" "${url}"
   if [[ "$?" -ne 0 ]]; then
      echo "ERROR: Failed to download ${name} file"
      exit 30
   fi
}

# Fetch the jar from a remote or local location and put it in this directory.
# Snapshots are fetched from the local maven repo and other builds are fetched remotely.
function fetch_psl() {
   if [[ $PSL_VERSION == *'SNAPSHOT'* ]]; then
      local snapshotJARPath="$HOME/.m2/repository/org/linqs/psl-cli/${PSL_VERSION}/psl-cli-${PSL_VERSION}.jar"
      cp "${snapshotJARPath}" "${JAR_PATH}"
   else
      local remoteJARURL="https://repo1.maven.org/maven2/org/linqs/psl-cli/${PSL_VERSION}/psl-cli-${PSL_VERSION}.jar"
      fetch_file "${remoteJARURL}" "${JAR_PATH}" 'psl-jar'
   fi
}

main "$@"
