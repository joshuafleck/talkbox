# Events

Contains event definitions used to communicate between applications and facilitates publishing of events

## Interesting bits

- **[Events API](lib/events.ex)** Functions for publishing and subscribing to events. Uses the [Registry](https://hexdocs.pm/elixir/master/Registry.html#module-using-as-a-pubsub) in order to get a local PubSub.
- **[Handler](lib/events/handler.ex)** A behaviour for consumers of events allowing consumers to subscribe to and define handlers for events.
- **[Event specifications](lib/events)** The event structures are defined in the modules here
