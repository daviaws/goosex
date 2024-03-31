defmodule Xoose.Game.Player do
  @moduledoc """
  Representation of players in the cluster as GenServer
    for distributed games
  """

  use GenServer

  require Logger

  @type type() :: :xooser | :goose | :duck

  defstruct [:id, :started, :type, :pid]

  def start_link(id) do
    GenServer.start_link(__MODULE__, name(id), name: name(id))
  end

  def init(id) do
    Logger.debug("(#{Node.self()})[Xoose.Game.Player] init #{id}")
    Process.flag(:trap_exit, true)
    {:ok, %__MODULE__{id: id, started: false, type: :duck, pid: self()}}
  end

  def players() do
    GenServer.multi_call(name(1), :player)
  end

  def start() do
    GenServer.multi_call(name(1), :start)
  end

  def stop(node, reason, id \\ 1) do
    GenServer.stop({Xoose.Game.Player.name(id), node}, reason)
  end

  def xooser(node, id \\ 1) do
    basic_cast(node, {:assign, :xooser}, id)
  end

  def basic_cast(node, message, id \\ 1) do
    GenServer.cast({Xoose.Game.Player.name(id), node}, message)
  end

  # Callback invoked when the GenServer receives a call
  def handle_call(:player, _from, player) do
    {:reply, player, player}
  end

  def handle_call(:start, _from, player) do
    start = %{player | started: true}
    {:reply, start, start}
  end

  def handle_cast({:assign, :duck}, player) do
    {:noreply, %{player | type: :duck, started: true}}
  end

  def handle_cast({:assign, :xooser}, player) do
    picked_goose = Enum.random(Node.list())
    Logger.warning("I'm #{Node.self()} assigned to be xooser")
    :timer.sleep(Enum.random(1000..2500))
    Logger.warning("I #{Node.self()} xoose #{inspect(picked_goose)} as goose")
    basic_cast(picked_goose, {:assign, :goose, Node.self()})
    {:noreply, %{player | type: :xooser, started: true}}
  end

  def handle_cast({:assign, :goose, xooser_node}, player) do
    Logger.warning(
      "I'm #{Node.self()} assigned to be goose and I'll try to catch #{xooser_node} before it scapes"
    )

    case Enum.random([:catch, :scaped]) do
      :catch ->
        Logger.warning("I #{Node.self()} was able to catch #{xooser_node} so I remain as a duck")
        basic_cast(Node.self(), {:assign, :xooser})
        {:noreply, player}

      :scaped ->
        Logger.warning(
          "I #{xooser_node} was able to scape and become a duck, I #{Node.self()} will be the next xooser"
        )

        basic_cast(xooser_node, {:assign, :duck})
        basic_cast(Node.self(), {:assign, :xooser})
        {:noreply, %{player | started: true}}
    end
  end

  def terminate(reason, state) do
    IO.puts("Going Down: #{inspect(state)} because #{reason}")
    :normal
  end

  def name(id), do: Module.concat(__MODULE__, "#{id}")
end
