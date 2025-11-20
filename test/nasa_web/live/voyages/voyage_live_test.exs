defmodule NasaWeb.VoyageLiveTest do
  use NasaWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  use Nasa.Constants

  import Mox

  alias Nasa.Fixtures.VoyageFixtures

  describe "validate event" do
    test "update fuel on weight change", %{conn: conn} do
      segment_id = Ecto.UUID.generate()
      voyage = VoyageFixtures.weighted_voyage(1000, segment_id)

      Nasa.Voyages.VoyageMock
      |> stub(:default_changeset, fn ->
        voyage
      end)

      params = %{
        "weight" => "1500"
      }

      {:ok, view, _html} =
        live(conn, ~p"/")

      render_change(view, "validate", %{"voyage" => params})

      fuel_span = view |> element("#fuel") |> render()
      assert fuel_span =~ "1387"
    end

    test "detect invalid weight value", %{conn: conn} do
      segment_id = Ecto.UUID.generate()
      voyage = VoyageFixtures.weighted_voyage(1000, segment_id)

      Nasa.Voyages.VoyageMock
      |> stub(:default_changeset, fn ->
        voyage
      end)

      params = %{
        "weight" => "xyz"
      }

      {:ok, view, _html} =
        live(conn, ~p"/")

      render_change(view, "validate", %{"voyage" => params})

      fuel_span = view |> render()
      assert fuel_span =~ "is invalid"
    end

    test "update fuel on planet change", %{conn: conn} do
      segment_id = Ecto.UUID.generate()
      voyage = VoyageFixtures.weighted_voyage(1000, segment_id)

      Nasa.Voyages.VoyageMock
      |> stub(:default_changeset, fn ->
        voyage
      end)

      params = %{
        "segments" => %{
          "0" => %{
            "id" => segment_id,
            "landing_planet" => @moon,
            "launch_planet" => @earth
          }
        }
      }

      {:ok, view, _html} =
        live(conn, ~p"/")

      render_change(view, "validate", %{"voyage" => params})

      fuel_span = view |> element("#fuel") |> render()
      assert fuel_span =~ "528"
    end

    test "update fuel on segment add", %{conn: conn} do
      segment_id = Ecto.UUID.generate()
      voyage = VoyageFixtures.weighted_voyage(1000, segment_id)

      Nasa.Voyages.VoyageMock
      |> stub(:default_changeset, fn ->
        voyage
      end)

      {:ok, view, _html} =
        live(conn, ~p"/")

      render_change(view, "add", %{})

      fuel_span = view |> element("#fuel") |> render()
      assert fuel_span =~ "1692"
    end

    test "update fuel on segment remove", %{conn: conn} do
      voyage = VoyageFixtures.two_segments_voyage(1000)

      [segment | _] = voyage.data.segments

      Nasa.Voyages.VoyageMock
      |> stub(:default_changeset, fn ->
        voyage
      end)

      {:ok, view, _html} =
        live(conn, ~p"/")

      render_change(view, "remove", %{"id" => segment.id})

      fuel_span = view |> element("#fuel") |> render()
      assert fuel_span =~ "46"
    end
  end
end
