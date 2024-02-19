defmodule BioIOFastqTest do
  use ExUnit.Case

  alias Bio.IO.FastQ, as: Subject
  alias Bio.QualityScore
  alias Bio.Sequence.DnaStrand

  doctest Bio.IO.FastQ

  test "reading with defaults" do
    expected = [
      {
        {"header1", "aatagatgatagtag"},
        QualityScore.new("FI?26E9+>=3$;)&", encoding: :phred_33)
      },
      {
        {"header2", "ggattaccagtgatgattgaa"},
        QualityScore.new("BA&\"!9:?8=EFH2#>+)064", encoding: :phred_33)
      }
    ]

    {:ok, content} = Subject.read(~c"test/files/fastq_1.fastq")

    assert content == expected
  end

  test "reading with type dna" do
    expected = [
      {
        DnaStrand.new("aatagatgatagtag", label: "header1"),
        QualityScore.new("FI?26E9+>=3$;)&", encoding: :phred_33)
      },
      {
        DnaStrand.new("ggattaccagtgatgattgaa", label: "header2"),
        QualityScore.new("BA&\"!9:?8=EFH2#>+)064", encoding: :phred_33)
      }
    ]

    {:ok, content} = Subject.read(~c"test/files/fastq_1.fastq", type: DnaStrand)

    assert content == expected
  end

  test "reading with Sequence type" do
    expected = [
      {
        Bio.Sequence.new("aatagatgatagtag", label: "header1"),
        QualityScore.new("FI?26E9+>=3$;)&", encoding: :phred_33)
      },
      {
        Bio.Sequence.new("ggattaccagtgatgattgaa", label: "header2"),
        QualityScore.new("BA&\"!9:?8=EFH2#>+)064", encoding: :phred_33)
      }
    ]

    {:ok, content} = Subject.read(~c"test/files/fastq_1.fastq", type: Bio.Sequence)

    assert content == expected
  end
end
