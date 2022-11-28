#!/bin/bash

brew install vault
brew install curl
brew install jq

PROJECT_NAME="vault-ops-keys"
while [[ $# -gt 0 ]]; do
  case $1 in
    -g|--githubToken)
      GITHUB_TOKEN="$2"
      shift
      shift
      ;;
    -t|--vaultTarget)
      VAULT_TARGET="$2"
      shift # past argument
      shift
      ;;
    -k|--keysList)
      KEYS_LIST="$2"
      shift # past argument
      shift
      ;;
    -o|--githubOrg)
      GITHUB_ORG="$2"
      shift # past argument
      shift
      ;;
    -h|--help)
      echo "Usage: show-keys.sh -g|--githubToken <githubToken> -t|--vaultTarget <vaultTarget> -k|--keysList <keysList>"
      shift # past argument
      shift
      ;;
    -*)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

if [ -z "$GITHUB_TOKEN" ]; then
  # check if token is saved
  GITHUB_TOKEN=$(cat ~/.github-token-"$PROJECT_NAME")
  if [ -z "$GITHUB_TOKEN" ]; then
    echo "Missing github Token"
    exit 1
  fi
else
  echo "$GITHUB_TOKEN" > ~/.github-token-"$PROJECT_NAME"
fi

if [ -z "$GITHUB_ORG" ]; then
  # check if token is saved
  GITHUB_ORG=$(cat ~/.github-org-"$PROJECT_NAME")
  if [ -z "$GITHUB_ORG" ]; then
    echo "Missing github org"
    exit 1
  fi
else
  echo "$GITHUB_ORG" > ~/.github-org-"$PROJECT_NAME"
fi

if [ -z "$VAULT_TARGET" ]; then
  VAULT_TARGET=$(cat ~/.vault-target-"$PROJECT_NAME")
  if [ -z "$VAULT_TARGET" ]; then
    echo "Missing vault Target"
    exit 1
  fi
  echo "Missing vault Target"
  exit 1
else
  echo "$VAULT_TARGET" > ~/.vault-target-"$PROJECT_NAME"
fi

if [ -z "$KEYS_LIST" ]; then
  # write default keys to property file and use it for future requests
  PROJECT_VERSION="$(brew info dotcomrow/sharedops/"$PROJECT_NAME" --json | jq -r '.[0].versions.stable' | sed "s/\"//g")"
  KEYS_LIST="$(cat "$(brew --cellar dotcomrow/sharedops/"$PROJECT_NAME")"/"$PROJECT_VERSION"/files/keys.properties)"
  if [ -z "$KEYS_LIST" ]; then
    echo "Missing keys List"
    exit 1
  fi
fi

vault login -address="$VAULT_TARGET" -method=github -path=github_"$GITHUB_ORG" token="$GITHUB_TOKEN"
for key in $KEYS_LIST; do
  bash -c "echo '------------------------------------------------'; echo \"Key: $key\"; vault read -address=\"$VAULT_TARGET\" \"$key\"; echo '------------------------------------------------'; wait;" &
done