###*
Page flow.

@class up.flow
###
up.flow = (->

  rememberSource = ($element) ->
    $element.attr("up-source", location.href)

  recallSource = ($element) ->
    $source = $element.closest("[up-source]")
    $source.attr("up-source") || location.href

  ###*
  Replaces elements on the current page with corresponding elements
  from a new page fetched from the server.

  The current and new elements must have the same CSS selector.

  @method up.replace
  @param {String|Element|jQuery} selectorOrElement
    The CSS selector to update. You can also pass a DOM element or jQuery element
    here, in which case a selector will be inferred from the element's class and ID.
  @param {String} url
    The URL to fetch from the server.
  @param {String} [options.history.url=url]
    An alternative URL to use for the browser's location bar and history.
  @param {String} [options.history.method='push']
  ###
  replace = (selectorOrElement, url, options) ->

    selector = null
    $target = null
    if up.util.isString(selectorOrElement)
      selector = selectorOrElement
      $target = $(selector)
      $target = up.util.$createElementFromSelector(selector) unless $target.length
    else
      selector = up.util.createSelectorFromElement($(selectorOrElement))
      $target = $(selectorOrElement)

    $target.addClass("up-loading")
    options = up.util.options(options, history: { url: url })

    up.util.get(url, selector: selector)
      .done (html) ->
        $target.removeClass("up-loading")
        implant(selector, html, options)
      .fail(up.util.error)

  ###*
  @method up.flow.implant
  @protected
  @param {String} selector
  @param {String} html
  @param {String} [options.history.url]
  @param {String} [options.history.method='push']
  @param {String} [options.transition]
  ###
  implant = (selector, html, options) ->
    $target = $(selector)
    options = up.util.options(options, history: { method: 'push' })
    # jQuery cannot construct transient elements that contain <html> or <body> tags,
    # so we're using the native browser API to grep through the HTML
    htmlElement = up.util.createElementFromHtml(html)
    if fragment = htmlElement.querySelector(selector)
      $fragment = $(fragment)
      up.bus.emit('fragment:destroy', $target)
      swapElements($target, $fragment, options.transition)
      title = htmlElement.querySelector("title")?.textContent # todo: extract title from header
      if options.history?.url
        document.title = title if title
        up.history[options.history.method](options.history.url)
        # Remember where the element came from so we can make
        # smaller page loads in the future (does this even make sense?).
        rememberSource($target)
      # The fragment is only ready after the history was (or wasn't) changed above
      up.bus.emit('fragment:ready', $fragment)

    else
      up.util.error("Could not find selector (#{selector}) in response (#{html})")

  swapElements = ($old, $new, transitionName) ->
    if up.util.isGiven(transitionName)
      if $old.is('body')
        up.util.error('Cannot apply transitions to body-elements')
      $new.insertAfter($old)
      up.transition($old, $new, transitionName).then -> $old.remove()
    else
      $old.replaceWith($new)


  ###*
  Replaces the given selector or element with a fresh copy
  fetched from the server.

  @method up.reload
  @param {String|Element|jQuery} selectorOrElement
  ###
  reload = (selectorOrElement) ->
    replace(selectorOrElement, recallSource($(selectorOrElement)))

  ###*
  Removes the given selector or element from the DOM tree.

  @method up.remove
  @param {String|Element|jQuery} selectorOrElement
  ###
  remove = (selectorOrElement) ->
    $(selectorOrElement).remove()

  replace: replace
  reload: reload
  remove: remove
  implant: implant

)()

up.replace = up.flow.replace
up.reload = up.flow.reload
up.remove = up.flow.remove