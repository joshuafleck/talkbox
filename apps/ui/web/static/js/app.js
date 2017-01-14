// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"

var node = document.getElementById('elm-main');
var app = Elm.App.embed(node, {
    clientName: window.location.search.split('client_name=')[1]
});

app.ports.setup.subscribe(function(token) {

  /* Create the Client with a Capability Token */
  Twilio.Device.setup(token, {debug: true, closeProtection: false});

  /* Let us know when the client is ready. */
  Twilio.Device.ready(function (device) {
    app.ports.statusChanged.send("Ready");
  });

  /* Report any errors on the screen */
  Twilio.Device.error(function (error) {
    app.ports.statusChanged.send("Error: " + error.message);
  });

  Twilio.Device.connect(function (conn) {
    app.ports.statusChanged.send("Connected");
  });

  Twilio.Device.offline(function () {
    app.ports.statusChanged.send("Offline");
  });

  /* Log a message when a call disconnects. */
  Twilio.Device.disconnect(function (conn) {
    app.ports.statusChanged.send("Disconnected");
  });

  /* Listen for incoming connections */
  Twilio.Device.incoming(function (conn) {
    app.ports.statusChanged.send("Incoming connection from " + conn.parameters.From);
    // accept the incoming connection and start two-way audio
    conn.accept();
  });
});

