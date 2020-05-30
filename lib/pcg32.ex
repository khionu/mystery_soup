defmodule MysterySoup.PCG32 do
  @moduledoc """
  Documentation for `MysterySoup`'s PCG32 implementation.
  """

  defstruct [:state, :inc]

  use MysterySoup.PCG32.Nif

  @doc """
  Initializes a new PCG32 state.
  """
  def init do
    Nif.init()
  end

  @doc """
  Generates a random unsigned 32-bit integer. 
  
  This function is used as the basis for the rest of 
  the operations in this module.
  """
  def gen(pcg, :raw), do: Nif.next(pcg)

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
    {rem(next, max) + 1, pcg}
  end

  @doc """
  Generates a number between `low` and `high`, exclusive.
  """
  def gen(pcg, {:range, low, high}) do
    {next, pcg} = gen(pcg, {:zero_to, high - low})
    {next + low, pcg}
  end
end
