defmodule Goosex.Game do
  @moduledoc """
  Abstraction for game process
    it is compatible for both local or distributed processes
  """

  require Logger

  alias Goosex.Processes

  @type types() :: :local | :distributed

  defstruct [:type, :pids, :players]

  @doc """
  Refresh player list
  """
  @spec refresh_players(%__MODULE__{}) :: %__MODULE__{}
  def refresh_players(game, skip_pid \\ nil) do
    Logger.debug("[Goosex.Game] refreshing players")

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
  @spec assign(%__MODULE__{}, :chooser) :: %__MODULE__{}
  def assign(%{players: []}, :chooser), do: throw("Restart game: nobody to assign")

  def assign(%{players: players} = game, :chooser) do
    chooser = Enum.find(players, &(&1.type == :chooser)) || Enum.random(players)
    Logger.debug("[Goosex.Game] assign chooser #{chooser.id} #{inspect(chooser.pid)}")

    if Process.alive?(chooser.pid) do
      send(chooser.pid, {:assign, :chooser})
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
