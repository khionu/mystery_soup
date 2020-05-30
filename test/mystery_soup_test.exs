defmodule MysterySoupTest do
  use ExUnit.Case
  doctest MysterySoup

  test "greets the world" do
    assert MysterySoup.hello() == :world
  end
end
