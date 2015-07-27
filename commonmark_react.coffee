
dependencies =
  React: "react"
  commonmark: "commonmark"
  $: "jquery"

# copy/pastable require.js hacks
define (_v for _, _v of dependencies), () ->
  _i=0; @[_k] = arguments[_i++] for _k of dependencies
#/hacks

  d = React.DOM

  _parser = commonmark.Parser()

  TagTypes =
    BLOCKQUOTE: 'BlockQuote'
    CODE: 'Code'
    CODEBLOCK: 'CodeBlock'
    DOCUMENT: 'Document'
    EMPH: 'Emph'
    HARDBREAK: 'Hardbreak'
    HEADER: 'Header'
    HORIZONTALRULE: 'HorizontalRule'
    HTML: 'Html'
    HTMLBLOCK: 'HtmlBlock'
    IMAGE: 'Image'
    ITEM: 'Item'
    LINK: 'Link'
    LIST: 'List'
    PARAGRAPH: 'Paragraph'
    SOFTBREAK: 'Softbreak'
    STRONG: 'Strong'
    TEXT: 'Text'

  AtomicTypes = [
    TagTypes.CODE
    TagTypes.CODEBLOCK
    TagTypes.HARDBREAK
    TagTypes.HORIZONTALRULE
    TagTypes.HTML
    TagTypes.HTMLBLOCK
    TagTypes.HTMLBLOCK
    TagTypes.IMAGE
    TagTypes.SOFTBREAK
    TagTypes.TEXT
  ]

  _build_tree = (walker, cur_node, parent, depth=0) ->
    while current = walker.next()
      if not current?
        return
      {entering, node} = current
      console.log depth, entering, node.type, node.type in AtomicTypes
      if entering
        new_node =
          node: node
          children: []
          type: node.type
        cur_node.children.push new_node
        if node.type not in AtomicTypes
          _build_tree walker, new_node, cur_node, depth+1
      else
        return

  build_tree = (raw) ->
    root = _parser.parse raw
    walker = root.walker()
    tree =
      node: root
      children: []
    _build_tree walker, tree, null
    return tree


  _render_children = (children) ->
    for node in children
      render_node node

  render_node = (tree_node) ->
    options = safe: false
    {node, children} = tree_node
    switch node.type
      when TagTypes.TEXT
        d.span
          className: "cm-react-text"
          node.literal
      when TagTypes.SOFTBREAK
        d.span
          className: "cm-react-softbreak"
          "\n"
      when TagTypes.HARDBREAK
        d.br
          className: "cm-react-hardbreak"
      when TagTypes.EMPH
        d.em
          className: "cm-react-empl"
          _render_children children
      when TagTypes.STRONG
        d.strong
          className: "cm-react-string"
          _render_children children
      when TagTypes.HTML, TagTypes.HTMLBLOCK
        if options.safe
          d.span {}, '<!-- raw HTML omitted -->'
        else
          d.span {}, "HTML #{node.literal}"
      when TagTypes.LINK
        d.a
          className: "cm-react-link"
          href: node.destination
          title: node.title
          _render_children children
      when TagTypes.IMAGE
        d.img
          className: "cm-react-image"
          src: node.destination
          title: node.title
      when TagTypes.CODE
        d.code
          className: "cm-react-code"
          node.literal
      when TagTypes.DOCUMENT
        d.div
          className: "cm-react-document"
          _render_children children
      when TagTypes.PARAGRAPH
        d.p
          className: "cm-react-p"
          _render_children children
      when TagTypes.BLOCKQUOTE
        d.blockquote
          className: "cm-react-blockquote"
          _render_children children
      when TagTypes.ITEM
        d.li
          className: "cm-react-item"
          _render_children children
      when TagTypes.LIST
        elementClass = if node.listType == 'Bullet' then d.ul else d.ol
        elementClass
          className: "cm-react-list"
          _render_children children
      when TagTypes.HEADER
        tagname = 'h' + node.level
        d[tagname]
          className: "cm-react-header"
          _render_children children
      when TagTypes.CODEBLOCK
        info_words = if node.info then node.info.split(/\s+/) else []
        language = "code"
        if info_words.length > 0 and info_words[0].length > 0
          language = info_words[0]
        d.pre
          className: "cm-react-codeblock-wrapper"
          d.code
            className: "cm-react-codeblock"
            node.literal
      when TagTypes.HORIZONTALRULE
        d.hr
          className: "cm-horizontal-rule"
      else
        throw 'Unknown node type ' + node.type

  CommonmarkElement = React.createFactory React.createClass
    displayName: "CommonmarkElement"

    propTypes:
      raw: React.PropTypes.string.isRequired

    getInitialState: -> {}

    render: ->
      # tree = build_tree @props.raw
      tree = build_tree @props.raw
      console.log tree
      content = render_node tree
      d.div {},
        content
