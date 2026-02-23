# Important that cat /etc/os-release is Debian 12 for python version 3.11 as
# flatdict doesn't support newer python releases for the RailsTranslator
FROM ruby:3.2.10-bookworm

ENV RAILS_ENV="development" \
    BUNDLE_WITHOUT=""

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential git libpq-dev pkg-config curl libjemalloc2 libvips postgresql-client

# Install python to use translation tool
RUN apt-get update -qq && \
    apt-get install -y \
    python3 python3-pip python3-venv

# Install node for postcss with tailwindcss-rails
ENV NODE_VERSION=22.12.0
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
