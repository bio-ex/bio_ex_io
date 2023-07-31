defmodule Bio.XML do
  # TODO: should I expose this? it's mostly test helpers
  @moduledoc false

  @doc """
  Read an XML file and return the document without the rest
  This function makes the assumption that you are parsing out a rooted document
  and that you don't care about anything that might be in rest. If you don't
  know, `:xmerl_scan.file/1` will return a tuple where the first element is the
  first root document and the second is a charlist of the next sibling. By way
  of example, the following:
  ```
  <?xml version="1.0" ?>
  <Things>
    <Thing></Thing>
    <Thing></Thing>
  </Things>
  <Other></Other>
  ```
  Would return `{doc, '<Other></Other>'}`.
  This function would ignore that. If you're working with XML that you might
  want to deal with this case, this is not the function for you!
  """
  def read(filename) do
    {doc, _rest} = :xmerl_scan.file(filename)
    doc
  end

  @doc """
  Get an element from an XML document
  Simple proxy call to `:xmerl_xpath.string/2`, but it switches the position of
  the arguments to make it easier to pipe a doc through. This plays nicely with
  the `Bio.XML.read/1` function, since you can now do things like:
      iex>Bio.XML.read("some.xml") |> Bio.XML.get('/*/Some/Thing')
  """
  def get(doc, path) do
    :xmerl_xpath.string(path, doc)
  end

  @doc """
  Retrieve [path] with `string` called on it from [doc]
  This is a proxy call to `:xmerl_xpath.string/2` where the arguments are
  reversed, and the path is interpolated into the XML `string` function.
  It also unpacks the tuple, returning only the value as a binary instead of a
  charlist.
  """
  def str(doc, path) do
    {_, _, value} = :xmerl_xpath.string('string(#{path})', doc)
    List.to_string(value)
  end

  @doc """
  Call `Bio.XML.str` on the root node of the document
  This is a pure convenience for mapping over collections of selected nodes
  where you want to get the string value. For example, if you have:
  ```
  <Things>
    <Thing name="bob dylan"/>
    <Thing name="jimi hendrix"/>
    <Thing name="nick drake"/>
  </Things>
  ```
  Then you can easily get the names with:
    iex> Bio.XML.read('that_file.xml') |> Bio.XML.get('/*/Thing/@name') |> Enum.map(&Bio.XML.root_str/1)
  """
  def root_str(doc) do
    str(doc, '/*')
  end

  @doc """
  Collect elements of the path using `Bio.XML.root_str/1`
  This abstracts the pattern of making a selection and mapping over it to
  produce a list of strings.
  """
  def collect(doc, path) do
    doc
    |> get(path)
    |> Stream.map(&root_str/1)
    |> Enum.into([])
  end

  @doc """
  Collect elements of the path using a given transformation
  Generalizes `Bio.XML.collect/2` by allowing you to define the transform on
  each element.
  """
  def collect(doc, path, transform) do
    doc
    |> get(path)
    |> Stream.map(fn el -> transform.(el) end)
    |> Enum.into([])
  end
end
