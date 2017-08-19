FROM elixir:1.5.1 as builder

WORKDIR /app

ARG TWILIO_AUTH_TOKEN
ARG TWILIO_ACCOUNT_SID
ARG SECRET_KEY_BASE
ARG COOKIE
ARG TELEPHONY_CLI
ARG TELEPHONY_WEBHOOK_URL

ENV TWILIO_AUTH_TOKEN=${TWILIO_AUTH_TOKEN} \
    TWILIO_ACCOUNT_SID=${TWILIO_ACCOUNT_SID} \
    SECRET_KEY_BASE=${SECRET_KEY_BASE} \
    COOKIE=${COOKIE} \
    TELEPHONY_CLI=${TELEPHONY_CLI} \
    TELEPHONY_WEBHOOK_URL=${TELEPHONY_WEBHOOK_URL} \
    MIX_ENV=prod

COPY . .

RUN mix local.hex --force && \
    mix local.rebar --force

RUN mix do deps.get, deps.compile, package

FROM elixir:1.5.1-slim as release

WORKDIR /root

COPY --from=builder /app/_build .

EXPOSE 4000 5000

CMD ["prod/rel/talkbox/bin/talkbox", "foreground"]
