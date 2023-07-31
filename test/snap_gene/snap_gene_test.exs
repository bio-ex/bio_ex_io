defmodule IO.SnapGene.SnapGeneTest do
  use ExUnit.Case, async: true

  alias Bio.IO.SnapGene, as: Subject
  alias Bio.Sequence.DnaStrand
  alias Bio.IO.SnapGene
  alias Bio.XML

  doctest Subject

  describe "sample-d" do
    test "reading primary fields type DnaStrand" do
      dna =
        DnaStrand.new(
          "gcacactaagccttccatctattcggcttcttgctctgcaatgcctacccatagctgctggaagctaacgaggtaagtttcgcctgggatatgcgccccatagcacgtataacggtaactttctacgacctatcatctaactagaaatcacagtatacgaggaagctcgtcgaccatatggcacctaacggtagtggaaggcgccaatcacagatggttcactaacggtcttaagatcgaattacaatgctgtgaacttatagaggacgggagcaagcgtcgtccacccgcgtagggttagcgttaacacagtctttcagtcgttcgtctaggagaggaggctctttcacaaaacaaaccagatgtctttgggcacgttgaaattagcgggttgaggtgctctacgtccgacacctttgccagaggtgtaaaaagggattaccttaatcccgtgtgtgataccctgtagtacccacgacttaacaactagaggccggtgtataccagttacccgacaatgcaaatcgtattattgcggtagtatcgatcctccccgatgctcgatcttgtacagaagaaaagcccgaaaatttaatgaagcaaaataccctatctgcccaggaggatagaagccccatcaatgacttaaactccgacgattttacgggcggtctaccgctcacaggcaggtgaagacatcacatatgctccgtgtacgcatcggatccaagaaacttccgtccagctgtcataaacctggactttttgtatctggaggtgacttagccgatagcaacgaaatctcaattgagctggttctaaatctttcttttagacggagcatatgtgaagtagtaaaatcatctctaggttcacggaggtaatcgtcggtctgccaccctgactcggctattaggtggaggagcttttaagctctttacaacacctaagtctgcccatattatgcatggttttccgacacatttcctcctaatcgtag"
        )

      {:ok, result} = Subject.read("test/snap_gene/sample-d.dna", sequence_type: DnaStrand)

      refute result.circular?
      assert result.valid?
      assert result.sequence == dna
    end

    test "reading primary fields" do
      dna =
        {nil,
         "gcacactaagccttccatctattcggcttcttgctctgcaatgcctacccatagctgctggaagctaacgaggtaagtttcgcctgggatatgcgccccatagcacgtataacggtaactttctacgacctatcatctaactagaaatcacagtatacgaggaagctcgtcgaccatatggcacctaacggtagtggaaggcgccaatcacagatggttcactaacggtcttaagatcgaattacaatgctgtgaacttatagaggacgggagcaagcgtcgtccacccgcgtagggttagcgttaacacagtctttcagtcgttcgtctaggagaggaggctctttcacaaaacaaaccagatgtctttgggcacgttgaaattagcgggttgaggtgctctacgtccgacacctttgccagaggtgtaaaaagggattaccttaatcccgtgtgtgataccctgtagtacccacgacttaacaactagaggccggtgtataccagttacccgacaatgcaaatcgtattattgcggtagtatcgatcctccccgatgctcgatcttgtacagaagaaaagcccgaaaatttaatgaagcaaaataccctatctgcccaggaggatagaagccccatcaatgacttaaactccgacgattttacgggcggtctaccgctcacaggcaggtgaagacatcacatatgctccgtgtacgcatcggatccaagaaacttccgtccagctgtcataaacctggactttttgtatctggaggtgacttagccgatagcaacgaaatctcaattgagctggttctaaatctttcttttagacggagcatatgtgaagtagtaaaatcatctctaggttcacggaggtaatcgtcggtctgccaccctgactcggctattaggtggaggagcttttaagctctttacaacacctaagtctgcccatattatgcatggttttccgacacatttcctcctaatcgtag"}

      {:ok, result} = Subject.read("test/snap_gene/sample-d.dna")

      refute result.circular?
      assert result.valid?
      assert result.sequence == dna
    end

    test "reading feature names" do
      {:ok, %{features: f}} = Subject.read("test/snap_gene/sample-d.dna")

      query_results =
        f
        |> XML.get('/*/Feature/@name')
        |> Enum.map(&XML.root_str/1)

      assert query_results == ["FeatureB", "FeatureA", "FeatureC", "FeatureD"]
    end

    test "reading feature qualifiers" do
      {:ok, %{features: f}} = Subject.read("test/snap_gene/sample-d.dna")

      query_results =
        f
        |> XML.get('/*/Feature')
        |> Enum.map(fn el ->
          {XML.str(el, 'string(/*/@name)'),
           XML.collect(
             el,
             '/Feature/Q/V/@text'
           )}
        end)

      assert query_results == [
               {"FeatureB",
                [
                  "<html><body>Random DNA-Binding Protein 1</body></html>",
                  "<html><body>Sample feature B</body></html>"
                ]},
               {"FeatureA", ["<html><body>Sample feature A</body></html>"]},
               {"FeatureC",
                [
                  "FeatureC",
                  "<html><body>Sample feature C, with explicit label</body></html>",
                  "<html><body>Another note for sample feature C</body></html>"
                ]},
               {"FeatureD",
                [
                  "SampleFeatureD",
                  "<html><body>Sample feature D, with a label different from the feature name</body></html>"
                ]}
             ]
    end

    test "reading segment ranges" do
      {:ok, %{features: f}} = Subject.read("test/snap_gene/sample-d.dna")

      query_results =
        f
        |> XML.get('/*/Feature/Segment/@range')
        |> Enum.map(&XML.root_str/1)

      assert query_results == ["500-700", "50-150", "701-720", "721-740"]
    end

    test "reading feature type" do
      {:ok, %{features: f}} = Subject.read("test/snap_gene/sample-d.dna")

      query_results =
        f
        |> XML.get('/*/Feature/@type')
        |> Enum.map(&XML.root_str/1)

      assert query_results == ["misc_binding", "promoter", "misc_feature", "misc_feature"]
    end

    test "reading feature directionality" do
      {:ok, %{features: f}} = Subject.read("test/snap_gene/sample-d.dna")

      query_results =
        f
        |> XML.get('/*/Feature')
        |> Enum.map(fn feat ->
          {XML.str(feat, '/Feature/@name'), XML.str(feat, '/Feature/@directionality')}
        end)

      assert query_results == [
               {"FeatureB", ""},
               {"FeatureA", "1"},
               {"FeatureC", ""},
               {"FeatureD", ""}
             ]
    end
  end

  describe "sample-e" do
    test "reading primary fields with type dna" do
      dna =
        DnaStrand.new(
          "gtcagcctgtctcttctgacagccacacagccattgcttgttaccaggattaacagcagcattccttcataaaagttatggtacccttttctttctgcgccggttcgtgcaaatgaccaatgcccacaagtgaagttcgtaataacgaccgagacctgggcgggaccgtatgtagttgatgatatgggctttaaccagctataggatctcgcgaccggtggaattccttcgtgaggattaaggtaaacgatgctcatgatgctgaggtgtgccatgacccagagtcgtatcgatccttatatgtgctatcactcttattatcattatactgattttccacgtggtggttgcaggtatcgctttctggcgagtatcaagttgctgctttatgatcggcgaactggcactcatagacggtctccctccaactcactagtacctggatcggaatcggcggctctgacatgtatcaggaagtgactgtgatcaaaactggcaaaagtgcaatataaatcgtcaccactgctgctcataagcgttcattcaacccgaggtagtaaggccgcagacaactcccaggcggagggtccaaccctgagtcagcgcgacacacaacagctcaacgctataaacctcggtcgttgacgctcggggggttaaagccgtgaagttctcaatacactctcttattccttcggctattaccaaattaaggtccatgccccgcgaactccttgaacgcaacctcgataaataaaaaacgattgaaggttacatgcgtaagggcctaaagataaaaacctccgataggcatgttatcggtcccttctacagggcgactagcgctgggagggatacgcaaacccggacaggaaaggtagctgaaagcaacgggtacggtagataaaatttgtccgcaagcagagctttgtacggtccgcccgatggtggaatcatatcgtttgctgaagtgctaacaccctccatctgactagctata"
        )

      {:ok, result} = Subject.read("test/snap_gene/sample-e.dna", sequence_type: DnaStrand)

      assert result.circular?
      assert result.valid?
      assert result.sequence == dna
    end

    test "reading primary fields" do
      dna =
        {nil,
         "gtcagcctgtctcttctgacagccacacagccattgcttgttaccaggattaacagcagcattccttcataaaagttatggtacccttttctttctgcgccggttcgtgcaaatgaccaatgcccacaagtgaagttcgtaataacgaccgagacctgggcgggaccgtatgtagttgatgatatgggctttaaccagctataggatctcgcgaccggtggaattccttcgtgaggattaaggtaaacgatgctcatgatgctgaggtgtgccatgacccagagtcgtatcgatccttatatgtgctatcactcttattatcattatactgattttccacgtggtggttgcaggtatcgctttctggcgagtatcaagttgctgctttatgatcggcgaactggcactcatagacggtctccctccaactcactagtacctggatcggaatcggcggctctgacatgtatcaggaagtgactgtgatcaaaactggcaaaagtgcaatataaatcgtcaccactgctgctcataagcgttcattcaacccgaggtagtaaggccgcagacaactcccaggcggagggtccaaccctgagtcagcgcgacacacaacagctcaacgctataaacctcggtcgttgacgctcggggggttaaagccgtgaagttctcaatacactctcttattccttcggctattaccaaattaaggtccatgccccgcgaactccttgaacgcaacctcgataaataaaaaacgattgaaggttacatgcgtaagggcctaaagataaaaacctccgataggcatgttatcggtcccttctacagggcgactagcgctgggagggatacgcaaacccggacaggaaaggtagctgaaagcaacgggtacggtagataaaatttgtccgcaagcagagctttgtacggtccgcccgatggtggaatcatatcgtttgctgaagtgctaacaccctccatctgactagctata"}

      {:ok, result} = Subject.read("test/snap_gene/sample-e.dna")

      assert result.circular?
      assert result.valid?
      assert result.sequence == dna
    end

    test "reading feature names" do
      {:ok, %{features: f}} = Subject.read("test/snap_gene/sample-e.dna")

      query_results =
        f
        |> XML.get('/*/Feature/@name')
        |> Enum.map(&XML.root_str/1)

      assert query_results == ["FeatureB", "FeatureA"]
    end

    test "reading segment ranges" do
      {:ok, %{features: f}} = Subject.read("test/snap_gene/sample-e.dna")

      query_results =
        f
        |> XML.get('/*/Feature/Segment/@range')
        |> Enum.map(&XML.root_str/1)

      assert query_results == ["400-750", "161-241"]
    end

    test "reading feature type" do
      {:ok, %{features: f}} = Subject.read("test/snap_gene/sample-e.dna")

      query_results =
        f
        |> XML.get('/*/Feature/@type')
        |> Enum.map(&XML.root_str/1)

      assert query_results == ["terminator", "rep_origin"]
    end

    test "reading feature directionality" do
      {:ok, %{features: f}} = Subject.read("test/snap_gene/sample-e.dna")

      query_results =
        f
        |> XML.get('/*/Feature')
        |> Enum.map(fn el ->
          {XML.str(el, '/*/@name'), XML.str(el, '/*/@directionality')}
        end)

      assert query_results == [{"FeatureB", "2"}, {"FeatureA", "1"}]
    end
  end

  describe "sample-f" do
    test "reading primary fields with type dna" do
      dna =
        DnaStrand.new(
          "gtcagcctgtctcttctgacagccacacagccattgcttgttaccaggattaacagcagcattccttcataaaagttatggtacccttttctttctgcgccggttcgtgcaaatgaccaatgcccacaagtgaagttcgtaataacgaccgagacctgggcgggaccgtatgtagttgatgatatgggctttaaccagctataggatctcgcgaccggtggaattccttcgtgaggattaaggtaaacgatgctcatgatgctgaggtgtgccatgacccagagtcgtatcgatccttatatgtgctatcactcttattatcattatactgattttccacgtggtggttgcaggtatcgctttctggcgagtatcaagttgctgctttatgatcggcgaactggcactcatagacggtctccctccaactcactagtacctggatcggaatcggcggctctgacatgtatcaggaagtgactgtgatcaaaactggcaaaagtgcaatataaatcgtcaccactgctgctcataagcgttcattcaacccgaggtagtaaggccgcagacaactcccaggcggagggtccaaccctgagtcagcgcgacacacaacagctcaacgctataaacctcggtcgttgacgctcggggggttaaagccgtgaagttctcaatacactctcttattccttcggctattaccaaattaaggtccatgccccgcgaactccttgaacgcaacctcgataaataaaaaacgattgaaggttacatgcgtaagggcctaaagataaaaacctccgataggcatgttatcggtcccttctacagggcgactagcgctgggagggatacgcaaacccggacaggaaaggtagctgaaagcaacgggtacggtagataaaatttgtccgcaagcagagctttgtacggtccgcccgatggtggaatcatatcgtttgctgaagtgctaacaccctccatctgactagctata"
        )

      {:ok, result} = Subject.read("test/snap_gene/sample-f.dna", sequence_type: DnaStrand)

      assert result.circular?
      assert result.valid?
      assert result.sequence == dna
    end

    test "reading primary fields" do
      dna =
        {nil,
         "gtcagcctgtctcttctgacagccacacagccattgcttgttaccaggattaacagcagcattccttcataaaagttatggtacccttttctttctgcgccggttcgtgcaaatgaccaatgcccacaagtgaagttcgtaataacgaccgagacctgggcgggaccgtatgtagttgatgatatgggctttaaccagctataggatctcgcgaccggtggaattccttcgtgaggattaaggtaaacgatgctcatgatgctgaggtgtgccatgacccagagtcgtatcgatccttatatgtgctatcactcttattatcattatactgattttccacgtggtggttgcaggtatcgctttctggcgagtatcaagttgctgctttatgatcggcgaactggcactcatagacggtctccctccaactcactagtacctggatcggaatcggcggctctgacatgtatcaggaagtgactgtgatcaaaactggcaaaagtgcaatataaatcgtcaccactgctgctcataagcgttcattcaacccgaggtagtaaggccgcagacaactcccaggcggagggtccaaccctgagtcagcgcgacacacaacagctcaacgctataaacctcggtcgttgacgctcggggggttaaagccgtgaagttctcaatacactctcttattccttcggctattaccaaattaaggtccatgccccgcgaactccttgaacgcaacctcgataaataaaaaacgattgaaggttacatgcgtaagggcctaaagataaaaacctccgataggcatgttatcggtcccttctacagggcgactagcgctgggagggatacgcaaacccggacaggaaaggtagctgaaagcaacgggtacggtagataaaatttgtccgcaagcagagctttgtacggtccgcccgatggtggaatcatatcgtttgctgaagtgctaacaccctccatctgactagctata"}

      {:ok, result} = Subject.read("test/snap_gene/sample-f.dna")

      assert result.circular?
      assert result.valid?
      assert result.sequence == dna
    end

    test "reading feature names" do
      {:ok, %{features: f}} = Subject.read("test/snap_gene/sample-f.dna")

      query_results =
        f
        |> XML.get('/*/Feature/@name')
        |> Enum.map(&XML.root_str/1)

      assert query_results == ["FeatureB", "FeatureA"]
    end

    test "reading segment ranges" do
      {:ok, %{features: f}} = Subject.read("test/snap_gene/sample-f.dna")

      query_results =
        f
        |> XML.get('/*/Feature/Segment/@range')
        |> Enum.map(&XML.root_str/1)

      assert query_results == [
               "400-499",
               "500-516",
               "517-634",
               "635-724",
               "161-180",
               "181-187",
               "188-207",
               "208-214",
               "215-241"
             ]
    end

    test "reading feature type" do
      {:ok, %{features: f}} = Subject.read("test/snap_gene/sample-f.dna")

      query_results =
        f
        |> XML.get('/*/Feature/@type')
        |> Enum.map(&XML.root_str/1)

      assert query_results == ["terminator", "rep_origin"]
    end

    test "reading feature directionality" do
      {:ok, %{features: f}} = Subject.read("test/snap_gene/sample-f.dna")

      query_results =
        f
        |> XML.get('/*/Feature')
        |> Enum.map(fn el ->
          {XML.str(el, '/*/@name'), XML.str(el, '/*/@directionality')}
        end)

      assert query_results == [{"FeatureB", "2"}, {"FeatureA", "1"}]
    end
  end

  describe "pFA-KanMX4" do
    test "reading primary fields with type dna" do
      dna =
        DnaStrand.new(
          "gaacgcggccgccagctgaagcttcgtacgctgcaggtcgacggatccccgggttaattaaggcgcgccagatctgtttagcttgcctcgtccccgccgggtcacccggccagcgacatggaggcccagaataccctccttgacagtcttgacgtgcgcagctcaggggcatgatgtgactgtcgcccgtacatttagcccatacatccccatgtataatcatttgcatccatacattttgatggccgcacggcgcgaagcaaaaattacggctcctcgctgcagacctgcgagcagggaaacgctcccctcacagacgcgttgaattgtccccacgccgcgcccctgtagagaaatataaaaggttaggatttgccactgaggttcttctttcatatacttccttttaaaatcttgctaggatacagttctcacatcacatccgaacataaacaaccatgggtaaggaaaagactcacgtttcgaggccgcgattaaattccaacatggatgctgatttatatgggtataaatgggctcgcgataatgtcgggcaatcaggtgcgacaatctatcgattgtatgggaagcccgatgcgccagagttgtttctgaaacatggcaaaggtagcgttgccaatgatgttacagatgagatggtcagactaaactggctgacggaatttatgcctcttccgaccatcaagcattttatccgtactcctgatgatgcatggttactcaccactgcgatccccggcaaaacagcattccaggtattagaagaatatcctgattcaggtgaaaatattgttgatgcgctggcagtgttcctgcgccggttgcattcgattcctgtttgtaattgtccttttaacagcgatcgcgtatttcgtctcgctcaggcgcaatcacgaatgaataacggtttggttgatgcgagtgattttgatgacgagcgtaatggctggcctgttgaacaagtctggaaagaaatgcataagcttttgccattctcaccggattcagtcgtcactcatggtgatttctcacttgataaccttatttttgacgaggggaaattaataggttgtattgatgttggacgagtcggaatcgcagaccgataccaggatcttgccatcctatggaactgcctcggtgagttttctccttcattacagaaacggctttttcaaaaatatggtattgataatcctgatatgaataaattgcagtttcatttgatgctcgatgagtttttctaatcagtactgacaataaaaagattcttgttttcaagaacttgtcatttgtatagtttttttatattgtagttgttctattttaatcaaatgttagcgtgatttatattttttttcgcctcgacatcatctgcccagatgcgaagttaagtgcgcagaaagtaatatcatgcgtcaatcgtatgtgaatgctggtcgctatactgctgtcgattcgatactaacgccgccatccagtgtcgaaaacgagctcgaattcatcgatgatatcagatccactagtggcctatgcggccgcggatctgccggtctccctatagtgagtcgtattaatttcgataagccaggttaacctgcattaatgaatcggccaacgcgcggggagaggcggtttgcgtattgggcgctcttccgcttcctcgctcactgactcgctgcgctcggtcgttcggctgcggcgagcggtatcagctcactcaaaggcggtaatacggttatccacagaatcaggggataacgcaggaaagaacatgtgagcaaaaggccagcaaaaggccaggaaccgtaaaaaggccgcgttgctggcgtttttccataggctccgcccccctgacgagcatcacaaaaatcgacgctcaagtcagaggtggcgaaacccgacaggactataaagataccaggcgtttccccctggaagctccctcgtgcgctctcctgttccgaccctgccgcttaccggatacctgtccgcctttctcccttcgggaagcgtggcgctttctcaatgctcacgctgtaggtatctcagttcggtgtaggtcgttcgctccaagctgggctgtgtgcacgaaccccccgttcagcccgaccgctgcgccttatccggtaactatcgtcttgagtccaacccggtaagacacgacttatcgccactggcagcagccactggtaacaggattagcagagcgaggtatgtaggcggtgctacagagttcttgaagtggtggcctaactacggctacactagaaggacagtatttggtatctgcgctctgctgaagccagttaccttcggaaaaagagttggtagctcttgatccggcaaacaaaccaccgctggtagcggtggtttttttgtttgcaagcagcagattacgcgcagaaaaaaaggatctcaagaagatcctttgatcttttctacggggtctgacgctcagtggaacgaaaactcacgttaagggattttggtcatgagattatcaaaaaggatcttcacctagatccttttaaattaaaaatgaagttttaaatcaatctaaagtatatatgagtaaacttggtctgacagttaccaatgcttaatcagtgaggcacctatctcagcgatctgtctatttcgttcatccatagttgcctgactccccgtcgtgtagataactacgatacgggagggcttaccatctggccccagtgctgcaatgataccgcgagacccacgctcaccggctccagatttatcagcaataaaccagccagccggaagggccgagcgcagaagtggtcctgcaactttatccgcctccatccagtctattaattgttgccgggaagctagagtaagtagttcgccagttaatagtttgcgcaacgttgttgccattgctacaggcatcgtggtgtcacgctcgtcgtttggtatggcttcattcagctccggttcccaacgatcaaggcgagttacatgatcccccatgttgtgcaaaaaagcggttagctccttcggtcctccgatcgttgtcagaagtaagttggccgcagtgttatcactcatggttatggcagcactgcataattctcttactgtcatgccatccgtaagatgcttttctgtgactggtgagtactcaaccaagtcattctgagaatagtgtatgcggcgaccgagttgctcttgcccggcgtcaatacgggataataccgcgccacatagcagaactttaaaagtgctcatcattggaaaacgttcttcggggcgaaaactctcaaggatcttaccgctgttgagatccagttcgatgtaacccactcgtgcacccaactgatcttcagcatcttttactttcaccagcgtttctgggtgagcaaaaacaggaaggcaaaatgccgcaaaaaagggaataagggcgacacggaaatgttgaatactcatactcttcctttttcaatattattgaagcatttatcagggttattgtctcatgagcggatacatatttgaatgtatttagaaaaataaacaaataggggttccgcgcacatttccccgaaaagtgccacctgacgtctaagaaaccattattatcatgacattaacctataaaaataggcgtatcacgaggccctttcgtctcgcgcgtttcggtgatgacggtgaaaacctctgacacatgcagctcccggagacggtcacagcttgtctgtaagcggatgccgggagcagacaagcccgtcagggcgcgtcagcgggtgttggcgggtgtcggggctggcttaactatgcggcatcagagcagattgtactgagagtgcaccatatggacatattgtcgttagaacgcggctacaattaatacataaccttatgtatcatacacatacgatttaggtgacactata"
        )

      {:ok, result} =
        Subject.read("test/snap_gene/pFA-KanMX4.dna",
          sequence_type: DnaStrand
        )

      assert result.circular?
      assert result.valid?
      assert result.sequence == dna
    end

    test "reading primary fields" do
      dna =
        {nil,
         "gaacgcggccgccagctgaagcttcgtacgctgcaggtcgacggatccccgggttaattaaggcgcgccagatctgtttagcttgcctcgtccccgccgggtcacccggccagcgacatggaggcccagaataccctccttgacagtcttgacgtgcgcagctcaggggcatgatgtgactgtcgcccgtacatttagcccatacatccccatgtataatcatttgcatccatacattttgatggccgcacggcgcgaagcaaaaattacggctcctcgctgcagacctgcgagcagggaaacgctcccctcacagacgcgttgaattgtccccacgccgcgcccctgtagagaaatataaaaggttaggatttgccactgaggttcttctttcatatacttccttttaaaatcttgctaggatacagttctcacatcacatccgaacataaacaaccatgggtaaggaaaagactcacgtttcgaggccgcgattaaattccaacatggatgctgatttatatgggtataaatgggctcgcgataatgtcgggcaatcaggtgcgacaatctatcgattgtatgggaagcccgatgcgccagagttgtttctgaaacatggcaaaggtagcgttgccaatgatgttacagatgagatggtcagactaaactggctgacggaatttatgcctcttccgaccatcaagcattttatccgtactcctgatgatgcatggttactcaccactgcgatccccggcaaaacagcattccaggtattagaagaatatcctgattcaggtgaaaatattgttgatgcgctggcagtgttcctgcgccggttgcattcgattcctgtttgtaattgtccttttaacagcgatcgcgtatttcgtctcgctcaggcgcaatcacgaatgaataacggtttggttgatgcgagtgattttgatgacgagcgtaatggctggcctgttgaacaagtctggaaagaaatgcataagcttttgccattctcaccggattcagtcgtcactcatggtgatttctcacttgataaccttatttttgacgaggggaaattaataggttgtattgatgttggacgagtcggaatcgcagaccgataccaggatcttgccatcctatggaactgcctcggtgagttttctccttcattacagaaacggctttttcaaaaatatggtattgataatcctgatatgaataaattgcagtttcatttgatgctcgatgagtttttctaatcagtactgacaataaaaagattcttgttttcaagaacttgtcatttgtatagtttttttatattgtagttgttctattttaatcaaatgttagcgtgatttatattttttttcgcctcgacatcatctgcccagatgcgaagttaagtgcgcagaaagtaatatcatgcgtcaatcgtatgtgaatgctggtcgctatactgctgtcgattcgatactaacgccgccatccagtgtcgaaaacgagctcgaattcatcgatgatatcagatccactagtggcctatgcggccgcggatctgccggtctccctatagtgagtcgtattaatttcgataagccaggttaacctgcattaatgaatcggccaacgcgcggggagaggcggtttgcgtattgggcgctcttccgcttcctcgctcactgactcgctgcgctcggtcgttcggctgcggcgagcggtatcagctcactcaaaggcggtaatacggttatccacagaatcaggggataacgcaggaaagaacatgtgagcaaaaggccagcaaaaggccaggaaccgtaaaaaggccgcgttgctggcgtttttccataggctccgcccccctgacgagcatcacaaaaatcgacgctcaagtcagaggtggcgaaacccgacaggactataaagataccaggcgtttccccctggaagctccctcgtgcgctctcctgttccgaccctgccgcttaccggatacctgtccgcctttctcccttcgggaagcgtggcgctttctcaatgctcacgctgtaggtatctcagttcggtgtaggtcgttcgctccaagctgggctgtgtgcacgaaccccccgttcagcccgaccgctgcgccttatccggtaactatcgtcttgagtccaacccggtaagacacgacttatcgccactggcagcagccactggtaacaggattagcagagcgaggtatgtaggcggtgctacagagttcttgaagtggtggcctaactacggctacactagaaggacagtatttggtatctgcgctctgctgaagccagttaccttcggaaaaagagttggtagctcttgatccggcaaacaaaccaccgctggtagcggtggtttttttgtttgcaagcagcagattacgcgcagaaaaaaaggatctcaagaagatcctttgatcttttctacggggtctgacgctcagtggaacgaaaactcacgttaagggattttggtcatgagattatcaaaaaggatcttcacctagatccttttaaattaaaaatgaagttttaaatcaatctaaagtatatatgagtaaacttggtctgacagttaccaatgcttaatcagtgaggcacctatctcagcgatctgtctatttcgttcatccatagttgcctgactccccgtcgtgtagataactacgatacgggagggcttaccatctggccccagtgctgcaatgataccgcgagacccacgctcaccggctccagatttatcagcaataaaccagccagccggaagggccgagcgcagaagtggtcctgcaactttatccgcctccatccagtctattaattgttgccgggaagctagagtaagtagttcgccagttaatagtttgcgcaacgttgttgccattgctacaggcatcgtggtgtcacgctcgtcgtttggtatggcttcattcagctccggttcccaacgatcaaggcgagttacatgatcccccatgttgtgcaaaaaagcggttagctccttcggtcctccgatcgttgtcagaagtaagttggccgcagtgttatcactcatggttatggcagcactgcataattctcttactgtcatgccatccgtaagatgcttttctgtgactggtgagtactcaaccaagtcattctgagaatagtgtatgcggcgaccgagttgctcttgcccggcgtcaatacgggataataccgcgccacatagcagaactttaaaagtgctcatcattggaaaacgttcttcggggcgaaaactctcaaggatcttaccgctgttgagatccagttcgatgtaacccactcgtgcacccaactgatcttcagcatcttttactttcaccagcgtttctgggtgagcaaaaacaggaaggcaaaatgccgcaaaaaagggaataagggcgacacggaaatgttgaatactcatactcttcctttttcaatattattgaagcatttatcagggttattgtctcatgagcggatacatatttgaatgtatttagaaaaataaacaaataggggttccgcgcacatttccccgaaaagtgccacctgacgtctaagaaaccattattatcatgacattaacctataaaaataggcgtatcacgaggccctttcgtctcgcgcgtttcggtgatgacggtgaaaacctctgacacatgcagctcccggagacggtcacagcttgtctgtaagcggatgccgggagcagacaagcccgtcagggcgcgtcagcgggtgttggcgggtgtcggggctggcttaactatgcggcatcagagcagattgtactgagagtgcaccatatggacatattgtcgttagaacgcggctacaattaatacataaccttatgtatcatacacatacgatttaggtgacactata"}

      {:ok, result} = Subject.read("test/snap_gene/pFA-KanMX4.dna")

      assert result.circular?
      assert result.valid?
      assert result.sequence == dna
    end

    test "reading feature names" do
      {:ok, %{features: f}} = Subject.read("test/snap_gene/pFA-KanMX4.dna")

      query_results =
        f
        |> XML.get('/*/Feature/@name')
        |> Enum.map(&XML.root_str/1)

      assert query_results == [
               "SP6 promoter",
               "T7 promoter",
               "AmpR promoter",
               "TEF terminator",
               "TEF promoter",
               "ori",
               "KanR",
               "AmpR",
               "kanMX"
             ]
    end

    test "reading segment ranges" do
      {:ok, %{features: f}} = Subject.read("test/snap_gene/pFA-KanMX4.dna")

      query_results =
        f
        |> XML.get('/*/Feature/Segment/@range')
        |> Enum.map(&XML.root_str/1)

      assert query_results == [
               "3925-2",
               "1579-1597",
               "3475-3579",
               "1274-1471",
               "115-458",
               "1855-2443",
               "459-1268",
               "2614-3405",
               "3406-3474",
               "115-1471"
             ]
    end

    test "reading feature type" do
      {:ok, %{features: f}} = Subject.read("test/snap_gene/pFA-KanMX4.dna")

      query_results =
        f
        |> XML.get('/*/Feature/@type')
        |> Enum.map(&XML.root_str/1)

      assert query_results == [
               "promoter",
               "promoter",
               "promoter",
               "terminator",
               "promoter",
               "rep_origin",
               "CDS",
               "CDS",
               "gene"
             ]
    end

    test "reading feature directionality" do
      {:ok, %{features: f}} = Subject.read("test/snap_gene/pFA-KanMX4.dna")

      query_results =
        f
        |> XML.get('/*/Feature')
        |> Enum.map(fn el ->
          {XML.str(el, '/*/@name'), XML.str(el, '/*/@directionality')}
        end)

      assert query_results == [
               {"SP6 promoter", "1"},
               {"T7 promoter", "2"},
               {"AmpR promoter", "2"},
               {"TEF terminator", ""},
               {"TEF promoter", "1"},
               {"ori", "2"},
               {"KanR", "1"},
               {"AmpR", "2"},
               {"kanMX", "1"}
             ]
    end

    test "reading feature qualifiers" do
      {:ok, %{features: f}} = Subject.read("test/snap_gene/pFA-KanMX4.dna")

      query_results =
        f
        |> XML.get('/*/Feature')
        |> Enum.map(fn el ->
          {XML.str(el, 'string(/*/@name)'),
           XML.collect(
             el,
             '/Feature/Q/V/@text'
           )}
        end)

      assert query_results == [
               {"SP6 promoter",
                ["<html><body>promoter for bacteriophage SP6 RNA polymerase</body></html>"]},
               {"T7 promoter",
                ["<html><body>promoter for bacteriophage T7 RNA polymerase</body></html>"]},
               {"AmpR promoter", ["<html><body><i>bla</i></body></html>"]},
               {"TEF terminator",
                ["<html><body><i>Ashbya gossypii TEF</i> terminator</body></html>"]},
               {"TEF promoter",
                ["<html><body><i>Ashbya gossypii TEF</i> promoter</body></html>"]},
               {"ori",
                [
                  "<html><body>high-copy-number colE1/pMB1/pBR322/pUC origin of replication</body></html>",
                  "LEFT"
                ]},
               {"KanR",
                [
                  "MGKEKTHVSRPRLNSNMDADLYGYKWARDNVGQSGATIYRLYGKPDAPELFLKHGKGSVANDVTDEMVRLNWLTEFMPLPTIKHFIRTPDDAWLLTTAIPGKTAFQVLEEYPDSGENIVDALAVFLRRLHSIPVCNCPFNSDRVFRLAQAQSRMNNGLVDASDFDDERNGWPVEQVWKEMHKLLPFSPDSVVTHGDFSLDNLIFDEGKLIGCIDVGRVGIADRYQDLAILWNCLGEFSPSLQKRLFQKYGIDNPDMNKLQFHLMLDEFF*",
                  "<html><body>aminoglycoside phosphotransferase</body></html>",
                  "<html><body>confers resistance to kanamycin in bacteria or G418 (Geneticin®) in eukaryotes</body></html>",
                  "<html><body><i>aph(3')-Ia</i></body></html>"
                ]},
               {"AmpR",
                [
                  "MSIQHFRVALIPFFAAFCLPVFA,HPETLVKVKDAEDQLGARVGYIELDLNSGKILESFRPEERFPMMSTFKVLLCGAVLSRIDAGQEQLGRRIHYSQNDLVEYSPVTEKHLTDGMTVRELCSAAITMSDNTAANLLLTTIGGPKELTAFLHNMGDHVTRLDRWEPELNEAIPNDERDTTMPVAMATTLRKLLTGELLTLASRQQLIDWMEADKVAGPLLRSALPAGWFIADKSGAGERGSRGIIAALGPDGKPSRIVVIYTTGSQATMDERNRQIAEIGASLIKHW*",
                  "<html><body>β-lactamase</body></html>",
                  "<html><body>confers resistance to ampicillin, carbenicillin, and related antibiotics</body></html>",
                  "<html><body><i>bla</i></body></html>"
                ]},
               {"kanMX",
                [
                  "<html><body>yeast selectable marker conferring kanamycin resistance</body></html>"
                ]}
             ]
    end
  end
end
