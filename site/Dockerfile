# syntax=docker/dockerfile:1
# check=error=true

# The docs site for velvetkit.com.
#
# Build from the repository root, not site/: the site installs the kit from
# ../registry and reads its preview templates at runtime, so the gem and the
# registry have to be in the image too. Kamal does this (config/deploy.yml):
#
#   docker build -f site/Dockerfile .

ARG RUBY_VERSION=3.4.5
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /velvetkit/site

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config unzip && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV BUN_INSTALL=/usr/local/bun
ENV PATH=/usr/local/bun/bin:$PATH
ARG BUN_VERSION=1.2.21
RUN curl -fsSL https://bun.sh/install | bash -s -- "bun-v${BUN_VERSION}"

# The gem the site's Gemfile points at with `path: ".."`.
COPY velvetkit.gemspec /velvetkit/
COPY lib /velvetkit/lib
COPY registry /velvetkit/registry

COPY site/Gemfile site/Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile -j 1 --gemfile

COPY site/package.json site/bun.lock ./
RUN bun install --frozen-lockfile

COPY site/ ./

# Copy the kit in from the registry, as any app would, then build assets.
RUN SECRET_KEY_BASE_DUMMY=1 bin/sync-kit && \
    bundle exec bootsnap precompile -j 1 app/ lib/ && \
    SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile && \
    rm -rf node_modules

FROM base

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /velvetkit /velvetkit

ENTRYPOINT ["/velvetkit/site/bin/docker-entrypoint"]

EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
