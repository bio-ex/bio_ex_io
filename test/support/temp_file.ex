defmodule Tempfile do
  def get() do
    filename =
      :crypto.strong_rand_bytes(10)
      |> Base.encode64(padding: false)
      |> String.replace("/", "")

    tmp_dir = System.tmp_dir!()

    file_path =
      tmp_dir
      |> Path.join(filename)

    {tmp_dir, file_path}
  end

  def remove(dir) do
    File.rm_rf(dir)
  end
end
