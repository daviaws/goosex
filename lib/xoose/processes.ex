defmodule Xoose.Processes do
  @moduledoc """
  Tools for working with processes
  """

  @doc """
    processes only communicate sending and receiving messages

    we create an async process to request and receive the answer

    usage example:
      iex(1)> Process.request(pid, :player) |> Task.await()
        %Player{id: 1, type: :duck, pid: #PID<0.707.0>}

      iex(2)> Enum.map(pids, & request(&1, :player)) |> Task.await_many()
        [
          %Player{id: 1, type: :duck, pid: #PID<0.707.0>},
          %Player{id: 2, type: :duck, pid: #PID<0.708.0>},
          %Player{id: 3, type: :duck, pid: #PID<0.709.0>},
          %Player{id: 4, type: :duck, pid: #PID<0.710.0>},
          %Player{id: 5, type: :duck, pid: #PID<0.711.0>}
        ]

    the advantage of the second case
    is that requests are made async before waiting all answers
  """

  require Logger

  def request(pid, message, timeout \\ 5_000) do
    Task.async(fn ->
      # Logger.error("#{inspect(self())} asking #{inspect(message)}")
      send(pid, {message, self()})

      receive do
        answer ->
          # Logger.error("#{inspect(self())} receiving answer #{inspect(answer)}")
          answer
      after
        # Timeout in milliseconds
        timeout -> :timeout
      end
    end)
  end
end
