# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

class MathHammer.DistributionForm
  constructor: (@props) ->
    window.view_model = this
    throw new Error unless (@ROLL_TYPES = @props.ROLL_TYPES)

    @new_roll_type = ko.observable(@ROLL_TYPES.first)

    window.ajax_params = @ajax_params = {
      times_to_roll: ko.observable(100000)
      distribution_type: ko.observable('offensive')
      tests: ko.observableArray [
        {
          number_of_dice: ko.observable(1)
          rolls: ko.observableArray([])
        }
      ]
    }

    @is_offensive = ko.computed =>
      @ajax_params.distribution_type() == 'offensive'

    @is_defensive = ko.computed =>
      @ajax_params.distribution_type() == 'defensive'

    @distribution = ko.observable ''
    @reset()

  perform_calculation: (data, event) =>
    console.log ko.toJS(@ajax_params)

    @distribution('Loading...')
    $.post(
      '/distributions',
      ko.toJS(@ajax_params),
      (data) =>
        if !!data.success
          @distribution(data.distribution)
          $(".current-distribution")[0].scrollIntoView(true)
        else
          @distribution(data.error)
    )


    event.preventDefault() && false

  add_roll: =>
    @ajax_params.tests()[0].rolls.push @roll_to_add()

  add_before: (data) =>
    array = @ajax_params.tests()[0].rolls
    array.splice(array.indexOf(data), 0, @roll_to_add())

  roll_to_add: =>
    new_test = { roll_type: @new_roll_type() }

    params_to_add =
      switch @new_roll_type()
        when 'to hit'
          {
            params: {
              skill: ko.observable()
              reroll: ko.observable('none')
            }
          }
        when 'to wound'
          {
            params: {
              strength: ko.observable()
              toughness: ko.observable()
              reroll: ko.observable('none')
            }
          }
        when 'save'
          {
            params: {
              save: ko.observable()
              armor_piercing: ko.observable()
            }
          }
        when 'damage'
          {
            params: {
              target_wounds: ko.observable()
              damage: ko.observable()
            }
          }
        else
          throw new Error('unknown roll type')

    $.extend new_test, params_to_add


  remove_roll: (roll) =>
    @ajax_params.tests()[0].rolls.remove(roll)

  reset: =>
    @ajax_params.tests()[0].rolls([])

    @new_roll_type('to hit')
    @ajax_params.tests()[0].rolls.push @roll_to_add()

    @new_roll_type('to wound')
    @ajax_params.tests()[0].rolls.push @roll_to_add()

    @new_roll_type('save')
    @ajax_params.tests()[0].rolls.push @roll_to_add()

    @new_roll_type('damage')
    @ajax_params.tests()[0].rolls.push @roll_to_add()

$ ->
  target = $('#distribution-new')
  props = target.attr('knockout_props')
  parsed_props = if !!props then JSON.parse(props) else {}
  ko.applyBindings(new MathHammer.DistributionForm(parsed_props), target[0])
