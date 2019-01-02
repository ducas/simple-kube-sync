#!/bin/bash

echo "Synchronising..."

git clone $GIT_REPO git_repo
pushd git_repo

if [[ -f "build.sh" ]]; then
  echo "Found build.sh. Running..."
  ./build.sh
fi

if [[ -f "apply.sh" ]]; then
  echo "Found apply.sh. Running..."
  ./apply.sh
else
  echo "Running \"kubectl apply -f .\"..."
  kubectl apply -f .
fi

if [[ -f "tidy.sh" ]]; then
  echo "Found tidy.sh. Running..."
  ./tidy.sh
fi

echo "All done."

popd
