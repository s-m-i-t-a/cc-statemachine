defmodule CatchCake.StateMachine do
  @moduledoc false

  require Logger

  def new(state_machine, id, context \\ %{}) do
    handle_event(
      %{
        context: context,
        id: id,
        machine: state_machine,
        state: :start
      },
      :init
    )
  end

  def handle_event(machine, event) do
    %{next: state, action: action} = machine.machine[machine.state][event]

    machine
    |> update_state(state)
    |> call_action(action)
    |> stop_or_continue()
  end

  defp update_state(machine, new_state) do
    Logger.debug(fn ->
      "[#{inspect(__MODULE__)}(#{to_string(machine.id)})] Moving #{machine.state} -> #{new_state}..."
    end)

    Map.put(machine, :state, new_state)
  end

  defp update_context(machine, new_context) when is_map(new_context),
    do: Map.put(machine, :context, new_context)

  defp call_action(%{context: context} = machine, action) do
    case action.(context) do
      {event, context} ->
        {:continue, event, update_context(machine, context)}

      context ->
        {:stop, update_context(machine, context)}
    end
  end

  defp stop_or_continue({:stop, machine}), do: machine
  defp stop_or_continue({:continue, event, machine}), do: handle_event(machine, event)
end
