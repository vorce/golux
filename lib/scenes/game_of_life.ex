defmodule Golux.Scene.GameOfLife do
  use Scenic.Scene
  alias Scenic.Graph

  @viewport Application.get_env(:golux, :viewport)
  @cell_size 10
  @width elem(@viewport.size, 0)
  @height elem(@viewport.size, 1)

  def init(_, _opts) do
    world = Golex.random_world(div(@width, @cell_size), div(@height, @cell_size))

    render_game(world)

    timer_interval = 500
    {:ok, timer} = :timer.send_interval(timer_interval, :world_tick)

    state = %{world: world, timer: timer, timer_interval: timer_interval}
    {:ok, state}
  end

  def render_game(world) do
    Graph.build()
    |> world_graph(world)
    |> build_grid({@width, @height}, @cell_size)
    |> push_graph()
  end

  def handle_info(:world_tick, state) do
    {_took, ret} =
      :timer.tc(fn ->
        new_world = Golex.world_tick(state.world)
        render_game(new_world)
        new_world
      end)

    # IO.puts("#{took}")

    {:noreply, %{state | world: ret}}
  end

  def build_grid(graph, {width, height}, spacing) do
    horizontal =
      Enum.reduce(0..height, graph, fn y, acc ->
        acc
        |> Scenic.Primitives.line({{0, spacing * y}, {width, spacing * y}},
          stroke: {1, :white}
        )
      end)

    Enum.reduce(0..width, horizontal, fn x, acc ->
      acc
      |> Scenic.Primitives.line({{spacing * x, 0}, {spacing * x, height}},
        stroke: {1, :white}
      )
    end)
  end

  def world_graph(graph, %Golex.World{cells: cells}) do
    Enum.reduce(cells, graph, fn {_pos, cell}, acc ->
      cell_graph(acc, cell)
    end)
  end

  def cell_graph(graph, %Golex.Cell{alive: false}), do: graph
  def cell_graph(graph, %Golex.Cell{position: {x, y}, alive: true}) do
    xp = x * @cell_size
    yp = y * @cell_size

    Scenic.Primitives.rectangle(graph, {@cell_size, @cell_size}, fill: :white, translate: {xp, yp}, id: "rect_#{x}_#{y}")
  end

  def handle_input({:cursor_button, {:left, :release, _, _}}, _input_context, state) do
    IO.puts("Generating a new world")
    new_world = Golex.random_world(div(@width, @cell_size), div(@height, @cell_size))
    render_game(new_world)

    {:noreply, %{state | world: new_world}}
  end

  def handle_input({:key, {"right", :release, _}}, _input_context, state) do
    :timer.cancel(state.timer)
    new_interval = interval(state.timer_interval, -100)
    IO.puts("Setting update speed to: #{new_interval}")

    {:ok, new_timer} = :timer.send_interval(new_interval, :world_tick)

    {:noreply, %{state | timer: new_timer, timer_interval: new_interval}}
  end

  def handle_input({:key, {"left", :release, _}}, _input_context, state) do
    :timer.cancel(state.timer)
    new_interval = interval(state.timer_interval, 100)
    IO.puts("Setting update speed to: #{new_interval}")

    {:ok, new_timer} = :timer.send_interval(new_interval, :world_tick)

    {:noreply, %{state | timer: new_timer, timer_interval: new_interval}}
  end

  def handle_input(_msg, _, state) do
    # IO.inspect(msg, label: "handle_input")
    {:noreply, state}
  end

  def interval(current, modifier, min \\ 100, max \\ 10_000) do
    cond do
      current + modifier >= max ->
        max
      current + modifier <= min ->
        min
      true ->
        current + modifier
    end
  end
end
