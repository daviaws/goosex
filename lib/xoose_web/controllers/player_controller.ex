defmodule XooseWeb.PlayerController do
  use XooseWeb, :controller

  def index(conn, _params) do
    {players, _dead} = Xoose.Game.Player.players()

    json(
      conn,
      Enum.map(players, fn {_node, player} ->
        player
        |> Map.from_struct()
        |> Map.update!(:pid, &inspect(&1))
      end)
    )
  end

  def show(conn, _params) do
    json(
      conn,
      Xoose.Game.Player.player(Node.self())
      |> Map.from_struct()
      |> Map.update!(:pid, &inspect(&1))
    )
  end
end
