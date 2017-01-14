defmodule Callbacks.Twiml do
  import ExTwiml

  def join_conference(conference_identifier) do
    twiml do
      dial do
        conference conference_identifier
      end
    end
  end
end
