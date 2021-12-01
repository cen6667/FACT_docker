FROM ubuntu:focal

# Upgrade system and install dependencies of the installer
RUN apt -y update && apt -y upgrade && \
    DEBIAN_FRONTEND="noninteractive" apt -y install --no-install-recommends \
        ca-certificates \
        git \
        lsb-release \
        patch \
        sudo \
        tzdata \
        wget

RUN useradd -r --no-create-home -d /var/log/fact fact
RUN printf 'fact	ALL=(ALL:ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/99_fact

RUN mkdir /opt/FACT_core && chown fact: /opt/FACT_core
RUN mkdir /var/log/fact && chown fact: /var/log/fact

USER fact:fact
WORKDIR /var/log/fact

RUN git clone https://github.com/cen6667/FACT_core_3.1_11242.git /opt/FACT_core

RUN /opt/FACT_core/src/install/pre_install.sh
RUN FACT_INSTALLER_SKIP_DOCKER=y /opt/FACT_core/src/install.py

# Apply some patches to the default config to make it _just work_ without any configuration
# The patched config is only needed during runtime and not during installation
COPY --chown=fact:fact 0000_uwsgi_bindip.patch /tmp/0000_uwsgi_bindip.patch
RUN patch /opt/FACT_core/src/config/uwsgi_config.ini < /tmp/0000_uwsgi_bindip.patch \
    && rm /tmp/0000_uwsgi_bindip.patch
COPY --chown=fact:fact 0001_main_cfg.patch /tmp/0001_main_cfg.patch
RUN patch /opt/FACT_core/src/config/main.cfg < /tmp/0001_main_cfg.patch \
    && rm /tmp/0001_main_cfg.patch

COPY --chown=fact:fact 0002_main_cfg.patch.template /opt/FACT_core/0002_main_cfg.patch.template

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
