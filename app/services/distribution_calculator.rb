class DistributionCalculator
  ROLL_TYPES = {
    'to hit shooting' => lambda { |params, number_of_dice|
      ballistic_skill = params['bs'].to_i
      fail if ballistic_skill > 5
      roll_needed = 7 - ballistic_skill

      roll_result = roll_d6(number_of_dice)
      successes =
        roll_result.
        select { |roll| roll >= roll_needed }.
        count
      successes += reroll_dice(roll_result, successes, params['reroll'], roll_needed) unless params['reroll'].nil?
      successes
      #extras = reroll_dice(roll_result, successes, params['reroll'], roll_needed) unless params['reroll'].nil?
      #ap successes: successes, extras: extras

      #successes + extras
    },

    'to hit assaulting' => lambda { |params, number_of_dice|
      attackers_ws = params['attackers ws']
      defenders_ws = params['defenders ws']

      roll_needed =
        if attackers_ws > defenders_ws
          3
        elsif attackers_ws <= defenders_ws * 2
          4
        else
          5
        end

      roll_result = roll_d6(number_of_dice)
      successes =
        roll_result.
        select { |roll| roll >= roll_needed }.
        count
      successes += reroll_dice(roll_result, successes, params['reroll'], roll_needed) unless params['reroll'].nil?

      successes
    },

    'to wound' => lambda { |params, number_of_dice|
      strength = params['strength']
      toughness = params['toughness']
      difference = strength - toughness
      roll_needed =
        if difference >= -2
          [4 - difference, 2].max
        elsif difference == -3
          -2
        else
          0
        end

      roll_result = roll_d6(number_of_dice)
      successes =
        roll_result.
        select { |roll| roll >= roll_needed }.
        count
      successes += reroll_dice(roll_result, successes, params['reroll']) unless params['reroll'].nil?

      successes
    },

    'armor penetration' => lambda { |params, number_of_dice|
      strength = params['strength']
      armor_value = params['armor value']

      roll_2d6(number_of_dice).
        select { |roll| roll + strength >= armor_value }.
        count
    },

    'save' => lambda { |params, number_of_dice|
      save = params['save']
      roll_d6(number_of_dice).
        select { |roll| roll < save }.
        count
    }
  }
  
  def initialize(json)
    puts json
  end
end
