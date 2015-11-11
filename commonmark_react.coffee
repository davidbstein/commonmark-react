
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

  SimpleTagToElem = {
    Emph: "em"
    Strong: "strong"
    Document: "div"
    Paragraph: "p"
    Blockquote: "blockquote"
    Item: "li"
  }

  class NodeTree
    constructor: (raw) ->
      root = _parser.parse raw
      walker = root.walker()
      @tree =
        node: root
        children: []
      @_build_tree walker, @tree, null
      @toc_elements = []
      @headings = []
      @react_element = @_render_react @tree, []

    get_react_element: -> @react_element

    get_toc_element: ->
      d.div className: "cm-table-of-contents",
        for [section_id, title] in @toc_elements
          d.div className: "cm-toc-item",
            d.a href: "#section-#{section_id}",
              d.div className: "cm-toc-item-section-id", section_id
              d.div className: "cm-toc-item-section-title", title

    _build_tree: (walker, cur_node, parent, depth=0) ->
      while current = walker.next()
        if not current?
          return
        {entering, node} = current
        if entering
          new_node =
            node: node
            children: []
            type: node.type
          cur_node.children.push new_node
          if node.type not in AtomicTypes
            @_build_tree walker, new_node, cur_node, depth+1
        else
          return

    _render_children: (children) ->
      for node in children
        @_render_react node

    _get_text_from_nodes: (nodes) ->
      return (n.node.literal for n in nodes).join(" ")

    _render_react: (tree_node) ->
      options = safe: false
      {node, children} = tree_node

      # atomic objects
      if node.type == TagTypes.SOFTBREAK
        d.span className: "cm-react-softbreak", "\n"
      else if node.type == TagTypes.HARDBREAK
        d.br className: "cm-react-hardbreak"
      else if node.type == TagTypes.HORIZONTALRULE
        d.hr className: "cm-horizontal-rule"

      # literals
      else if node.type == TagTypes.TEXT
        d.span className: "cm-react-text", node.literal
      else if node.type == TagTypes.CODE
        d.code className: "cm-react-code", node.literal
      else if node.type in [TagTypes.HTML, TagTypes.HTMLBLOCK]
        d.div className: "cm-react-html", dangerouslySetInnerHTML: __html: node.literal
      else if node.type == TagTypes.CODEBLOCK
        info_words = if node.info then node.info.split(/\s+/) else []
        language = "code"
        if info_words.length > 0 and info_words[0].length > 0
          language = info_words[0]
        d.pre className: "cm-react-codeblock-wrapper",
          d.code className: "cm-react-codeblock",
            node.literal

      # simple wrappers
      else if (tag = SimpleTagToElem[node.type])?
        tag = SimpleTagToElem[node.type]
        d[tag] className: "cm-react-#{tag}",
          @_render_children children

      # wrappers with configuration
      else if node.type == TagTypes.HEADER
        tagname = 'h' + node.level
        content = @_render_children children
        raw_text = @_get_text_from_nodes children
        section_id = undefined
        if 1 < node.level < 4
          @headings[node.level-2]?=0
          @headings[node.level-2]++
          @headings = @headings.slice(0, node.level-1)
          section_id = @headings.join('.')
          @toc_elements.push([section_id, raw_text])
        d[tagname]
          className: "cm-react-header"
          if section_id
            d.a
              name: "section-#{section_id}",
              className: "cm-section-id"
              "#{section_id}"
          content
      else if node.type == TagTypes.BLOCKQUOTE
        d.blockquote
          className: "cm-react-blockquote"
          @_render_children children
      else if node.type == TagTypes.LINK
        d.a
          className: "cm-react-link"
          href: node.destination
          title: node.title
          target: if node.destination?.substr(0, 1) != "#" then "_blank"
          @_render_children children
      else if node.type == TagTypes.IMAGE
        d.img
          className: "cm-react-image"
          src: node.destination
          title: node.title
      else if node.type == TagTypes.LIST
        elementClass = if node.listType == 'Bullet' then d.ul else d.ol
        elementClass
          className: "cm-react-list"
          @_render_children children

      # error mode
      else
        throw 'Unknown node type ' + node.type

  CommonmarkElement = React.createFactory React.createClass
    displayName: "CommonmarkElement"

    propTypes:
      raw: React.PropTypes.string.isRequired

    getInitialState: -> {}

    render: ->
      node_tree = new NodeTree @props.raw
      d.div {},
        if @props.showTableOfContents
          node_tree.get_toc_element()
        node_tree.get_react_element()
