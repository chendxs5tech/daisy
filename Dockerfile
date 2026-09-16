# Custom PostgreSQL image for the "daisy" project.
# Base image already handles initdb, entrypoint and PGDATA permissions.
#
# Version is pinned to an exact patch release so every machine builds the same
# thing. Debian (bookworm) rather than Alpine: Alpine uses musl, which collates
# text differently, so ORDER BY on text columns and LIKE/ILIKE would give
# different results there.
FROM postgres:15.12-bookworm

# tzdata so TZ/PGTZ below actually resolve inside the container.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends tzdata; \
    rm -rf /var/lib/apt/lists/*

ENV TZ=Asia/Ho_Chi_Minh \
    PGTZ=Asia/Ho_Chi_Minh

# Scripts here are executed by the entrypoint in alphabetical order,
# but ONLY on the very first start (when PGDATA is empty).
COPY initdb/ /docker-entrypoint-initdb.d/

EXPOSE 5432
