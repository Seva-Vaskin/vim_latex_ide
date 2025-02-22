# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install locales package and generate locales
RUN apt-get update && apt-get install -y locales \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8

# Set locale environment variables
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Update and install dependencies
RUN apt-get update && apt-get install -y \
    texlive-full

RUN apt-get install -y \
    build-essential \
    cmake \
    git \
    libtool-bin \
    ninja-build \
    pkg-config \
    gettext \
    curl \
    python3 \
    python3-pip \
    python3-venv \
    python-is-python3 \
    software-properties-common \
    ruby-dev \
    cpanminus \
    zathura \
    inkscape \
    xclip \
    ripgrep \
    xdotool \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    dbus-x11 \
    libglib2.0-0 \
    psmisc \
    rofi \
    pdf2svg \
    rxvt-unicode \
    ranger \
    caca-utils \
    highlight \
    atool \
    w3m \
    poppler-utils \
    mediainfo \
    wget \
    gnupg \
    xvfb \
    x11-xserver-utils \
    xpra \
    libxkbfile-dev \
    libboost-all-dev

# Install Node.js (LTS version)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Build Neovim from source
RUN git clone https://github.com/neovim/neovim.git /tmp/neovim \
    && cd /tmp/neovim \
    && git checkout stable \
    && make CMAKE_BUILD_TYPE=Release \
    && make install \
    && rm -rf /tmp/neovim

# Install Node.js support for Neovim
RUN npm install -g neovim

# Install Ruby support for Neovim
RUN gem install neovim
RUN cpanm --force Neovim::Ext IO::Async MsgPack::Raw Eval::Safe 
RUN cpan App::cpanminus

# Configure Xpra
RUN mkdir -p /run/user/0/xpra

# Install XKB-Switch (required for SALKS)
RUN git clone https://github.com/sergei-mironov/xkb-switch.git /tmp/xkb-switch \
    && cd /tmp/xkb-switch \
    && mkdir build && cd build \
    && cmake .. \
    && make \
    && make install \
    && rm -rf /tmp/xkb-switch

# Install SALKS
RUN git clone --recursive https://github.com/sharkov63/sakls.git /tmp/sakls \
    && cd /tmp/sakls \
    && mkdir build && cd build \
    && cmake \
        -DCMAKE_CXX_FLAGS="-Wno-error=unused-variable" \
        -DSAKLS_ENABLE_LAYOUT_BACKENDS="xkb-switch" \
        .. \
    && make -j \
    && cp lib/libSAKLS.so /usr/lib/libSAKLS.so \
    && rm -rf /tmp/sakls

RUN ldconfig

ARG USER=user
RUN useradd -ms /bin/bash $USER
RUN usermod -aG sudo $USER

# Switch to the new user
USER $USER
ENV HOME=/home/$USER
WORKDIR $HOME

# Install Python support for Neovim
RUN pip3 install --upgrade pip \
    && pip3 install \
        pynvim \
        neovim-remote \
        inkscape-figures \
        xlib \
        Pygments
ENV PATH=${HOME}/.local/bin/:${PATH}

# Set environment variables required by neovim-remote
ENV NVIM_LISTEN_ADDRESS=/tmp/nvimsocket

# Install inkscape shortcut manager 
RUN git clone https://github.com/gillescastel/inkscape-shortcut-manager.git $HOME/.local/share/inkscape-shortcut-manager

# Manually download and install Russian spell files for Vim
RUN mkdir -p $HOME/.local/share/nvim/site/spell \
    && curl -fLo $HOME/.local/share/nvim/site/spell/ru.utf-8.spl \
        https://ftp.nluug.nl/pub/vim/runtime/spell/ru.utf-8.spl \
    && curl -fLo $HOME/.local/share/nvim/site/spell/ru.utf-8.sug \
        https://ftp.nluug.nl/pub/vim/runtime/spell/ru.utf-8.sug

# Install Vim-Plug
RUN mkdir -p $HOME/.local/share/nvim/site/autoload
RUN curl -fLo $HOME/.local/share/nvim/site/autoload/plug.vim \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Copy config files
COPY ./config/ $HOME/.config/

# Install Neovim plugins
RUN nvim -u ${HOME}/.config/nvim/lua/texvide/plugins.lua --headless +PlugInstall +qall

COPY ./launch/entrypoint.sh /entrypoint.sh
RUN echo "source $HOME/.config/env_config.sh" >> $HOME/.bashrc

WORKDIR /userdata
ENTRYPOINT [ "/entrypoint.sh" ]