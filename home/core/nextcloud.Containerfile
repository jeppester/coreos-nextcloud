FROM docker.io/nextcloud:apache

RUN apt update && apt -y install ffmpeg
