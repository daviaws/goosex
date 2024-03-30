defmodule Xoose.Game do
  @moduledoc """
  Abstraction for game process
    it is compatible for both local or distributed processes
  """

  require Logger

  alias Xoose.Processes

  @type types() :: :local | :distributed

  defstruct [:type, :pids, :players]

  @doc """
  Refresh player list
  """
  @spec refresh_players(%__MODULE__{}) :: %__MODULE__{}
  def refresh_players(game, skip_pid \\ nil) do
    Logger.debug("[Xoose.Game] refreshing players")

    players =
      Enum.map(game.pids, fn pid ->
        unless skip_pid == pid do
          Processes.request(pid, {:player, self()})
        end
      end)
      |> Enum.filter(& &1)
      |> Task.await_many()

    %{game | players: players}
  end

  @doc """
  Assign and trigger game role / action
  """
  @spec assign(%__MODULE__{}, :xooser) :: %__MODULE__{}
  def assign(%{players: []}, :xooser), do: throw("Restart game: nobody to assign")

  def assign(%{players: players} = game, :xooser) do
    xooser = Enum.find(players, &(&1.type == :xooser)) || Enum.random(players)
    Logger.debug("[Xoose.Game] assign xooser #{xooser.id} #{inspect(xooser.pid)}")

    if Process.alive?(xooser.pid) do
      send(xooser.pid, {:assign, :xooser})
    end

    game
  end

  @spec loop(%__MODULE__{}) :: nil
  def loop(game) do
    receive do
      {{:players, skip_pid}, sender_pid} ->
        refreshed_game = refresh_players(game, skip_pid)
        send(sender_pid, refreshed_game.players)
        loop(refreshed_game)
    end
  end

  @doc """
  Function to report nodes types
  """
  @spec report_types(%__MODULE__{}) :: %__MODULE__{}
  def report_types(%{players: players}) do
    players
    |> refresh_players()
    |> Enum.each(fn %{pid: pid, type: type} ->
      IO.puts("Node #{inspect(pid)} is a #{inspect(type)}")
    end)
  end
end
