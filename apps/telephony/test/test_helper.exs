Logger.remove_backend(:console)
ExUnit.start
Application.stop(:telephony)
Application.start(:telephony)
