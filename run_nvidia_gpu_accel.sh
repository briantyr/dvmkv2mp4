#!/usr/bin/env bash
#
# Example of using `ubuntu:20.04` base image with Docker arguments specifically designed
# to allow the GPU to be passed in from the host.  You can confirm this if you have an
# RTX 30/40/50 series card by using this image to build a container and utilize
# `nvidia-smi` to confirm the GPU appears.

# Example run of ubuntu base container but pass in GPU
# * Make sure to pass in --device (/dev/dri) to allow the container access to GPU hardware.
# * Pass in `--gpus all` to tell Docker to allow GPU in.

# This will convert any MKV files inside the volume mounted to /convert/ to MP4 (as long as 
# the MKV file(s) use Dolby Vision HDR10+ 
docker run -it --rm --device /dev/dri:/dev/dri --gpus all -v /media/Downloads/Movie/:/convert/ --name btaylormd/dvmkv2mp4:latest -l eng


