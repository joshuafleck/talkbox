# Ui

Serves the single page web application. Translates websocket messages from the client into [events](../events). Provides an endpoint for other applications (i.e. [router](../router)) to send websocket messages back to the client.

## Interesting bits

- **[Single page application](web/elm/App.elm)** An Elm application that contains most of the logic for the UI.
- **[Application setup](web/static/js/app.js)** The Javascript used to initiate the SPA and connect the Twilio device.
- **[Page template](web/templates/page/index.html.eex)** The html template for the SPA (not much to see here).
