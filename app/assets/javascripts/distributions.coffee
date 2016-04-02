# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

class MathHammer.DistributionForm
  constructor: (@props) ->
    window.view_model = this
    throw new Error unless (@ROLL_TYPES = @props.ROLL_TYPES)

    @new_roll_type = ko.observable(@ROLL_TYPES.first)

    @ajax_params = {
      times_to_roll: ko.observable(100000)
      tests: ko.observableArray [
        {
          number_of_dice: ko.observable 1
          rolls: ko.observableArray []
        }
      ]
    }

    @distribution = ko.observable ''

  perform_calculation: (data, event) =>
    console.log ko.toJS(@ajax_params)

    @distribution('Loading...')
    $.post(
      '/distributions',
      ko.toJS(@ajax_params),
      (data) =>
        if !!data.success
          @distribution(data.distribution)
        else
          alert data
    )


    event.preventDefault() && false

  add_roll: =>
    new_test = { roll_type: @new_roll_type() }

    switch @new_roll_type()
      when 'to hit shooting'
        @ajax_params.tests()[0].rolls.push $.extend new_test, {
          params: {
            ballistic_skill: ko.observable
          }
        }
      when 'to hit assaulting'
        @ajax_params.tests()[0].rolls.push $.extend new_test, {
          params: {
            attackers_ws: ko.observable
            defenders_ws: ko.observable
          }
        }
      when 'to wound'
        @ajax_params.tests()[0].rolls.push $.extend new_test, {
          params: {
            strength: ko.observable
            toughness: ko.observable
          }
        }
      when 'armor penetration'
        @ajax_params.tests()[0].rolls.push $.extend new_test, {
          params: {
            strength: ko.observable
            armor_value: ko.observable
          }
        }
      when 'save'
        @ajax_params.tests()[0].rolls.push $.extend new_test, {
          params: {
            save: ko.observable
          }
        }
      else
        throw new Error('unknown roll type')

$ ->
  target = $('#distribution-new')
  props = target.attr('knockout_props')
  parsed_props = if !!props then JSON.parse(props) else {}
  ko.applyBindings(new MathHammer.DistributionForm(parsed_props), target[0])
