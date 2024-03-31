defmodule Xoose do
  @moduledoc """
  Xoose keeps the contexts that define our game domain
  and business logic.

    iex(1)> Xoose.start_local()
  """

  require Logger

  def start_local(players \\ 5) do
    Xoose.Game.Local.spawn_link(players)
  end

  def start_distributed() do
    Xoose.Game.Player.start()

    case Node.list() do
      [] ->
        Logger.debug("not reached minimun quorum of 2")

      nodes ->
        xooser = Enum.random([Node.self() | nodes])
        Logger.debug("[Xoose] #{inspect(xooser)}")
        Xoose.Game.Player.xooser(xooser)
    end
  end
end
