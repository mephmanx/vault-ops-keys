#!/bin/bash

PROJECT_NAME="vault-ops-keys"
PROJECT_VERSION="1.1"
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
  GITHUB_TOKEN=$(cat ~/.github-token)
  if [ -z "$GITHUB_TOKEN" ]; then
    echo "Missing githubToken"
    exit 1
  fi
else
  echo "$GITHUB_TOKEN" > ~/.github-token-$PROJECT_NAME
fi

if [ -z "$VAULT_TARGET" ]; then
  VAULT_TARGET=$(cat ~/.vault-target)
  if [ -z "$VAULT_TARGET" ]; then
    echo "Missing vaultTarget"
    exit 1
  fi
  echo "Missing vaultTarget"
  exit 1
else
  echo "$VAULT_TARGET" > ~/.vault-target-$PROJECT_NAME
fi

if [ ! -z "$KEYS_LIST" ]; then
  # write default keys to property file and use it for future requests

  KEYS_LIST=$(cat "$(brew --cellar dotcomrow/sharedops/vault-ops-keys)"/$PROJECT_VERSION/files/keys.properties)
  if [ -z "$KEYS_LIST" ]; then
    echo "Missing keysList"
    exit 1
  fi
else
  echo "$KEYS_LIST" > ~/.keys-list-$PROJECT_NAME
fi

brew install vault
vault login -method=github token="$GITHUB_TOKEN"
vault read "$VAULT_TARGET"/"$KEYS_LIST"
vault logout