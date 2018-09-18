defmodule Golux.Scene.GameOfLife do
  use Scenic.Scene
  alias Scenic.Graph

  @viewport Application.get_env(:golux, :viewport)
  @cell_size 10
  @width elem(@viewport.size, 0)
  @height elem(@viewport.size, 1)

  def init(_, _opts) do
    world = Golex.random_world(div(@width, @cell_size), div(@height, @cell_size))

    Graph.build()
    |> world_graph(world)
    |> build_grid({@width, @height}, @cell_size)
    |> push_graph()

    {:ok, timer} = :timer.send_interval(500, :world_tick)

    state = %{world: world, timer: timer}
    {:ok, state}
  end

  def filter_event(event, _, state) do
    IO.inspect(binding(), label: "filter_event")

    {:continue, event, state}
  end

  def handle_info(:world_tick, state) do
    {took, ret} =
      :timer.tc(fn ->
        new_world = Golex.world_tick(state.world)

        Graph.build()
        |> world_graph(new_world)
        |> build_grid({@width, @height}, @cell_size)
        |> push_graph()

        new_world
      end)

    IO.puts("World update + render: #{took / 1_000_000}s")

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

  def cell_graph(graph, %Golex.Cell{position: {x, y}, alive: living?}) do
    case living? do
      true ->
        xp = x * @cell_size
        yp = y * @cell_size

        graph
        |> Scenic.Primitives.quad(
          {{xp, yp}, {xp, yp + @cell_size}, {xp + @cell_size, yp + @cell_size}, {xp + @cell_size, yp}},
          fill: :white,
          id: "quad_#{x}_#{y}"
        )

      false ->
        graph
    end
  end
end
