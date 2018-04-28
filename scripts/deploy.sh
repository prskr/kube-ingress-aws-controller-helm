#!/bin/bash

helm registry login -u baez+travis -p "$QUAY_IO_TOKEN" quay.io
helm registry push -v ${TRAVIS_TAG} --namespace baez quay.io