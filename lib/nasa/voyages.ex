defmodule Nasa.Voyages do
  use Nasa.Constants

  alias Nasa.Voyages.Voyage
  alias Nasa.Voyages.Segment
  alias Nasa.Gravity

  def add(voyage) do
    new_segments = voyage.data.segments ++ [Segment.default()]
    segments_attrs = new_segments |> Segment.to_maps()

    voyage |> Voyage.changeset(%{"segments" => segments_attrs}) |> calculate()
  end

  def remove(voyage, id) do
    new_segments =
      voyage.data.segments |> Enum.filter(fn item -> item.id != id end)

    segments_attrs = new_segments |> Segment.to_maps()

    voyage |> Voyage.changeset(%{"segments" => segments_attrs}) |> calculate()
  end

  def calculate(changeset) do
    case changeset.changes do
      %{weight: _} -> recalculate_all(changeset)
      %{segments: _} -> recalculate_segments(changeset)
      _ -> changeset
    end
  end

  def recalculate_segments(changeset) do
    segments = changeset.data.segments
    changes = changeset.changes.segments
    weight = changeset.data.weight
    fuel = changeset.data.fuel

    %{segments: new_segments, fuel_diff: fuel_diff} = process_segments(segments, changes, weight)

    segments_attrs = new_segments |> Segment.to_maps()

    changeset |> Voyage.changeset(%{"segments" => segments_attrs, "fuel" => fuel + fuel_diff})
  end

  def process_segments(segments, changes, weight) do
    diff = %{segments: segments, fuel_diff: 0}

    diff
    |> process_segments_remove(changes)
    |> process_segments_update(changes, weight)
    |> process_segments_add(changes, weight)
  end

  def process_segments_add(diff, changes, weight) do
    add_changes = changes |> Enum.filter(fn change -> change.action == :insert end)

    if add_changes |> Enum.empty?() do
      diff
    else
      to_add =
        add_changes
        |> Enum.map(fn change ->
          process_segment(change, Segment.from_struct(change.changes), weight)
        end)

      to_add
      |> Enum.reduce(diff, fn item, memo ->
        %{segments: memo.segments ++ [item.segment], fuel_diff: memo.fuel_diff + item.fuel_diff}
      end)
    end
  end

  def process_segments_remove(diff, changes) do
    remove_changes = changes |> Enum.filter(fn change -> change.action == :replace end)

    if remove_changes |> Enum.empty?() do
      diff
    else
      Enum.reduce(remove_changes, diff, fn change, memo ->
        data = change.data
        filtered_segments = memo.segments |> Enum.filter(fn segment -> segment.id != data.id end)

        %{
          segments: filtered_segments,
          fuel_diff: memo.fuel_diff - (data.launch_fuel + data.landing_fuel)
        }
      end)
    end
  end

  def process_segments_update(diff, changes, weight) do
    %{segments: segments} = diff

    processed =
      segments
      |> Enum.map(fn item -> process_segment_update(item, changes, weight) end)

    reduced =
      processed
      |> Enum.reduce(%{segments: [], fuel_diff: 0}, fn item, memo ->
        %{segments: memo.segments ++ [item.segment], fuel_diff: memo.fuel_diff + item.fuel_diff}
      end)

    %{segments: reduced.segments, fuel_diff: diff.fuel_diff + reduced.fuel_diff}
  end

  def process_segment_update(segment, changes, weight) do
    change =
      changes
      |> Enum.find(fn item ->
        item.data.id == segment.id && item.action == :update && !Enum.empty?(item.changes)
      end)

    if change == nil do
      %{segment: segment, fuel_diff: 0}
    else
      process_segment(change, segment, weight)
    end
  end

  def process_segment(change, segment, weight) do
    new_launch_planet = change.changes[:launch_planet]
    new_landing_planet = change.changes[:landing_planet]

    new_segment =
      segment
      |> process_new_launch_planet(new_launch_planet, weight)
      |> process_new_landing_planet(new_landing_planet, weight)

    fuel_change =
      new_segment.launch_fuel + new_segment.landing_fuel -
        (segment.launch_fuel + segment.landing_fuel)

    %{segment: new_segment, fuel_diff: fuel_change}
  end

  def process_new_launch_planet(segment, nil, _) do
    segment
  end

  def process_new_launch_planet(segment, planet, weight) do
    launch_fuel =
      calculate_total_launch(weight, Gravity.for_planet(planet))

    %Segment{segment | launch_fuel: launch_fuel, launch_planet: planet}
  end

  def process_new_landing_planet(segment, nil, _) do
    segment
  end

  def process_new_landing_planet(segment, planet, weight) do
    landing_fuel =
      calculate_total_landing(weight, Gravity.for_planet(planet))

    %Segment{segment | landing_fuel: landing_fuel, landing_planet: planet}
  end

  def recalculate_all(changeset) do
    %{data: data, changes: %{weight: weight}} = changeset

    recalculated_segments =
      data.segments |> Enum.map(fn segment -> recalculate_segment(segment, weight) end)

    fuel = recalculated_segments |> sum_segments_fuel()

    segments_attrs = recalculated_segments |> Segment.to_maps()
    changeset |> Voyage.changeset(%{"segments" => segments_attrs, "fuel" => fuel})
  end

  def sum_segments_fuel(segments) do
    segments
    |> Enum.reduce(0, fn segment, memo -> memo + segment.launch_fuel + segment.landing_fuel end)
  end

  def recalculate_segment(segment, weight) do
    launch_fuel =
      calculate_total_launch(weight, Gravity.for_planet(segment.launch_planet))

    landing_fuel =
      calculate_total_landing(weight, Gravity.for_planet(segment.landing_planet))

    %Segment{segment | launch_fuel: launch_fuel, landing_fuel: landing_fuel}
  end

  def calculate_total_launch(mass, gravity) do
    res = calculate_launch(mass, gravity)

    if res > 0 do
      res + max(calculate_total_launch(res, gravity), 0)
    else
      res
    end
  end

  def calculate_total_landing(mass, gravity) do
    res = calculate_landing(mass, gravity)

    if res > 0 do
      res + calculate_total_landing(res, gravity)
    else
      res
    end
  end

  def calculate_launch(mass, gravity) do
    (mass * gravity * 0.042 - 33) |> Kernel.trunc() |> max(0)
  end

  def calculate_landing(mass, gravity) do
    (mass * gravity * 0.033 - 42) |> Kernel.trunc() |> max(0)
  end
end
