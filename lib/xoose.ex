defmodule Xoose do
  @moduledoc """
  Xoose keeps the contexts that define our game domain
  and business logic.

    iex(1)> Xoose.start_local()
  """

  def start_local(players \\ 5) do
    Xoose.Game.Local.spawn_link(players)
  end
end
