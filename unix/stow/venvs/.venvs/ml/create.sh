#!/usr/bin/env bash

run () {
  local executable=python3.10

  local dirPath=$(realpath $(dirname $BASH_SOURCE))
  local promptName=$(basename $dirPath)
  local reqFile=${dirPath}/requirements.txt

  echo "Creating virtual environment: $promptName"
  $executable -m venv --prompt $promptName $dirPath

  echo "Activating virtual environment"
  source ${dirPath}/bin/activate 
  
  echo "Installing requirements from $reqFile"
  pip install -r $reqFile 
}

run

