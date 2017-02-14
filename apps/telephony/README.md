# Telephony

Manages the core business logic for the system. Maintains its own version of the call state separate from Twilio.

## Interesting bits

- **[Telephony API](lib/telephony.ex)** These are the operations that can be peformed against a conference or call leg
- **[Conference state](lib/telephony/conference.ex)** This is where the conference state is maintained. It controls the allowed operations on the conference when it is in a given state. Stores the conferences in memory as a map of user -> conference.

