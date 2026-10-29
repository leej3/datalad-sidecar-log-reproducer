FROM ghcr.io/prefix-dev/pixi:0.83.0@sha256:3dce86c6e87371c58035aa41b09f2b56ca8f011722320551e0c2bfc1c59da5fb
WORKDIR /reproducer
COPY pixi.toml pixi.lock ./
RUN pixi install --locked
COPY reproduce.sh verify.py ./
CMD ["pixi", "run", "--locked", "reproduce"]
