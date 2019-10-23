#!/bin/bash
truffle migrate --network u0dwxbpj5l --reset > /dev/null &
sleep 1
set -x
truffle migrate --network u0dwxbpj5l --reset
