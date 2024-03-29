defmodule Goosex.Player do
  @moduledoc """
  Representation of players process in the cluster
  """

  require Logger

  alias Goosex.Processes

  @type type() :: :chooser | :goose | :duck

  defstruct [:id, :type, :pid, :game_pid]

  def spawn_link(id) do
    Kernel.spawn_link(fn -> init(id) end)
  end

  defp init(id) do
    Logger.debug("[Goosex.Player] init #{id}")
    loop(%__MODULE__{id: id, type: :duck, pid: self()})
  end

  # Function representing the main loop for each player
  defp loop(player) do
    receive do
      # Message to get player current struct
      {{:player, game_pid}, answer_pid} ->
        # IO.puts("[Goosex.Player] player #{player.id} #{inspect(player.pid)} asked by #{inspect(game_pid)}")
        send(answer_pid, player)
        loop(%{player | game_pid: game_pid})

      # Message to assign duck
      {:assign, :duck} ->
        loop(%{player | type: :duck})

      # Message to assign chooser
      {:assign, :chooser} ->
        players = Processes.request(player.game_pid, {:players, self()}) |> Task.await()
        assigned_as_chooser(player, players)
        loop(%{player | type: :chooser})

      # Message to assign chooser
      {:assign, :goose, chooser_pid} ->
        assigned_as_goose(player, chooser_pid)
        loop(player)
    end
  end

  defp assigned_as_chooser(chooser, players) do
    goose = pick_goose(chooser, players)
    cpid = inspect(chooser.pid)
    Logger.warning("I'm #{cpid} assigned to be chooser")
    :timer.sleep(Enum.random(1000..2500))
    Logger.warning("I #{cpid} choose #{inspect(goose.pid)} as goose")
    send(goose.pid, {:assign, :goose, chooser.pid})
  end

  defp pick_goose(chooser, players) do
    players
    |> Enum.reject(&(&1.id == chooser.id))
    |> Enum.random()
  end

  defp assigned_as_goose(goose, chooser_pid) do
    gpid = inspect(goose.pid)
    cpid = inspect(chooser_pid)

    Logger.warning(
      "I'm #{gpid} assigned to be goose and I'll try to catch #{cpid} before it scapes"
    )

    case Enum.random([:catch, :scaped]) do
      :catch ->
        Logger.warning("I #{gpid} was able to catch #{cpid} so I remain as a duck")
        send(self(), {:assign, :duck})
        send(chooser_pid, {:assign, :chooser})

      :scaped ->
        Logger.warning(
          "I #{cpid} was able to scape and become a duck, I #{gpid} will be the next chooser"
        )

        send(chooser_pid, {:assign, :duck})
        send(self(), {:assign, :chooser})
    end
  end
end
