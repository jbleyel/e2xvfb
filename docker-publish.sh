#!/bin/bash
VERSION=latest
docker build . -t jbleyel/e2xvfbatv:${VERSION}
docker push jbleyel/e2xvfbatv:${VERSION}
