defmodule Goosex do
  @moduledoc """
  Goosex keeps the contexts that define our game domain
  and business logic.

    iex(1)> Goosex.start_local()
  """

  def start_local(players \\ 5) do
    Goosex.Game.Local.spawn_link(players)
  end
end
