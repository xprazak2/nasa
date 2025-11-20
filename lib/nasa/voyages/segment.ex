defmodule Nasa.Voyages.Segment do
  use Nasa.Constants
  import Ecto.Changeset
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "segments" do
    field :launch_planet, :string
    field :landing_planet, :string
    field :launch_fuel, :integer
    field :landing_fuel, :integer
  end

  def changeset(segment, attrs) do
    segment
    |> cast(attrs, [:id, :launch_planet, :landing_planet, :launch_fuel, :landing_fuel])
    |> validate_inclusion(:launch_planet, @planets)
    |> validate_inclusion(:landing_planet, @planets)
  end

  def to_map(segment) do
    %{
      "launch_planet" => segment.launch_planet,
      "landing_planet" => segment.landing_planet,
      "launch_fuel" => segment.launch_fuel,
      "landing_fuel" => segment.landing_fuel,
      "id" => segment.id
    }
  end

  def to_maps(segments) do
    segments |> Enum.map(&to_map/1)
  end

  def from_struct(struct) do
    %__MODULE__{
      id: struct[:id],
      launch_planet: struct[:launch_planet],
      landing_planet: struct[:landing_planet],
      launch_fuel: struct[:launch_fuel] || 0,
      landing_fuel: struct[:landing_fuel] || 0
    }
  end

  def default() do
    %__MODULE__{
      id: Ecto.UUID.generate(),
      launch_planet: @earth,
      landing_planet: @earth,
      launch_fuel: 0,
      landing_fuel: 0
    }
  end
end
