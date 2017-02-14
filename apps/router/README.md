# Router

Handlers for [events](../events). Runs a pool of consumer processes that pull events from the event queue and delegate to the [telephony](../telephony) or [ui](../ui) applications.

## Interesting bits

- **[Consumer](lib/router/consumer.ex)** This pulls events off of the event queue and processes them. It runs in an infinite loop (with tail recursion)
- **[Router](lib/router.ex)** For each type of event, defines a handler which delegates to the [telephony](../telephony) or [ui](../ui) applications.

