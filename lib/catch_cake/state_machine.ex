defmodule CatchCake.StateMachine do
  @moduledoc false

  require Logger

  @type state() :: atom() | binary()
  @type action() :: (context(), event() -> context() | {event(), context()})
  @type state_machine_definition() :: %{
          required(:start) => %{next: :init, action: action()},
          optional(state()) => %{next: state(), action: action()}
        }
  @type id() :: atom() | binary()
  @type context() :: any()
  @type event_type() :: atom() | binary()
  @type event() :: event_type() | {event_type(), any()}
  @type state_machine() :: %{
          context: context(),
          id: id(),
          machine: state_machine_definition(),
          state: state()
        }

  @spec new(state_machine_definition(), id(), context()) :: state_machine()
  def new(state_machine, id, context \\ %{}) do
    state_machine
    |> init_state(id, context)
    |> handle_event(:init)
  end

  @spec handle_event(state_machine, event()) :: state_machine()
  def handle_event(machine, event) do
    next_state = get_next_state(machine, event)
    action = get_action(machine, event)

    machine
    |> update_state(next_state)
    |> call_action(action, event)
    |> stop_or_continue()
  end

  defp get_next_state(machine, event) do
    machine.machine[machine.state][get_event_type(event)][:next]
  end

  defp get_action(machine, event) do
    machine.machine[machine.state][get_event_type(event)][:action]
  end

  defp get_event_type({event_type, _}), do: event_type
  defp get_event_type(event_type), do: event_type

  defp init_state(machine, id, context) do
    %{
      context: context,
      id: id,
      machine: machine,
      state: :start
    }
  end

  defp update_state(machine, new_state) do
    Logger.debug(fn ->
      "[#{inspect(__MODULE__)}(#{to_string(machine.id)})] Moving #{machine.state} -> #{new_state}..."
    end)

    Map.put(machine, :state, new_state)
  end

  defp update_context(machine, new_context) when is_map(new_context),
    do: Map.put(machine, :context, new_context)

  defp call_action(%{context: context} = machine, action, event) do
    case action.(context, event) do
      {event, context} ->
        {:continue, event, update_context(machine, context)}

      context ->
        {:stop, update_context(machine, context)}
    end
  end

  defp stop_or_continue({:stop, machine}), do: machine
  defp stop_or_continue({:continue, event, machine}), do: handle_event(machine, event)
end
