# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

class MathHammer.DistributionForm
  constructor: (@props) ->
    throw new Error unless (@ROLL_TYPES = @props.ROLL_TYPES)
    console.log @ROLL_TYPES

  perform_calculation: (data, event) =>
    console.log @props
    event.preventDefault() && false

$ ->
  target = $('#distribution-new')
  props = target.attr('knockout_props')
  parsed_props = if !!props then JSON.parse(props) else {}
  ko.applyBindings(new MathHammer.DistributionForm(parsed_props), target[0])
