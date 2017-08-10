# Telephony

Encapsulates the logic for communicating with the telephony provider. Makes API calls and accepts webhook requests from the telephony provider (also uses [Phoenix](http://www.phoenixframework.org/)).

## Interesting bits

- **[Routing](lib/telephony_web/router.ex)** This controls the routing of the webhook calls from the telephony provider
- **[Call controller](lib/telephony_web/controllers/twilio/call_controller.ex)** Handles webhook calls from Twilio pertaining to call legs and either publishes a corresponding event or returns a TwiML response.
- **[Conference controller](lib/telephony_web/controllers/twilio/conference_controller.ex)** Handles webhook calls from Twilio pertaining to conferences and publishes a corresponding event.
- **[Event consumer](lib/telephony/consumer.ex)** Subscribes to events concerning call state change and defines how each event is to be handled.

## TODO

- [ ] Assert validity of requests from telephony provider
- [ ] Introduce another telephony provider
