defmodule CatchCake.StateMachineTest do
  use ExUnit.Case
  doctest CatchCake.StateMachine

  test "greets the world" do
    assert CatchCake.StateMachine.hello() == :world
  end
end
