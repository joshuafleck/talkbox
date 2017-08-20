FROM elixir:1.5.1 as builder

WORKDIR /app

ARG COOKIE

ENV COOKIE=${COOKIE} \
    MIX_ENV=prod

COPY . .

RUN mix local.hex --force && \
    mix local.rebar --force

RUN mix do deps.get, deps.compile, package

FROM elixir:1.5.1-slim as release

WORKDIR /root

COPY --from=builder /app/_build .

EXPOSE 4000 5000

ENV MIX_ENV=prod

CMD ["prod/rel/talkbox/bin/talkbox", "foreground"]
