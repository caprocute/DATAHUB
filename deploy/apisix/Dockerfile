# APISIX + Coraza proxy-wasm — WP-12 DEV (ADR-003)
FROM apache/apisix:3.11.0-debian

USER root
ARG CORAZA_VERSION=0.5.0
RUN apt-get update \
  && apt-get install -y --no-install-recommends curl ca-certificates unzip \
  && mkdir -p /usr/local/apisix/proxywasm \
  && curl -fsSL -o /tmp/coraza.zip \
       "https://github.com/corazawaf/coraza-proxy-wasm/releases/download/${CORAZA_VERSION}/coraza-proxy-wasm-${CORAZA_VERSION}.zip" \
  && unzip -o /tmp/coraza.zip -d /usr/local/apisix/proxywasm \
  && (test -f /usr/local/apisix/proxywasm/coraza-proxy-wasm.wasm \
      || mv /usr/local/apisix/proxywasm/*.wasm /usr/local/apisix/proxywasm/coraza-proxy-wasm.wasm) \
  && rm -f /tmp/coraza.zip \
  && apt-get purge -y curl unzip \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/* \
  && chown -R apisix:apisix /usr/local/apisix/proxywasm

USER apisix
