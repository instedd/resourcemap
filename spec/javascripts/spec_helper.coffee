# Each of the pages that have tests need to be defined here.
# You must invoked runOnCallbacks(pageName) in the beforeEach of the spec.
window.pages = ['collections', 'thresholds', 'layers', 'reminders', 'importWizard', 'channels']

String::capitalize = -> "#{@[0].toUpperCase()}#{@.substring(1)}"

window.runOnCallbacks = (page) -> window["run#{page.capitalize()}Callbacks"]()

window.google = {}
window.google.maps = {}
class window.google.maps.OverlayView
class window.google.maps.Geocoder
class window.google.maps.Size
class window.google.maps.Point
class window.google.maps.MarkerImage
class window.google.maps.LatLng
  constructor: (@lati, @long, @noWrap) ->

  lat: ->
    @lati

  lng: ->
    @long

class window.google.maps.LatLngBounds
  constructor: (@sw, @ne) ->

  getNorthEast: ->
    @ne
  getSouthWest: ->
    @sw

class window.google.maps.Marker
  setIcon: -> 'setIcon'
  setShadow: -> 'setShadow'


window.__ = (x) -> x
