defmodule MysterySoup.PCG32 do
  @moduledoc """
  Documentation for `MysterySoup`'s PCG32 implementation.
  """

  defstruct [:state, :inc]

  alias MysterySoup.PCG32.Nif

  @doc """
  Initializes a new PCG32 state.
  """
  def init do
    Nif.init_state()
  end

  @doc """
  Generates a random unsigned 32-bit integer. 
  
  This function is used as the basis for the rest of 
  the operations in this module.
  """
  def gen(pcg), do: Nif.next(pcg)

  @doc """
  Generates a number between 0 and 1.
  """
  def gen(pcg, :decimal) do
    {next, pcg} = gen(pcg)
    {1 / next, pcg}
  end

  @doc """
  Generates a value between 1 and `sides`, akin to 
  rolling a die with sides equal to `sides`.
  """
  def gen(pcg, {:die, sides}) do 
    {next, pcg} = gen(pcg)
    {rem(next, sides) + 1, pcg}
  end

  @doc """
  Generates a number between `low` and `high`, exclusive.
  """
  def gen(pcg, {:range, low, high}) do
    {next, pcg} = gen(pcg, {:zero_to, high - low})
    {next + low, pcg}
  end

  @doc """
  Picks `n` options from `set`.
  """
  def gen(pcg, {:pick_n, n, set}) when is_list(set) do
    if Enum.empty?(set), do: raise(ArgumentError, message: "Argument `set` must be a non empty Enumerable.")

    gen_pick_n_loop(pcg, {false, n, set})
  end

  @doc """
  Picks `n` _unique_ options from `set`.
  """
  def gen(pcg, {:pick_n_unique, n, set}) when is_list(set) do
    if Enum.empty?(set), do: raise(ArgumentError, message: "Argument `set` must be a non empty Enumerable.")

    gen_pick_n_loop(pcg, {true, n, set})
  end

  # Common logic for pick of set functions
  defp gen_pick_n_loop(pcg, {remove, n, set}, out \\ []) do
    # Next random
    {next, pcg} = gen(pcg)
    # The remainder of the random number divided by 
    # the length produces a valid index.
    index = rem(next, Enum.count(set))
    # Add the element to the out list
    out = [out | Enum.at(set, index)]

    # If we're removing used values, remove it
    set = case remove do
      true  -> List.delete_at(set, index)
      false -> set
    end

    n = n - 1
    if n != 0 do
      gen_pick_n_loop(pcg, {remove, n, set}, out)
    else
      {pcg, out}
    end
  end
end
