# Events

Contains event definitions used to communicate between applications and facilitates publishing of events

## Interesting bits

- **[Events API](lib/events.ex)** Functions for publishing and consuming events from the events queue
- **[Event queue](lib/events/queue.ex)** An in-memory FIFO queue on which events are queued until they are consumed
- **[Event specifications](lib/events)** The structure of the events are defined in the modules here
