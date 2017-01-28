# Talkbox

Components

- **UI** Renders the UI used by the end-user. Sends and receives websocket events from the browser.
- **Callbacks** Webhook that accepts callbacks issued by Twilio
- **Telephony** Manages the core business logic for the system
- **Router** Accepts events produced by the components and routes them to other components

Competitive Advantages

- Resilient to UI crash (fetch from server at restart)
- Resilient to server crash (fetch from Twilio at restart)
- Rolling deploys (proposed Docker, Consul)
- Better performance (due to event-driven, Elixir, no DB)
- Fewer external dependencies (i.e. no Pusher, Mongo)
- More testable? (smaller, testable components)

Competitive Disadvantages

- Not tested in production
- Fewer features
- Unfamiliar languages
