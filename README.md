# Ticker

**Simple library for time-based task execution.**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `ticker` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ticker, github: "mattneel/ticker"}]
    end
    ```

  2. Ensure `ticker` is started before your application:

    ```elixir
    def application do
      [applications: [:ticker]]
    end
    ```
3. Add `ticker` to your Supervision tree or start it yourself with `start_link/0`:
  ```elixir
    {:ok, pid} = Ticker.start_link
  ```
