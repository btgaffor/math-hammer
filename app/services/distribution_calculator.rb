class DistributionCalculator
  ROLL_TYPES = {
    'to hit shooting' => lambda { |params, number_of_dice|
      ballistic_skill = params['ballistic_skill'].to_i
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
    }.curry,

    'to hit assaulting' => lambda { |params, number_of_dice|
      attackers_ws = params['attackers_ws'].to_i
      defenders_ws = params['defenders_ws'].to_i

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
    }.curry,

    'to wound' => lambda { |params, number_of_dice|
      strength = params['strength'].to_i
      toughness = params['toughness'].to_i
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
      successes += reroll_dice(roll_result, successes, params['reroll'], roll_needed) unless params['reroll'].nil?

      successes
    }.curry,

    'armor penetration' => lambda { |params, number_of_dice|
      strength = params['strength'].to_i
      armor_value = params['armor_value'].to_i

      roll_d6(number_of_dice).
        select { |roll| roll + strength >= armor_value }.
        count
    }.curry,

    'save' => lambda { |params, number_of_dice|
      save = params['save'].to_i
      roll_d6(number_of_dice).
        select { |roll| roll < save }.
        count
    }.curry
  }
  
  def initialize(input)
    @times_to_roll = input['times_to_roll'].to_i
    @tests = input['tests']
  end

  def run
    string_rv = ''
    @tests.each do |_index, test|
      distribution = Hash.new { |h,k| h[k] = 0.0 }

      number_of_dice = test['number_of_dice'].to_i

      # create pipe to pass rolls through
      roll_pipe =
        test['rolls'].
        map { |_index, roll_definition| ROLL_TYPES[roll_definition['roll_type']].(roll_definition['params']) }.
        reduce(self.class.identity) { |memo, roll_lambda| self.class.pipe(memo, roll_lambda) }

      @times_to_roll.times do
        distribution[roll_pipe.(number_of_dice)] += 1
      end
      puts distribution
      number_of_dice.downto(0).reduce(0) do |memo, n|
        this_percent = (distribution[n] / @times_to_roll) * 100
        rv = memo + this_percent
        string_rv << (sprintf '%02d %6.2f%% %6.2f%% %s', n, this_percent, rv, '#' * ((distribution[n] / @times_to_roll) * 100))
        string_rv << '<br>'
        rv
      end
    end
    string_rv
  end

private

  def self.pipe (lambda1, lambda2)
    lambda { |*params| lambda2.(lambda1.(*params)) }
  end

  def self.identity
    lambda { |x| x }
  end

  def self.roll_d6(number_of_dice)
    (0...number_of_dice).map { rand(6) + 1 }
  end

  def self.roll_2d6(number_of_rolls)
    (0...number_of_rolls).map { rand(6) + 1 + rand(6) + 1}
  end

  def self.reroll_dice(original_rolls, successes, dice_to_reroll, roll_needed)
    number_to_reroll = 0
    if dice_to_reroll == 'all'
      number_to_reroll = original_rolls.count - successes
    elsif dice_to_reroll == 'ones'
      number_to_reroll =
        original_rolls.
        select { |roll| roll == 1 }.
        count
    end

    rv = 0
    if number_to_reroll > 0
      rv =
        self.roll_d6(number_to_reroll).
        select { |roll| roll >= roll_needed }.
        count
    end

    rv
  end

end
