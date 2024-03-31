defmodule Xoose.Cluster.NodeListener do
  @moduledoc """
  A cluster membership manager.

  inspired on [Horde.NodeListener]
  Xoose.Cluster.NodeListener monitors nodes in BEAM's distribution system and
  automatically adds and removes those marked as `visible` from the cluster it's
  managing

  it's just monitoring up and downs on the node
  """
  use GenServer

  require Logger

  # API

  @spec start_link(atom()) :: GenServer.on_start()
  def start_link(cluster) do
    GenServer.start_link(__MODULE__, nodes(), name: listener_name(cluster))
  end

  # GenServer callbacks

  def init(cluster) do
    :net_kernel.monitor_nodes(true, node_type: :visible)
    {:ok, cluster}
  end

  def handle_cast(:initial_set, cluster) do
    Logger.debug("[Xoose.Cluster.NodeListener] initial_set #{cluster}")
    {:noreply, nodes()}
  end

  def handle_info({:nodeup, node, node_type}, cluster) do
    Logger.debug(
      "[Xoose.Cluster.NodeListener] nodeup #{node} #{inspect(node_type)} #{inspect(cluster)}"
    )

    {players, _dead} = Xoose.Game.Player.players()

    if started?(players) do
      Logger.debug("[Xoose.Cluster.NodeListener] starting players")
      Xoose.Game.Player.start()
      handle_quorum(cluster)
    end

    {:noreply, nodes()}
  end

  def handle_info({:nodedown, node, node_type}, cluster) do
    Logger.debug(
      "[Xoose.Cluster.NodeListener] nodedown #{node} #{inspect(node_type)} #{inspect(cluster)}"
    )

    :timer.sleep(1000)
    handle_quorum(cluster)
    {:noreply, nodes()}
  end

  def handle_info(_, cluster), do: {:noreply, cluster}

  defp handle_quorum(cluster) do
    cluster_size = length(cluster)
    quorum_size = cluster_size / 2
    {players, _dead} = Xoose.Game.Player.players()
    # time to stablish networking
    if length(players) >= quorum_size do
      Logger.error("[Xoose.Cluster.NodeListener] quorum up")

      if need_chooser?(players) do
        Logger.error("[Xoose.Cluster.NodeListener] need a new xooser")
        Xoose.start_distributed()
      end
    else
      Logger.error("[Xoose.Cluster.NodeListener] not reach quorum")
      Xoose.Game.Player.stop(Node.self(), :out_of_quorum)
    end
  end

  defp need_chooser?(players) do
    started?(players) && !find_chooser(players)
  end

  defp started?(players) do
    Enum.find(players, fn {_node, player} -> player.started == true end)
  end

  defp find_chooser(players) do
    Enum.find(players, fn {_node, player} -> player.type == :xooser end)
  end

  # Helper functions

  defp listener_name(cluster), do: Module.concat(cluster, NodeListener)

  defp nodes(), do: Node.list()
end
