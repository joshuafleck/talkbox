# ContactCentre

A [Phoenix](http://www.phoenixframework.org/) application that serves the interface allowing the user to make and receive calls. Contains the core business logic for managing calls and conferences.

## Interesting bits

### Front end

- **[Single page application](lib/contact_centre/web/elm/App.elm)** An Elm application that contains most of the logic for the UI.
- **[Application setup](assets/js/app.js)** The Javascript used to initiate the SPA and connect the Twilio device.
- **[Page template](lib/contact_centre/web/templates/page/index.html.eex)** The html template for the SPA (not much to see here).
- **[Websocket channels](lib/contact_centre/web/channels)** This is where actions from the client-side are turned into events.

### Back end

- **[Event consumer](lib/contact_centre/consumer.ex)** Subscribes to events concerning conferencing and defines how each event is to be handled.
- **[Conferencing module](lib/contact_centre/conferencing.ex)** Where the business logic for managing conferencing lives. Each conference is represented as a process that is registered using the [Registry](https://hexdocs.pm/elixir/master/Registry.html).


