defmodule TaelBotTest do
  use ExUnit.Case
  doctest TaelBot

  test "greets the world" do
    assert TaelBot.hello() == :world
  end
end
