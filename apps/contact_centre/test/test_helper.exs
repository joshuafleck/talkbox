Logger.remove_backend(:console)
ExUnit.start
Application.stop(:contact_centre)
Application.start(:contact_centre)
