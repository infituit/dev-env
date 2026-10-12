# syntax=docker/dockerfile:1

ARG MISE_VERSION=2026.9.11
ARG CHEZMOI_VERSION=2.73.0

FROM ghcr.io/jdx/mise:${MISE_VERSION} AS mise-image

FROM mcr.microsoft.com/devcontainers/base:bookworm

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
ARG CHEZMOI_VERSION

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/${USERNAME} \
    LOGNAME=${USERNAME} \
    MISE_DATA_DIR=/home/${USERNAME}/.local/share/mise \
    MISE_CONFIG_DIR=/home/${USERNAME}/.config/mise \
    MISE_CACHE_DIR=/home/${USERNAME}/.cache/mise \
    MISE_STATE_DIR=/home/${USERNAME}/.local/state/mise \
    MISE_INSTALL_PATH=/usr/local/bin/mise \
    SHELL=/usr/bin/zsh \
    USER=${USERNAME} \
    PATH=/home/${USERNAME}/.local/share/mise/shims:/usr/local/bin:${PATH}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# OS foundation: packages expected in every shell, bootstrap, and diagnostics path.
RUN rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        autojump \
        ca-certificates \
        curl \
        fd-find \
        git \
        iputils-ping \
        jq \
        less \
        openssh-client \
        ripgrep \
        sudo \
        tar \
        unzip \
        vim \
        zsh

# Identity and home: keep the persistent container home writable by the dev user.
RUN if getent group "${USER_GID}" >/dev/null; then \
        EXISTING_GROUP="$(getent group "${USER_GID}" | cut -d: -f1)"; \
        groupmod --new-name "${USERNAME}" "${EXISTING_GROUP}"; \
    else \
        groupadd --gid "${USER_GID}" "${USERNAME}"; \
    fi \
    && if id --user "${USER_UID}" >/dev/null 2>&1; then \
        EXISTING_USER="$(getent passwd "${USER_UID}" | cut -d: -f1)"; \
        usermod --login "${USERNAME}" --home "/home/${USERNAME}" --move-home "${EXISTING_USER}"; \
        usermod --gid "${USER_GID}" --shell /usr/bin/zsh "${USERNAME}"; \
    else \
        useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /usr/bin/zsh "${USERNAME}"; \
    fi \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}" \
    && mkdir -p "/home/${USERNAME}/items" "/home/${USERNAME}/.dev-env/state" \
    && chown -R "${USER_UID}:${USER_GID}" "/home/${USERNAME}"

# Project tool manager layer: project runtimes and tasks belong in per-repo mise.toml.
COPY --from=mise-image /usr/local/bin/mise /usr/local/bin/mise
RUN mise --version

# Dotfiles manager layer: install chezmoi only; applying private dotfiles is first-run state.
RUN curl --fail --show-error --silent --location --retry 3 --retry-delay 2 --http1.1 \
        "https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION}/chezmoi_${CHEZMOI_VERSION}_linux-glibc_amd64.tar.gz" \
        | tar --extract --gzip --directory /usr/local/bin chezmoi \
    && chmod +x /usr/local/bin/chezmoi \
    && chezmoi --version

# Future layers stay separate: docker access, AI agent config, and language runtimes.

USER ${USERNAME}
WORKDIR /home/${USERNAME}

CMD ["sleep", "infinity"]
