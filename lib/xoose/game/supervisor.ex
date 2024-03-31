defmodule Xoose.Game.Supervisor do
  @moduledoc """
  Game supervisor for distributed Games
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    # for starting local only game as a process
    # children = [
    #   %{
    #     id: Xoose.Game.Local,
    #     start: {Xoose.Game.Local, :start_link, [5]},
    #     type: :worker
    #   }
    # ]
    children = [{Xoose.Game.Player, 1}]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
