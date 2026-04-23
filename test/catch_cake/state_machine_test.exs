defmodule CatchCake.StateMachineTest do
  use ExUnit.Case
  doctest CatchCake.StateMachine

  alias CatchCake.StateMachine

  describe "new/2" do
    test "should move state from start to next state" do
      definition = %{
        start: %{init: %{next: :next, action: fn context, _event -> context end}},
        next: %{}
      }

      machine = StateMachine.new(definition, "test")

      assert machine.state == :next
    end

    test "should move state from start to next state and call action" do
      definition = %{
        start: %{
          init: %{
            next: :next,
            action: fn context, :init ->
              send(self(), :action_called)
              context
            end
          }
        },
        next: %{}
      }

      StateMachine.new(definition, "test")

      assert_received :action_called
    end

    test "should move state from start to next state without defined action" do
      definition = %{
        start: %{init: %{next: :next}},
        next: %{}
      }

      machine = StateMachine.new(definition, "test")

      assert machine.state == :next
    end
  end

  describe "new/3" do
    test "should set context" do
      definition = %{
        start: %{init: %{next: :next, action: fn context, _event -> context end}},
        next: %{}
      }

      machine = StateMachine.new(definition, "test", %{context: :context})

      assert machine.state == :next
      assert machine.context == %{context: :context}
    end
  end

  describe "handle_event/2" do
    test "should event with data is properly handled and passed to action" do
      definition = %{
        start: %{init: %{next: :next, action: fn context, _event -> context end}},
        next: %{
          ignite: %{
            next: :fire,
            action: fn context, {:ignite, data} -> Map.put(context, :data, data) end
          }
        },
        fire: %{}
      }

      machine =
        definition
        |> StateMachine.new("test")
        |> StateMachine.handle_event({:ignite, :test})

      assert machine.state == :fire
      assert machine.context == %{data: :test}
    end

    test "should self move to next state" do
      definition = %{
        start: %{init: %{next: :next, action: fn context, _event -> {:ignite, context} end}},
        next: %{
          ignite: %{
            next: :fire,
            action: fn context, _event -> context end
          }
        },
        fire: %{}
      }

      machine = StateMachine.new(definition, "test")

      assert machine.state == :fire
    end

    test "should move to next state without defined action" do
      definition = %{
        start: %{init: %{next: :next}},
        next: %{run: %{next: :running}},
        running: %{}
      }

      machine =
        definition
        |> StateMachine.new("test")
        |> StateMachine.handle_event(:run)

      assert machine.state == :running
    end
  end
end
