defmodule MysterySoup.PCG32 do
  @moduledoc """
  Documentation for `MysterySoup`'s PCG32 implementation.
  """

  @type t :: __MODULE__

  defstruct [:state, :inc]

  alias MysterySoup.PCG32.Nif

  @doc """
  Initializes a new PCG32 state, seeding with system random.
  """
  def init do
    Nif.init_state()
  end

  @doc """
  Generates the next random unsigned 32-bit integer from the PCG32 state.
  """
  @spec next(MysterySoup.PCG32.t()) :: {integer(), MysterySoup.PCG32.t()}
  def next(pcg), do: Nif.next(pcg)

  @doc """
  Generates a float between 0 and 1. Consumes multiple `next/1` calls.

  # Notes
  This function will pull an indeterminate amount
  """
  @spec decimal(MysterySoup.PCG32.t()) :: {float(), MysterySoup.PCG32.t()}
  def decimal(pcg), do: Nif.next_float(pcg)

  @doc """
  Generates an integer between 1 and `sides`, as though rolling a die with as many sides.
  """
  @spec roll_die(MysterySoup.PCG32.t(), integer()) :: {integer(), MysterySoup.PCG32.t()}
  def roll_die(pcg, sides) do
    {next, pcg} = next(pcg)

    # Using the remainder will confine the value to a range between `sides - 1` and 0. This is off
    # by one, so we simply add 1 to it.
    val = rem(next, sides) + 1

    {val, pcg}
  end

  @doc """
  Generates an integer between `low` and `high`, inclusive.
  """
  @spec from_range(MysterySoup.PCG32.t(), integer(), integer()) :: {integer(), MysterySoup.PCG32.t()}
  def from_range(pcg, low, high) when high > low do
    {next, pcg} = next(pcg)

    # Similar to `roll_die/2`, this uses remainders to get a value from the range, then adjusts for
    # the offsets
    val = rem(next, (high - low)) + low + 1

    {val, pcg}
  end

  @doc """
  Picks `n` options from `set`.
  """
  @spec pick_n(MysterySoup.PCG32.t(), integer(), [any()]) :: [any()]
  def pick_n(_, n, set) when n == 0 or set == [], do: []
  def pick_n(pcg, n, set) when is_list(set) do
    gen_pick_n_loop(pcg, {false, n, set}, [])
  end

  @doc """
  Picks `n` _unique_ options from `set`.
  """
  @spec pick_n_uniq(MysterySoup.PCG32.t(), integer(), [any()]) :: [any()]
  def pick_n_uniq(_, n, set) when n == 0 or set == [], do: []
  def pick_n_uniq(pcg, n, set) when is_list(set) do
    gen_pick_n_loop(pcg, {false, n, set}, [])
  end

  # Common logic for pick of set functions
  defp gen_pick_n_loop(pcg, {remove, n, set}, out) when n != 0 do
    # Next random
    {next, pcg} = next(pcg)

    # The remainder of the random number divided by
    # the length produces a valid index.
    index = rem(next, Enum.count(set))

    # Add the element to the out list
    out = [out | Enum.at(set, index)]

    # If we're removing used values, remove it
    set = pop_if(remove, set, index)

    gen_pick_n_loop(pcg, {remove, n - 1, set}, out)
  end

  defp gen_pick_n_loop(pcg, {_, 0, _}, out), do: {pcg, out}

  defp pop_if(true, set, i), do: List.delete_at(set, i)
  defp pop_if(false, set, _), do: set
end
