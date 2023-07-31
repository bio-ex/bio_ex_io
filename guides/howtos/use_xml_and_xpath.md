# How To Work With XML

## Document Purpose

This is an overview of how to use XPaths to query an XML structure in Elixir.

## Why force you to deal with XPath?

I'm a software engineer. Plain and simple. I do not know what you want, nor do I
have a desire to lock you into a specific sub-set of the data that can be
retrieved from any given format. This is no exception.

My primary goal in this project is to provide powerful, efficient, and
expressive tooling, which will allow more intuitive tooling in higher level
projects.

## XPath Basics

Wikipedia's definition of XML is fairly useful here:

> Extensible Markup Language (XML) is a markup language and file format for storing,
> transmitting, and reconstructing arbitrary data. It defines a set of rules for
> encoding documents in a format that is both human-readable and machine-readable.
> The World Wide Web Consortium's XML 1.0 Specification of 1998 and several other
> related specifications—all of them free open standards—define XML.
> That is, XML is a structured document format. This allows us to treat the
> document according the Document Object Model (DOM). This will be familiar to
> anyone with experience in developing for the web, as HTML is a similar format.
> In fact, you can use XPath to query HTML documents in JavaScript as well.

The most basic form of access is the root. All well formed documents will have a
root node against which you can query. This will often take the form of the `/`
character. This is a very common idiom for tree-like structures, not limited to
the DOM. Even the root directory of your file-system (on \*nix) will be
represented as such.

Each element beyond the root is considered as a child. You can access them with
`/ChildNode`. For those familiar with HTML, the biggest difference between XML
and HTML is that there isn't a standard for the nodes. In XML, each node can be
defined however you would like. So this is a perfectly valid document:

```xml
<?xml version="1.0" ?>
<OuterBody>
  <InnerBody>
    <InnerField1>Content</InnerField1>
    <InnerField2>Content</InnerField2>
    <InnerField3>Content</InnerField3>
  </InnerBody>
  <OuterField1>Content</OuterField1>
  <OuterField2>Content</OuterField2>
</OuterBody>
```

Where the root node is `/OuterBody`, and the children are `OuterBody/InnerBody`,
`OuterBody/OuterField1`, and `OuterBody/OuterField2`.

The fields do _not_ need to be numbered though, and more often they won't be.
Something more common might be:

```xml
<?xml version="1.0" ?>
<OuterBody>
  <InnerBody>
    <InnerField>Content</InnerField>
    <InnerField>Content</InnerField>
    <InnerField>Content</InnerField>
  </InnerBody>
  <OuterField>Content</OuterField>
  <OuterField>Content</OuterField>
</OuterBody>
```

The fields will normally be named according to the semantic meaning of the
contents. You can also have various attributes that are associated with each
node:

```xml
<?xml version="1.0" ?>
<OuterBody>
  <InnerBody name="First Inner">
    <InnerField>Content</InnerField>
    <InnerField>Content</InnerField>
    <InnerField>Content</InnerField>
  </InnerBody>
  <OuterField>Content</OuterField>
  <OuterField>Content</OuterField>
</OuterBody>
```

This is useful for when you are representing hierarchical relationships. These
are access by using the `@<field_attribute>` notation. So the above would be
`/Outerbody/InnerBody/@name`.

## Querying Paths with Erlang

Querying paths with Erlang is very straightforward. The biggest issue with doing
so is that you will need to convert between binaries and character lists. As
this interface is elixir, the expectation is character list.

```elixir
:xmerl_xpath.string('/path/to/node', xml_doc)
```

Let's use an example that is a little easier to think about, something like
research paper citations:

```xml
<?xml version="1.0" ?>
<References>
  <Paper refNum="1">
    <Title>A Novel Method for Quantification of Midi-Chlorians From Salivary Samples</Title>
    <Authors>
      <Author name="H. Solo"></Author>
      <Author name="L. Organa"></Author>
      <Author name="L. Skywalker"></Author>
    </Authors>
  </Paper>
  <Paper refNum="2">
    <Title>Harmonic Crystal Frequencies and Light-Saber Characteristics: Review</Title>
    <Authors>
      <Author name="A. Skywalker"></Author>
      <Author name="O. Kenobi"></Author>
      <Author name="A. Tano"></Author>
    </Authors>
  </Paper>
  <Paper refNum="3">
    <Title>Modification of the Natural Foci for Midi-Chlorian Energies</Title>
    <Authors>
      <Author name="D. Plagueis"></Author>
      <Author name="D. Sidious" aka="S. Palpatine"></Author>
      <Author name="D. Maul"></Author>
      <Author name="D. Vader" aka="A. Skywalker"></Author>
    </Authors>
  </Paper>
</References>
```

**Note**: I had to look up a lot of names and general themes on Wookipedia. I
hope that you can enjoy the references for what they are. I tried.

There are obviously different ways that you might want to query this data. For
example, let's say that you wanted to get the paper with `refNum="2"`. I'll
start by showing how to parse the file, assuming you call it something like
`practice.xml`

```elixir
{xml, _rest} = :xmerl_scan.file('practice.xml')
```

Demonstrating again that when interacting with the Erlang libraries, you should
recall to use character lists not binaries. That said, if you _do_ use a binary
here it won't actually fail.

Now to perform the query:

```elixir
:xmerl_xpath.string('/*/Paper[@refNum="2"]', xml)
```

This will net you back the slightly massive looking:

```elixir
[
  {:xmlElement, :Paper, :Paper, [], {:xmlNamespace, [], []}, [References: 1], 4,
   [
     {:xmlAttribute, :refNum, [], [], [], [Paper: 4, References: 1], 1, [], '2',
      false}
   ],
   [
     {:xmlText, [Paper: 4, References: 1], 1, [], '\n    ', :text},
     {:xmlElement, :Title, :Title, [], {:xmlNamespace, [], []},
      [Paper: 4, References: 1], 2, [],
      [
        {:xmlText, [Title: 2, Paper: 4, References: 1], 1, [],
         'Harmonic Crystal Frequencies and Light-Saber Characteristics: Review',
         :text}
      ], [], ".", :undeclared},
     {:xmlText, [Paper: 4, References: 1], 3, [], '\n    ', :text},
     {:xmlElement, :Authors, :Authors, [], {:xmlNamespace, [], []},
      [Paper: 4, References: 1], 4, [],
      [
        {:xmlText, [Authors: 4, Paper: 4, References: 1], 1, [], '\n      ',
         :text},
        {:xmlElement, :Author, :Author, [], {:xmlNamespace, [], []},
         [Authors: 4, Paper: 4, References: 1], 2,
         [
           {:xmlAttribute, :name, [], [], [],
            [Author: 2, Authors: 4, Paper: 4, References: 1], 1, [],
            'A. Skywalker', false}
         ], [], [], ".", :undeclared},
        {:xmlText, [Authors: 4, Paper: 4, References: 1], 3, [], '\n      ',
         :text},
        {:xmlElement, :Author, :Author, [], {:xmlNamespace, [], []},
         [Authors: 4, Paper: 4, References: 1], 4,
         [
           {:xmlAttribute, :name, [], [], [],
            [Author: 4, Authors: 4, Paper: 4, References: 1], 1, [],
            'O. Kenobi', false}
         ], [], [], ".", :undeclared},
        {:xmlText, [Authors: 4, Paper: 4, References: 1], 5, [], '\n      ',
         :text},
        {:xmlElement, :Author, :Author, [], {:xmlNamespace, [], []},
         [Authors: 4, Paper: 4, References: 1], 6,
         [
           {:xmlAttribute, :name, [], [], [],
            [Author: 6, Authors: 4, Paper: 4, References: 1], 1, [], 'A. Tano',
            false}
         ], [], [], ".", :undeclared},
        {:xmlText, [Authors: 4, Paper: 4, References: 1], 7, [], '\n    ',
         :text}
      ], [], ".", :undeclared},
     {:xmlText, [Paper: 4, References: 1], 5, [], '\n  ', :text}
   ], [], ".", :undeclared}
]
```

This is a slightly intimidating wall of data. Within it, you can see the
pieces that matter to you. We have the title of the paper, as well as the
authors. This is a good start, but what if you want a list of _just_ the names
of the authors?

```elixir
:xmerl_xpath.string('/*/Paper[@refNum="2"]/Authors/Author', xml)
```

This will get you the tags. To be fair, you can just index into the tuples to
get the values you want. But that's probably a little brittle. What makes more
sense is to use the `string()` function in the XPath:

```elixir
:xmerl_xpath.string('string(/*/Paper[@refNum="2"]/Authors/Author/@name)', xml)
```

But if you try this, you only get back one name. We can combine some of what
we've learned though to enumerate and get the names back easily:

```elixir
:xmerl_xpath.string('/*/Paper[@refNum="2"]/Authors/Author/@name', xml)
  |> Enum.map(fn el ->
    :xmerl_xpath.string('string(/*)', el)
  end)
```

Which gives us:

```elixir
[
  {:xmlObj, :string, 'A. Skywalker'},
  {:xmlObj, :string, 'O. Kenobi'},
  {:xmlObj, :string, 'A. Tano'}
]
```

This works because we get the exact node that we want, then we iterate over the
group and simply apply the `string` function to that node. Using `/*` is
necessary because the node is now technically the root. This allows us to avoid
needing to use indices to access items.

Another common operation you might like to perform is to find something
conditionally. For example, all the papers that were authored by a specific
individual. This is somewhat trickier:

```elixir
:xmerl_xpath.string('string(/*/Paper[descendant::Authors/Author[@name="L. Skywalker"]]/Title)', xml)
```

Here we're using the conditional selection `Node[criterion]`. This would allow
us to select e.g. all the nodes with a specific property. Then we use the
`descendant::` qualifier to define the criterion as being on the children of the
paper. Calling string on the title merely retrieves the desired datum.

For a more complex condition, let's say that we want to select all the papers
that were authored by A. Skywalker, either in name or in aka:

```elixir
condition_1 = '/*/Paper[descendant::Authors/Author[@name="A. Skywalker"]]/Title'
condition_2 = '/*/Paper[descendant::Authors/Author[@aka="A. Skywalker"]]/Title'
:xmerl_xpath.string('#{condition_1} | #{condition_2}', xml)
```

This can again be used with the mapping and string selection to get the titles
in a friendlier to access format, ala:

```elixir
:xmerl_xpath.string('#{condition_1} | #{condition_2}', xml)
    |> Enum.map(fn el ->
        :xmerl_xpath.string('string(/*)', el)
    end)
```

### Conclusion

This is a really quick survey of the experimentation that I did to get some
useful XPath queries written. Hopefully these are helpful to you in dealing with
any XML that is returned.

If you find that you want to do something and need a reference, then I can
recommend the [specification](https://www.w3.org/TR/2017/REC-xpath-31-20170321/#id-path-expressions) for XPath.

It's a little dense, but you should be able to use the reference to come up with
anything that can be done.

### References

https://en.wikipedia.org/wiki/XML#Pull_parsing
https://www.w3.org/TR/2008/REC-xml-20081126
https://www.erlang.org/doc/man/xmerl
https://starwars.fandom.com/wiki/Main_Page
https://www.w3.org/TR/2017/REC-xpath-31-20170321/
