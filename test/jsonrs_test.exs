defmodule JsonrsTest do
  use ExUnit.Case
  doctest Jsonrs

  defmodule Container do
    defstruct [:payload]
  end

  describe "encodes" do
    test "simple map" do
      assert Jsonrs.encode!(%{"foo" => 5}) == ~s({"foo":5})
      assert Jsonrs.encode!({:ok, :error}) == ~s(["ok","error"])
    end

    test "struct using fallback protocol" do
      assert Jsonrs.encode!(%Container{payload: ~T[12:00:00]}) == ~s({"payload":"12:00:00"})
    end

    test "nested types" do
      assert Jsonrs.encode!(%{a: [3, {URI.parse("http://foo.bar"), ~T[12:00:00]}]}) ==
               ~s({"a":[3,["http://foo.bar","12:00:00"]]})
    end

    test "prettily" do
      assert Jsonrs.encode!([1], pretty: 2) == "[\n  1\n]"
    end

    test "without custom protocols when lean" do
      assert "12:00:00" == Jsonrs.encode!(~T[12:00:00]) |> Jsonrs.decode!()

      assert %{"hour" => _, "minute" => _, "second" => _} =
               Jsonrs.encode!(~T[12:00:00], lean: true) |> Jsonrs.decode!()
    end

    test "with compress: :gzip" do
      assert zipped = Jsonrs.encode!(%{"foo" => 5}, compress: :gzip)
      assert :zlib.gunzip(zipped) == ~s({"foo":5})
    end

    test "with compress: {:gzip, level}" do
      for level <- 0..9 do
        assert zipped = Jsonrs.encode!(%{"Leslie" => "Pawnee"}, compress: {:gzip, level})
        assert :zlib.gunzip(zipped) == ~s({"Leslie":"Pawnee"})
      end
    end

    test "with compress: :zlib" do
      assert zipped = Jsonrs.encode!(%{"foo" => 5}, compress: :zlib)
      assert :zlib.uncompress(zipped) == ~s({"foo":5})
    end

    test "with compress: {:zlib, level}" do
      for level <- 0..9 do
        assert zipped = Jsonrs.encode!(%{"Leslie" => "Pawnee"}, compress: {:zlib, level})
        assert :zlib.uncompress(zipped) == ~s({"Leslie":"Pawnee"})
      end
    end

    test "with compress and pretty" do
      assert zipped = Jsonrs.encode!([1], compress: :gzip, pretty: 2)
      assert :zlib.gunzip(zipped) == "[\n  1\n]"
    end

    test "with compress: false/nil" do
      assert Jsonrs.encode!(%{ron: "swanson"}, compress: false) == ~S({"ron":"swanson"})
      assert Jsonrs.encode!(%{ron: "swanson"}, compress: nil) == ~S({"ron":"swanson"})
    end

    test "with invalid compress options" do
      assert_raise ArgumentError, "argument error", fn ->
        Jsonrs.encode!(%{foo: "bar"}, compress: :zlib)
      end

      assert_raise ArgumentError, "argument error", fn ->
        Jsonrs.encode!(%{foo: "bar"}, compress: "Wat?!?!")
      end

      assert_raise ArgumentError, "argument error", fn ->
        Jsonrs.encode!(%{foo: "bar"}, compress: {:gzip, "foo"})
      end
    end
  end

  describe "decodes" do
    test "simple map" do
      assert Jsonrs.decode!(~s({"foo":5})) == %{"foo" => 5}
    end
  end
end
