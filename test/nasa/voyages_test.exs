defmodule Nasa.VoyagesTest do
  use ExUnit.Case

  use Nasa.Constants

  alias Nasa.Voyages
  alias Nasa.Gravity
  alias Nasa.Voyages.Voyage
  alias Nasa.Voyages.Segment

  alias Nasa.Fixtures.VoyageFixtures

  describe "voyages" do
    test "calculate_landing should calculate fuel for earth landing" do
      assert Voyages.calculate_landing(28801, Gravity.earth()) == 9278
    end

    test "calculate_launch should calculate fuel for earth launch" do
      assert Voyages.calculate_launch(28801, Gravity.earth()) == 11829
    end

    test "calculate_total_landing should calculate total fuel for earth landing" do
      assert Voyages.calculate_total_landing(28801, Gravity.earth()) == 13447
    end

    test "calculate_total_landing should not return negative values" do
      assert Voyages.calculate_total_landing(5, Gravity.earth()) == 0
    end

    test "calculate should recalculate when launch planet changes" do
      segment_id = Ecto.UUID.generate()
      changeset = VoyageFixtures.weighted_voyage(1000, segment_id)

      attrs = %{
        "segments" => %{
          "0" => %{
            "id" => segment_id,
            "landing_planet" => @earth,
            "launch_planet" => @moon
          }
        }
      }

      changed = changeset |> Voyage.changeset(attrs)
      res = changed |> Voyages.calculate()

      {:ok, data} = Ecto.Changeset.apply_action(res, :update)
      assert data.fuel == 364

      [segment | _] = data.segments
      assert segment.launch_planet == @moon
    end

    test "calculate should recalculate when landing planet changes" do
      segment_id = Ecto.UUID.generate()
      changeset = VoyageFixtures.weighted_voyage(1000, segment_id)

      attrs = %{
        "segments" => %{
          "0" => %{
            "id" => segment_id,
            "landing_planet" => @moon,
            "launch_planet" => @earth
          }
        }
      }

      changed = changeset |> Voyage.changeset(attrs)
      res = changed |> Voyages.calculate()

      {:ok, data} = Ecto.Changeset.apply_action(res, :update)
      assert data.fuel == 528

      [segment | _] = data.segments
      assert segment.landing_planet == @moon
    end

    test "calculate should recalculate when weight changes" do
      segment_id = Ecto.UUID.generate()
      changeset = VoyageFixtures.weighted_voyage(1000, segment_id)

      attrs = %{
        "weight" => 500
      }

      changed = changeset |> Voyage.changeset(attrs)
      res = changed |> Voyages.calculate()

      {:ok, data} = Ecto.Changeset.apply_action(res, :update)
      assert data.fuel == 328
    end

    test "calculate should recalculate when segment added" do
      segment_id = Ecto.UUID.generate()
      changeset = VoyageFixtures.weighted_voyage(1000, segment_id)

      segments_attrs =
        Segment.to_maps(changeset.data.segments) ++
          [
            %{
              "id" => "81367f20-768d-4626-9bd1-34b07bf518f7",
              "landing_fuel" => 0,
              "landing_planet" => @moon,
              "launch_fuel" => 0,
              "launch_planet" => @moon
            }
          ]

      res =
        changeset
        |> Voyage.changeset(%{"segments" => segments_attrs})
        |> Voyages.calculate()

      {:ok, data} = Ecto.Changeset.apply_action(res, :insert)
      assert data.fuel == 892

      assert Enum.count(data.segments) == 2
    end

    test "calculate should recalculate when segment removed" do
      changeset = VoyageFixtures.two_segments_voyage(1000)

      [_ | tail] = changeset.data.segments

      segments_attrs = tail |> Segment.to_maps()

      res =
        changeset
        |> Voyage.changeset(%{"segments" => segments_attrs})
        |> Voyages.calculate()

      {:ok, data} = Ecto.Changeset.apply_action(res, :replace)
      assert data.fuel == 46

      assert Enum.count(data.segments) == 1
    end
  end
end
