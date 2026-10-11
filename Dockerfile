ARG MISE_VERSION=2026.9.11

FROM ghcr.io/jdx/mise:${MISE_VERSION} AS mise-image

FROM mcr.microsoft.com/devcontainers/base:bookworm

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/${USERNAME} \
    LOGNAME=${USERNAME} \
    MISE_DATA_DIR=/opt/mise \
    MISE_CONFIG_DIR=/etc/mise \
    MISE_CACHE_DIR=/opt/mise/cache \
    MISE_INSTALL_PATH=/usr/local/bin/mise \
    SHELL=/usr/bin/zsh \
    USER=${USERNAME} \
    PATH=/opt/mise/shims:/usr/local/bin:${PATH}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# OS foundation: packages expected in every shell, bootstrap, and diagnostics path.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        autojump \
        ca-certificates \
        curl \
        fd-find \
        git \
        jq \
        less \
        openssh-client \
        ripgrep \
        sudo \
        tar \
        unzip \
        vim \
        zsh \
    && rm -rf /var/lib/apt/lists/*

# Identity and workspace: keep bind-mounted ~/items writable from host and container.
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
RUN sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b /usr/local/bin \
    && chezmoi --version

# Future layers stay separate: docker access, AI agent config, and language runtimes.

USER ${USERNAME}
WORKDIR /home/${USERNAME}

CMD ["sleep", "infinity"]
