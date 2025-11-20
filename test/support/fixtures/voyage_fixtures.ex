defmodule Nasa.Fixtures.VoyageFixtures do
  use Nasa.Constants

  alias Nasa.Voyages
  alias Nasa.Voyages.Voyage
  alias Nasa.Voyages.Segment

  def weighted_voyage(weight, segment_id) do
    segment = %Segment{
      id: segment_id,
      launch_planet: @earth,
      landing_planet: @earth,
      launch_fuel: 0,
      landing_fuel: 0
    }

    segment = segment |> Voyages.recalculate_segment(weight)
    segments = [segment]
    fuel = segments |> Voyages.sum_segments_fuel()

    voyage = %Voyage{
      weight: weight,
      fuel: fuel,
      segments: segments
    }

    Voyage.changeset(voyage, %{})
  end

  def two_segments_voyage(weight) do
    segments = [
      %Segment{
        id: Ecto.UUID.generate(),
        launch_planet: @earth,
        landing_planet: @earth,
        launch_fuel: 0,
        landing_fuel: 0
      },
      %Segment{
        id: Ecto.UUID.generate(),
        launch_planet: @moon,
        landing_planet: @moon,
        launch_fuel: 0,
        landing_fuel: 0
      }
    ]

    segments =
      segments |> Enum.map(fn segment -> Voyages.recalculate_segment(segment, weight) end)

    fuel = segments |> Voyages.sum_segments_fuel()

    voyage = %Voyage{
      weight: weight,
      fuel: fuel,
      segments: segments
    }

    Voyage.changeset(voyage, %{})
  end
end
