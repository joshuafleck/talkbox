# Talkbox

A proof of concept in building browser-based telephony applications using functional programming languages. The back-end is implemented with [Elixir](http://elixir-lang.org/), the front-end implemented with [Elm](http://elm-lang.org/).

## Why?

- To improve my knowledge of functional programming.
- To learn what types of problems are more/less difficult to solve in the telephony domain using functional languages vs. object oriented languages.
- To gain more experience with event-driven architectures.

## What does it do?

- [x] Make a call from the browser
- [x] Receive a call from another browser
- [x] Make a conference call
- [ ] Receive a call from a telephone

## Design

This project serves as an [umbrella](https://elixirschool.com/lessons/advanced/umbrella-projects/) enclosing some smaller applications.

### Goals

- Small, loosely coupled components, each with a narrow set of responsibilities
- Components that can be tested in isolation

### Components

Each of these components is implemented as a child-project under the `/apps` directory. This was done to promote the abovementioned design goals. Communication between components is achieved by publishing and subscribing to events.

![Architecture](images/Talkbox.png)

- **[ContactCentre](apps/contact_centre)** A [Phoenix](http://www.phoenixframework.org/) application that serves the interface allowing the user to make and receive calls. Contains the core business logic for managing calls and conferences.
- **[Telephony](apps/telephony)** Encapsulates the logic for communicating with the telephony provider. Makes API calls and accepts webhook requests from the telephony provider (also uses [Phoenix](http://www.phoenixframework.org/)).
- **[Events](apps/events)** Contains event definitions used to communicate between applications and facilitates publishing of events

## Set up

1. Install dependencies

    ```
    brew bundle
    mix deps.get
    ```
    
1. Install Node packages

    ```
    # within the `apps/contact_centre/assets` directory:
    npm install
    ```

1. Set environment variables

    ```
    export TWILIO_ACCOUNT_SID=<account sid>
    export TWILIO_AUTH_TOKEN=<auth token>
    ```

1. Run the tests

    ```
    mix test
    ```

1. Start the applications

    ```
    iex -S mix phx.server
    ```

1. Open the application

    ```
    open http://localhost:5000/?client_name=yourname
    ```

## Proposed enhancements

- [ ] Resilience to client crash (fetch state from server at load)
- [ ] Resilience to server crash (fetch call state from Twilio at boot)
- [ ] Rolling deploys (proposing Docker with Consul)
