FROM ubuntu:24.04

# 1. Install dependencies
RUN apt-get update && apt-get install -y \
    curl git bash build-essential libssl-dev zlib1g-dev \
    ca-certificates gnupg dirmngr coreutils \
    && rm -rf /var/lib/apt/lists/*

# 2. Install asdf
ENV ASDF_DIR=/root/.asdf
RUN git clone https://github.com/asdf-vm/asdf.git $ASDF_DIR --branch v0.14.0
ENV PATH="$ASDF_DIR/bin:$ASDF_DIR/shims:$PATH"
RUN echo '. $ASDF_DIR/asdf.sh' >> ~/.bashrc \
    && echo '. $ASDF_DIR/completions/asdf.bash' >> ~/.bashrc

# 3. Install StarkNet CLI (starkup)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.starkup.dev | sh \
    && echo 'export PATH=$HOME/.starkup/bin:$PATH' >> ~/.bashrc
ENV PATH="/root/.starkup/bin:${PATH}"

# 4. Install StarkNet Devnet + Node.js via asdf
RUN bash -c ". $ASDF_DIR/asdf.sh \
    && asdf plugin add nodejs \
    && asdf plugin add starknet-devnet \
    && echo 'nodejs 20.5.1' >> ~/.tool-versions \
    && echo 'starknet-devnet 0.4.1' >> ~/.tool-versions \
    && asdf install"

# 5. Verify installs
RUN bash -c ". $ASDF_DIR/asdf.sh \
    && starknet --version || true \
    && starknet-devnet --version || true \
    && node -v"

CMD ["bash"]
