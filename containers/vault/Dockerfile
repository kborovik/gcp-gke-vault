FROM alpine:3.15

ARG VAULT_VERSION=1.9.1
ARG ROOT_CA_CERTIFICATE_URL

RUN addgroup vault && \
    adduser -S -G vault vault

RUN set -eux; \
    apk add --no-cache ca-certificates gnupg openssl libcap su-exec dumb-init tzdata && \
    wget -O /usr/local/share/ca-certificates/gcp-private-ca.crt ${ROOT_CA_CERTIFICATE_URL} && \
    update-ca-certificates && \
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
    armhf) ARCH='arm' ;; \
    aarch64) ARCH='arm64' ;; \
    x86_64) ARCH='amd64' ;; \
    x86) ARCH='386' ;; \
    *) echo >&2 "error: unsupported architecture: $apkArch"; exit 1 ;; \
    esac && \
    VAULT_GPGKEY=C874011F0AB405110D02105534365D9472D7468F; \
    found=''; \
    for server in \
    hkp://keyserver.ubuntu.com:80 \
    hkp://p80.pool.sks-keyservers.net:80 \
    hkp://pgp.mit.edu:80 \
    ; do \
    echo "Fetching GPG key $VAULT_GPGKEY from $server"; \
    gpg --batch --keyserver "$server" --recv-keys "$VAULT_GPGKEY" && found=yes && break; \
    done; \
    test -z "$found" && echo >&2 "error: failed to fetch GPG key $VAULT_GPGKEY" && exit 1; \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${ARCH}.zip && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS.sig && \
    gpg --batch --verify vault_${VAULT_VERSION}_SHA256SUMS.sig vault_${VAULT_VERSION}_SHA256SUMS && \
    grep vault_${VAULT_VERSION}_linux_${ARCH}.zip vault_${VAULT_VERSION}_SHA256SUMS | sha256sum -c && \
    unzip -d /tmp/build vault_${VAULT_VERSION}_linux_${ARCH}.zip && \
    cp /tmp/build/vault /bin/vault && \
    if [ -f /tmp/build/EULA.txt ]; then mkdir -p /usr/share/doc/vault; mv /tmp/build/EULA.txt /usr/share/doc/vault/EULA.txt; fi && \
    if [ -f /tmp/build/TermsOfEvaluation.txt ]; then mkdir -p /usr/share/doc/vault; mv /tmp/build/TermsOfEvaluation.txt /usr/share/doc/vault/TermsOfEvaluation.txt; fi && \
    cd /tmp && \
    rm -rf /tmp/build && \
    gpgconf --kill dirmngr && \
    gpgconf --kill gpg-agent && \
    apk del gnupg openssl && \
    rm -rf /root/.gnupg

RUN mkdir -p /vault/logs && \
    mkdir -p /vault/file && \
    mkdir -p /vault/config && \
    mkdir -p /vault/userconfig && \
    mkdir -p /vault/data

RUN chown -R vault:vault /vault

VOLUME /vault/logs
VOLUME /vault/file
VOLUME /vault/config
VOLUME /vault/userconfig
VOLUME /vault/data

EXPOSE 8200/tcp
EXPOSE 8201/tcp

USER vault:vault

ENTRYPOINT ["/usr/bin/dumb-init", "/bin/vault", "server", "-config", "/vault/config/server.hcl"]
