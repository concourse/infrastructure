#!/bin/bash

function tfoutput() {
  terraform output -json | jq -r ".$1.value"
}
