defmodule Xoose.Player do
  @moduledoc """
  Representation of players process in the cluster
    as a Process
  """

  require Logger

  alias Xoose.Processes

  @type type() :: :xooser | :goose | :duck

  defstruct [:id, :type, :pid, :game_pid]

  def spawn_link(id) do
    Kernel.spawn_link(fn -> init(id) end)
  end

  defp init(id) do
    Logger.debug("[Xoose.Player] init #{id}")
    loop(%__MODULE__{id: id, type: :duck, pid: self()})
  end

  # Function representing the main loop for each player
  defp loop(player) do
    receive do
      # Message to get player current struct
      {{:player, game_pid}, answer_pid} ->
        # IO.puts("[Xoose.Player] player #{player.id} #{inspect(player.pid)} asked by #{inspect(game_pid)}")
        send(answer_pid, player)
        loop(%{player | game_pid: game_pid})

      # Message to assign duck
      {:assign, :duck} ->
        loop(%{player | type: :duck})

      # Message to assign xooser
      {:assign, :xooser} ->
        players = Processes.request(player.game_pid, {:players, self()}) |> Task.await()
        assigned_as_xooser(player, players)
        loop(%{player | type: :xooser})

      # Message to assign xooser
      {:assign, :goose, xooser_pid} ->
        assigned_as_goose(player, xooser_pid)
        loop(player)
    end
  end

  defp assigned_as_xooser(xooser, players) do
    goose = pick_goose(xooser, players)
    cpid = inspect(xooser.pid)
    Logger.warning("I'm #{cpid} assigned to be xooser")
    :timer.sleep(Enum.random(1000..2500))
    Logger.warning("I #{cpid} xoose #{inspect(goose.pid)} as goose")
    send(goose.pid, {:assign, :goose, xooser.pid})
  end

  defp pick_goose(xooser, players) do
    players
    |> Enum.reject(&(&1.id == xooser.id))
    |> Enum.random()
  end

  defp assigned_as_goose(goose, xooser_pid) do
    gpid = inspect(goose.pid)
    cpid = inspect(xooser_pid)

    Logger.warning(
      "I'm #{gpid} assigned to be goose and I'll try to catch #{cpid} before it scapes"
    )

    case Enum.random([:catch, :scaped]) do
      :catch ->
        Logger.warning("I #{gpid} was able to catch #{cpid} so I remain as a duck")
        send(self(), {:assign, :duck})
        send(xooser_pid, {:assign, :xooser})

      :scaped ->
        Logger.warning(
          "I #{cpid} was able to scape and become a duck, I #{gpid} will be the next xooser"
        )

        send(xooser_pid, {:assign, :duck})
        send(self(), {:assign, :xooser})
    end
  end
end
