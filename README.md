# e2xvfb Docker image fork from https://github.com/technic/e2xvfb

[![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/jbleyel/e2xvfbatv.svg)](https://hub.docker.com/r/jbleyel/e2xvfbatv/builds)
[![Docker Pulls](https://img.shields.io/docker/pulls/jbleyel/e2xvfbatv.svg)](https://hub.docker.com/r/jbleyel/e2xvfbatv)

Run enigma2 application via SDL under Xvfb xserver.

If you want to be able to connect to the image with vnc first start it with
```bash
docker run --rm -p 5900:5900 --name enigma2_box jbleyel/e2xvfbatv x11vnc -forever
```
Then to start enigma2 in the container use
```bash
docker exec -e ENIGMA_DEBUG_LVL=5 enigma2_box enigma2
```
Finally, to stop and remove the container use
```bash
docker stop enigma2_box
```
We also support `RESOLUTION` environment variable for Xvfb.

To allow ftp you need to add:
```
-p 21:21 -p 20:20 -p 21100-21110:21100-21110 
```
to docker run command.

To allow ssh you need to add:
```
-p 22:22
```
to docker run command.

# Environment
* Ubuntu 22.04
* openATV enigma2 branch 7.0
* Python 3.10
* default and MetrixHD skin

