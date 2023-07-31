defmodule Testing.Tempfile do
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

defmodule BioIOFastaTest.Read do
  use ExUnit.Case

  alias Bio.IO.Fasta, as: Subject
  alias Bio.IO.Fasta
  alias Bio.Sequence.{DnaStrand, DnaDoubleStrand, AminoAcid}

  doctest Bio.IO.Fasta

  alias Bio.IO.Fasta, as: Subject

  setup do
    {tmp_dir, tmp_file} = Testing.Tempfile.get()

    on_exit(fn ->
      Testing.Tempfile.remove(tmp_dir)
    end)

    [tmp_file: tmp_file]
  end

  describe "from_binary/2" do
    test "allows injecting callable to massage header data" do
      {:ok, contents} = File.read("test/fasta/test_1.fasta")

      {:ok, fasta} =
        Subject.from_binary(contents,
          parse_header: fn h -> h |> String.replace("header", "face") end
        )

      assert fasta == [{"face1", "ataatatgatagtagatagatagtcctatga"}]
    end

    test "reads into default tuple" do
      {:ok, contents} = File.read('test/fasta/test_1.fasta')
      {:ok, fasta} = Subject.from_binary(contents)

      assert fasta == [{"header1", "ataatatgatagtagatagatagtcctatga"}]
    end

    test "reads into dna" do
      {:ok, contents} = File.read('test/fasta/test_1.fasta')
      {:ok, fasta} = Subject.from_binary(contents, type: DnaDoubleStrand)

      assert fasta == [
               Bio.Sequence.DnaDoubleStrand.new("ataatatgatagtagatagatagtcctatga",
                 label: "header1"
               )
             ]
    end
  end

  test "allows injecting callable to massage header data" do
    {:ok, content} =
      Subject.read('test/fasta/test_1.fasta',
        parse_header: fn h -> h |> String.replace("header", "face") end
      )

    assert content == [{"face1", "ataatatgatagtagatagatagtcctatga"}]
  end

  test "reads a file into default tuple" do
    {:ok, content} = Subject.read('test/fasta/test_1.fasta')

    assert content == [{"header1", "ataatatgatagtagatagatagtcctatga"}]
  end

  test "reads a file into dna" do
    {:ok, content} = Subject.read('test/fasta/test_1.fasta', type: DnaDoubleStrand)

    assert content == [
             Bio.Sequence.DnaDoubleStrand.new("ataatatgatagtagatagatagtcctatga", label: "header1")
           ]
  end

  test "reads a file into amino acid" do
    {:ok, content} = Subject.read('test/fasta/test_1.fasta', type: AminoAcid)

    assert content == [
             Bio.Sequence.AminoAcid.new("ataatatgatagtagatagatagtcctatga", label: "header1")
           ]
  end

  test "reads a multi-line file" do
    {:ok, content} = Subject.read('test/fasta/test_multi.fasta')

    assert content == [{"header1", "ataatatgatagtagatagatagtcctatga"}]
  end

  test "reads a multi-line file into dna" do
    {:ok, content} = Subject.read('test/fasta/test_multi.fasta', type: DnaDoubleStrand)

    assert content == [
             Bio.Sequence.DnaDoubleStrand.new("ataatatgatagtagatagatagtcctatga", label: "header1")
           ]
  end

  test "reads a multi-line file into amino acid" do
    {:ok, content} = Subject.read('test/fasta/test_multi.fasta', type: AminoAcid)

    assert content == [
             %Bio.Sequence.AminoAcid{
               sequence: "ataatatgatagtagatagatagtcctatga",
               length: 31,
               label: "header1"
             }
           ]
  end

  test "correctly read multiple sequences" do
    expected = [
      {"header1", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},
      {"header2", "ttttttttttttttttttttttttttttttt"},
      {"header3", "ggggggggggggggggggggggggggggggg"},
      {"header4", "ccccccccccccccccccccccccccccccc"},
      {"header5", "atgcatgcatgcatgcatgcatgcatgcatg"}
    ]

    {:ok, content} = Subject.read('test/fasta/test_5.fasta')

    assert content == expected
  end

  test "correctly read multiple sequences dna" do
    expected = [
      DnaDoubleStrand.new("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", label: "header1"),
      DnaDoubleStrand.new("ttttttttttttttttttttttttttttttt", label: "header2"),
      DnaDoubleStrand.new("ggggggggggggggggggggggggggggggg", label: "header3"),
      DnaDoubleStrand.new("ccccccccccccccccccccccccccccccc", label: "header4"),
      DnaDoubleStrand.new("atgcatgcatgcatgcatgcatgcatgcatg", label: "header5")
    ]

    {:ok, content} = Subject.read('test/fasta/test_5.fasta', type: DnaDoubleStrand)

    assert content == expected
  end

  test "correctly read multiple sequences amino acid" do
    expected = [
      AminoAcid.new("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", label: "header1"),
      AminoAcid.new("ttttttttttttttttttttttttttttttt", label: "header2"),
      AminoAcid.new("ggggggggggggggggggggggggggggggg", label: "header3"),
      AminoAcid.new("ccccccccccccccccccccccccccccccc", label: "header4"),
      AminoAcid.new("atgcatgcatgcatgcatgcatgcatgcatg", label: "header5")
    ]

    {:ok, content} = Subject.read('test/fasta/test_5.fasta', type: AminoAcid)

    assert content == expected
  end
end

defmodule BioIOFastaTest.Write do
  use ExUnit.Case

  alias Bio.IO.Fasta, as: Subject
  alias Bio.Sequence.DnaStrand

  setup do
    {tmp_dir, tmp_file} = Testing.Tempfile.get()

    on_exit(fn ->
      Testing.Tempfile.remove(tmp_dir)
    end)

    [tmp_file: tmp_file]
  end

  test "correctly writes sequences from list of tuples", context do
    input = [
      "header1",
      "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      "header2",
      "ttttttttttttttttttttttttttttttt",
      "header3",
      "ggggggggggggggggggggggggggggggg",
      "header4",
      "ccccccccccccccccccccccccccccccc",
      "header5",
      "atgcatgcatgcatgcatgcatgcatgcatg"
    ]

    expected = [
      {"header1", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},
      {"header2", "ttttttttttttttttttttttttttttttt"},
      {"header3", "ggggggggggggggggggggggggggggggg"},
      {"header4", "ccccccccccccccccccccccccccccccc"},
      {"header5", "atgcatgcatgcatgcatgcatgcatgcatg"}
    ]

    tmp = Map.get(context, :tmp_file)

    :ok = Subject.write(tmp, input)
    {:ok, re_read} = Subject.read(tmp)

    assert re_read == expected
  end

  test "correctly writes sequences from map with lists", context do
    input = %{
      headers: [
        "header1",
        "header2",
        "header3",
        "header4",
        "header5"
      ],
      sequences: [
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "ttttttttttttttttttttttttttttttt",
        "ggggggggggggggggggggggggggggggg",
        "ccccccccccccccccccccccccccccccc",
        "atgcatgcatgcatgcatgcatgcatgcatg"
      ]
    }

    expected = [
      {"header1", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},
      {"header2", "ttttttttttttttttttttttttttttttt"},
      {"header3", "ggggggggggggggggggggggggggggggg"},
      {"header4", "ccccccccccccccccccccccccccccccc"},
      {"header5", "atgcatgcatgcatgcatgcatgcatgcatg"}
    ]

    tmp = Map.get(context, :tmp_file)

    :ok = Subject.write(tmp, input)
    {:ok, re_read} = Subject.read(tmp)

    assert re_read == expected
  end

  # TODO: figure out if this makes sense
  test "correctly writes sequences from list", context do
    expected = [
      {"header1", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},
      {"header2", "ttttttttttttttttttttttttttttttt"},
      {"header3", "ggggggggggggggggggggggggggggggg"},
      {"header4", "ccccccccccccccccccccccccccccccc"},
      {"header5", "atgcatgcatgcatgcatgcatgcatgcatg"}
    ]

    tmp = Map.get(context, :tmp_file)

    Subject.write(tmp, expected)
    re_read = Subject.read!(tmp)

    assert re_read == expected
  end

  test "correctly writes sequences from list of dna", context do
    write_out = [
      DnaStrand.new("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", label: "header1"),
      DnaStrand.new("ttttttttttttttttttttttttttttttt", label: "header2"),
      DnaStrand.new("ggggggggggggggggggggggggggggggg", label: "header3"),
      DnaStrand.new("ccccccccccccccccccccccccccccccc", label: "header4"),
      DnaStrand.new("atgcatgcatgcatgcatgcatgcatgcatg", label: "header5")
    ]

    expected = [
      {"header1", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},
      {"header2", "ttttttttttttttttttttttttttttttt"},
      {"header3", "ggggggggggggggggggggggggggggggg"},
      {"header4", "ccccccccccccccccccccccccccccccc"},
      {"header5", "atgcatgcatgcatgcatgcatgcatgcatg"}
    ]

    tmp = Map.get(context, :tmp_file)

    Subject.write(tmp, write_out)
    re_read = Subject.read!(tmp)
    dna_read = Subject.read!(tmp, type: DnaStrand)

    assert re_read == expected
    assert dna_read == write_out
  end
end
