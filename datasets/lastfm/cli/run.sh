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

declare -A WEIGHT_LEARNING_METHOD_OPTIONS
WEIGHT_LEARNING_METHOD_OPTIONS[uniform]=''
WEIGHT_LEARNING_METHOD_OPTIONS[gpp]='-learn org.linqs.psl.application.learning.weight.bayesian.GaussianProcessPrior'

readonly RULETYPES='-linear -orignal -quadratic'

readonly AVAILABLE_MEM_KB=$(cat /proc/meminfo | grep 'MemTotal' | sed 's/^[^0-9]\+\([0-9]\+\)[^0-9]\+$/\1/')
# Floor by multiples of 5 and then reserve an additional 5 GB.
readonly JAVA_MEM_GB=$((${AVAILABLE_MEM_KB} / 1024 / 1024 / 5 * 5 - 5))

function main() {
   trap exit SIGINT

   fold=$1
   wl_method=$2
   shift 2

   # Get the data
   getData

   # Make sure we can run PSL.
   check_requirements
   fetch_psl

   for ruletype in $RULETYPES
   do
       # Modify data file
       modifyDataFile "0" "${fold}"

       # Run PSL
       runWeightLearning "$ruletype" "$wl_method" "$@"
       runEvaluation "$ruletype" "$wl_method" "$@"

       # Modify data file
       modifyDataFile "${fold}" "0"
   done
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

function runWeightLearning() {
   ruletype=$1
   wl_method=$2

   echo "Running PSL Weight Learning"
   echo "Weight Learning options: $3"

   echo "${WEIGHT_LEARNING_METHOD_OPTIONS[${wl_method}]}"

   if [[ "uniform" != "${wl_method}" ]]; then
     java -Xmx${JAVA_MEM_GB}G -Xms${JAVA_MEM_GB}G -jar "${JAR_PATH}" --model "../${BASE_NAME}${ruletype}/cli/${BASE_NAME}.psl" --data "${BASE_NAME}-learn.data" "${WEIGHT_LEARNING_METHOD_OPTIONS[${wl_method}]}" ${ADDITIONAL_PSL_OPTIONS} "$3"
     if [[ "$?" -ne 0 ]]; then
        echo 'ERROR: Failed to run weight learning'
        exit 60
     fi
   fi
}

function runEvaluation() {
   ruletype=$1
   wl_method=$2

   echo "Running PSL Inference"
   echo "Evaluation options: $3"

   if [[ "uniform" != "${wl_method}" ]]; then
     java -Xmx${JAVA_MEM_GB}G -Xms${JAVA_MEM_GB}G -jar "${JAR_PATH}" --model "../${BASE_NAME}${ruletype}/cli/${BASE_NAME}-learned.psl" --data "${BASE_NAME}-eval.data" --output inferred-predicates ${ADDITIONAL_EVAL_OPTIONS} ${ADDITIONAL_PSL_OPTIONS} "$3"
     if [[ "$?" -ne 0 ]]; then
        echo 'ERROR: Failed to run infernce'
        exit 70
     fi
   else
     java -Xmx${JAVA_MEM_GB}G -Xms${JAVA_MEM_GB}G -jar "${JAR_PATH}" --model "../${BASE_NAME}${ruletype}/cli/${BASE_NAME}.psl" --data "${BASE_NAME}-eval.data" --output inferred-predicates ${ADDITIONAL_EVAL_OPTIONS} ${ADDITIONAL_PSL_OPTIONS} "$3"
     if [[ "$?" -ne 0 ]]; then
        echo 'ERROR: Failed to run infernce'
        exit 70
     fi
   fi
}

function check_requirements() {
   local hasWget
   local hasCurl

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
