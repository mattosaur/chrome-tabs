$ = jQuery

tabTemplate = '''
  <div class="chrome-tab">
    <div class="chrome-tab-background">
      <svg version="1.1" xmlns="http://www.w3.org/2000/svg"><defs><symbol id="topleft" viewBox="0 0 214 29" ><path d="M14.3 0.1L214 0.1 214 29 0 29C0 29 12.2 2.6 13.2 1.1 14.3-0.4 14.3 0.1 14.3 0.1Z"/></symbol><symbol id="topright" viewBox="0 0 214 29"><use xlink:href="#topleft"/></symbol><clipPath id="crop"><rect class="mask" width="100%" height="100%" x="0"/></clipPath></defs><svg width="50%" height="100%" transfrom="scale(-1, 1)"><use xlink:href="#topleft" width="214" height="29" class="chrome-tab-background"/><use xlink:href="#topleft" width="214" height="29" class="chrome-tab-shadow"/></svg><g transform="scale(-1, 1)"><svg width="50%" height="100%" x="-100%" y="0"><use xlink:href="#topright" width="214" height="29" class="chrome-tab-background"/><use xlink:href="#topright" width="214" height="29" class="chrome-tab-shadow"/></svg></g></svg>
    </div>
    <div class="chrome-tab-favicon"></div>
    <div class="chrome-tab-title"></div>
    <div class="chrome-tab-close"></div>
  </div>
'''

defaultNewTabData =
  title: 'New Tab'
  favicon: ''
  data: {}

animationStyle = document.createElement 'style'

chromeTabs =

  init: (options) ->
    $.extend options.$shell.data(), options
    options.$shell.prepend animationStyle
    options.$shell
      .find('.chrome-tab').each ->
        $(@).data().tabData = { data: {} }

    render = ->
      chromeTabs.render options.$shell

    $(window).resize render
    render()

  render: ($shell) ->
    chromeTabs.fixTabSizes $shell
    chromeTabs.fixZIndexes $shell
    chromeTabs.setupEvents $shell
    chromeTabs.setupSortable $shell
    $shell.trigger('chromeTabRender')

  setupSortable: ($shell) ->
    $tabs = $shell.find('.chrome-tabs')

    $tabs.sortable
      axis: 'x'
      tolerance: 'pointer'
      cancel: '.chrome-tab-close'

      start: (e, ui) ->
        ui.item.addClass 'ui-sortable-draggable-item'
        $shell.addClass 'chrome-tabs-sorting'
        chromeTabs.setupTabClones $shell, ui.item
        chromeTabs.fixZIndexes $shell
        if not $(ui.item).hasClass('chrome-tab-current')
          $tabs.sortable('option', 'zIndex',  $(ui.item).data().zIndex)
        else
          $tabs.sortable('option', 'zIndex',  $tabs.length + 40)

      stop: (e, ui) ->
        $('.ui-sortable-draggable-item').removeClass 'ui-sortable-draggable-item'
        $shell.removeClass 'chrome-tabs-sorting'
        chromeTabs.cleanUpTabClones $shell
        chromeTabs.setCurrentTab $shell, $(ui.item)

      change: (e, ui) ->
        placeholderIndex = ui.placeholder.index()
        placeholderIndex -= 1 if ui.helper.index() <= placeholderIndex
        chromeTabs.animateSort $shell, placeholderIndex

  animateSort: ($shell, newPlaceholderIndex) ->
    $clone = $shell.find('.chrome-tabs.chrome-tabs-clone')
    $placeholder = $clone.find('.ui-sortable-placeholder')
    placeholderIndex = $placeholder.index()
    delta = newPlaceholderIndex - placeholderIndex
    if delta is -1
      if newPlaceholderIndex - 1 < 0
        $clone.prepend $placeholder
      else
        $($clone.find('.chrome-tab').get(newPlaceholderIndex - 1)).after $placeholder
    else if delta is 1
      $($clone.find('.chrome-tab').get(newPlaceholderIndex)).after $placeholder

  setupTabClones: ($shell) ->
    $lastClone = $shell.find('.chrome-tabs.chrome-tabs-clone')
    $tabsContainer = $shell.find('.chrome-tabs').first()
    $clone = $tabsContainer.clone().addClass('chrome-tabs-clone')
    $clone.find('.ui-sortable-helper, .ui-sortable-draggable-item').remove()
    $clone.find('.chrome-tab').css('position', '')
    if $lastClone.length
      $lastClone.replaceWith $clone
    else
      $tabsContainer.after $clone

  cleanUpTabClones: ($shell) ->
    $shell.find('.chrome-tabs.chrome-tabs-clone').remove()

  fixTabSizes: ($shell) ->
    $tabs = $shell.find('.chrome-tab')
    margin = (parseInt($tabs.first().css('marginLeft'), 10) + parseInt($tabs.first().css('marginRight'), 10)) or 0
    width = $shell.width() - 50
    width = (width / $tabs.length) - margin
    width = Math.max($shell.data().minWidth, Math.min($shell.data().maxWidth, width))
    $tabs.css width: width

    setTimeout ->
      chromeTabs.setupAnimationStyles $shell

  setupAnimationStyles: ($shell) ->
    styleHTML = ''
    offsetLeft = $shell.find('.chrome-tabs').offset().left
    $tabs = $shell.find('.chrome-tabs:not(.chrome-tabs-clone) .chrome-tab')
    $tabs.each (i) ->
      $tab = $ @
      left = $tab.offset().left - offsetLeft - parseInt($tabs.first().css('marginLeft'), 10)
      styleHTML += """
        .chrome-tabs-clone .chrome-tab:nth-child(#{ i + 1 }) {
          left: #{ left }px
        }
      """
    animationStyle.innerHTML = styleHTML

  fixZIndexes: ($shell) ->
    $tabs = $shell.find('.chrome-tab')
    $tabs.each (i) ->
      $tab = $ @
      zIndex = $tabs.length - i
      zIndex = $tabs.length + 40 if $tab.hasClass('chrome-tab-current')
      $tab.css zIndex: zIndex
      $tab.data zIndex: zIndex

  setupEvents: ($shell) ->
    $shell.unbind('dblclick').bind 'dblclick', ->
      chromeTabs.addNewTab $shell

    $shell.unbind('mouseup').bind 'mouseup', (e) ->
      if e.which == 2 and e.target.className != 'chrome-tab-title'
        return chromeTabs.addNewTab($shell)
      return

    $shell.find('.chrome-tab').each ->
      $tab = $ @

      $tab.unbind('click').click ->
        chromeTabs.setCurrentTab $shell, $tab

      $tab.unbind('mouseup').mouseup (e) ->
        if e.which == 2
          return chromeTabs.closeTab($shell, $tab)
        return

      $tab.find('.chrome-tab-close').unbind('click').click ->
        chromeTabs.closeTab $shell, $tab

  addNewTab: ($shell, newTabData) ->
    $newTab = $ tabTemplate
    $shell.find('.chrome-tabs').append $newTab
    tabData = $.extend true, {}, defaultNewTabData, newTabData
    chromeTabs.updateTab $shell, $newTab, tabData
    chromeTabs.setCurrentTab $shell, $newTab

  setCurrentTab: ($shell, $tab) ->
    $shell.find('.chrome-tab-current').removeClass('chrome-tab-current')
    $tab.addClass('chrome-tab-current')
    chromeTabs.render $shell

  closeTab: ($shell, $tab) ->
    if $tab.hasClass('chrome-tab-current')
      if $tab.prev().length
        chromeTabs.setCurrentTab $shell, $tab.prev()
      else if $tab.next().length
        chromeTabs.setCurrentTab $shell, $tab.next()
    $tab.remove()
    chromeTabs.render $shell

  updateTab: ($shell, $tab, tabData) ->
    $tab.find('.chrome-tab-title').html tabData.title
    $tab.find('.chrome-tab-favicon').css backgroundImage: "url('#{tabData.favicon}')"
    $tab.data().tabData = tabData

window.chromeTabs = chromeTabs
