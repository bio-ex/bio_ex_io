defmodule TestFile do
  @base_path "./test/files/"

  def get(name) do
    @base_path
    |> Path.join(name)
  end

  def read(name) do
    get(name)
    |> File.read()
  end
end
