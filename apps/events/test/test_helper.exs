Logger.remove_backend(:console)
ExUnit.start()
Application.stop(:events)
Application.start(:events)
