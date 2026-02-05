defmodule TaelBot.TaskSupervisor do
  def start_link(_args) do
    Task.Supervisor.start_link(name: __MODULE__)
  end

  def child_spec(_args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [[]]},
      type: :supervisor
    }
  end

  def start_child(fun) do
    Task.Supervisor.start_child(__MODULE__, fun)
  end
end
