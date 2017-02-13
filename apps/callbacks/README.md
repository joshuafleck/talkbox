# Callbacks

Accepts webhook requests from Twilio. Responds back with TwiML instructions and/or publishes [events](../events) to broadcast that call state in Twilio has changed.

## Interesting bits

- **[Routing](web/router.ex)** This controls the routing of requests
- **[Call controller](web/controllers/twilio/call_controller.ex)** Handles requests pertaining to call legs
- **[Conference controller](web/controllers/twilio/conference_controller.ex)** Handles requests pertaining to conferences
