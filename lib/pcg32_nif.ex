defmodule MysterySoup.PCG32.Nif do
    use Rustler, otp_app: :mystery_soup

    def init_state, do: :erlang.nif_error(:nif_not_loaded)

    def next(state), do: :erlang.nif_error(:nif_not_loaded)
end