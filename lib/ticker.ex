defmodule Ticker do
  use Timex
  use GenServer
  require Logger

  @tick_interval 500

  defmodule Timer do
    use Timex
    @derive [Poison.Encoder]
    defstruct id: nil,
    enabled: true,
    created: DateTime.now,
    during: true,
    during_start: DateTime.now,
    during_end: Timex.shift(DateTime.now, weeks: 1),
    interval: [],
    target: DateTime.zero,
    times: 0,
    last: DateTime.now,
    actions: [],
    fired: false,
    name: "Unnamed Timer"
    use ExConstructor
  end

  def state() do
    GenServer.call(__MODULE__, {:state})
  end

  def create(%{} = data) do
    GenServer.call(__MODULE__, {:create_timer, data})
  end

  def get(id) do
    GenServer.call(__MODULE__, {:get_timer, id})
  end

  def set(id, %{} = data) do
    GenServer.call(__MODULE__, {:set_timer, id, data})
  end

  def start_link do
    GenServer.start_link __MODULE__, :ok, name: __MODULE__
  end

  def init(_) do
    Logger.info "Starting #{__MODULE__}"
    Process.send_after(__MODULE__, {:tick}, @tick_interval)
    {:ok, []}
  end

  def handle_info({:tick}, state) do
    Process.send_after(__MODULE__, {:tick}, @tick_interval)
    {:noreply, tick(state)}
  end

  def handle_call({:state}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get_timer, id}, _from, state) do
    {:reply, get_timer(state, id), state}
  end

  def handle_call({:set_timer, id, %{} = data}, _from, state) do
    {:reply, :ok, set_timer(state, id, data)}
  end

  def handle_call({:create_timer, %{} = data}, _from, state) do
    {:reply, :ok, create_timer(state, data)}
  end

  defp tick(state) do
    state |> Enum.map(&tick_timer(&1))
  end

  defp tick_timer(%Timer{} = timer) do
    case {during?(timer), fire?(timer)} do
      {true, true} ->
        Enum.map(timer.actions, &(&1.()))
        put_in(put_in(put_in(timer.fired, true).last, DateTime.now).times, timer.times+1)
      {_, _} -> timer
    end
  end


  defp create_timer(state, %{} = data) do
    new_id = state |> get_ids |> get_highest
    List.insert_at(state, -1, struct(Timer, Map.merge(data, %{id: new_id})))
  end

  defp get_timer(state, id) do
    List.first(Enum.filter(state, fn x -> x.id == id end))
  end

  defp set_timer(state, id, %{} = data) do
    Enum.map(state, fn x -> if x.id == id do
      Map.merge(x, data)
    else
      x
      end
    end)
  end

  defp get_ids(list) do
    Enum.map(list, fn x -> x.id end)
  end

  defp get_highest(list) do
    case list do
      [] -> 0
      ids -> ids |> Enum.max |> Kernel.+(1)
    end
  end

  defp during?(%Timer{} = timer) do
    case {timer.during, timer.enabled} do
      {_, false} -> false
      {false, true} -> true
      {true, true} -> Timex.after?(DateTime.now, timer.during_start) && Timex.before?(DateTime.now, timer.during_end)
    end
  end

  defp fire?(%Timer{} = timer) do
    case {timer.interval, timer.enabled} do
      {[], true} ->(Timex.after?(DateTime.now, timer.target) || Timex.equal?(DateTime.now, timer.target)) && !timer.fired
      {interval, true} -> Timex.after?(DateTime.now, Timex.shift(timer.last, interval)) || Timex.equal?(DateTime.now, Timex.shift(timer.last, interval))
      {_, _} -> false
    end
  end
end
