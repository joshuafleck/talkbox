# Events

Contains event definitions used to communicate between applications and facilitates publishing of events

## Interesting bits

- **[Events API](lib/events.ex)** Functions for publishing and subscribing to events
- **[Handler](lib/events/handler.ex)** Behaviour that consumers of events must implement for each type of event consumed
- **[Event specifications](lib/events)** The event structures are defined in the modules here
- **[PubSub registry](lib/events/registry.ex)** Uses the [Registry](https://hexdocs.pm/elixir/master/Registry.html#module-using-as-a-pubsub) in order to get a local PubSub.
