{View} = require 'atom'

module.exports = class IconView extends View
  @content: (params) ->
    @div class: 'icon-alert', title: params.title
