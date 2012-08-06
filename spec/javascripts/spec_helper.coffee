# Each of the pages that have tests need to be defined here.
# You must invoked runOnCallbacks(pageName) in the beforeEach of the spec.
window.pages = ['collections', 'thresholds', 'layers', 'reminders', 'importWizard']

String::capitalize = -> "#{@[0].toUpperCase()}#{@.substring(1)}"

for page in pages
  do (page) ->
    callbacksName = "#{page}Callbacks"
    window[callbacksName] = []
    window["on#{page.capitalize()}"] = (callback) -> window[callbacksName].push(callback)

window.runOnCallbacks = (page) -> callback() for callback in window["#{page}Callbacks"]

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
