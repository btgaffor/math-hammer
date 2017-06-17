class DistributionCalculator
  ROLL_TYPES = {
    'to hit' => lambda { |params, number_of_dice|
      skill = params['skill'].to_i
      roll_d6(number_of_dice, ->(roll) { roll >= skill }, params['reroll'])
    }.curry,

    'to wound' => lambda { |params, number_of_dice|
      strength = params['strength'].to_i
      toughness = params['toughness'].to_i

      roll_needed =
        if strength >= toughness * 2
          2
        elsif strength > toughness
          3
        elsif strength <= toughness / 2
          6
        elsif strength < toughness
          5
        else
          4
        end

      roll_d6(number_of_dice, ->(roll) { roll >= roll_needed }, params['reroll'])
    }.curry,

    'save' => lambda { |params, number_of_dice|
      save = params['save'].to_i - params['armor_piercing'].to_i
      roll_d6(number_of_dice, ->(roll) { roll < save }, params['reroll'])
    }.curry,

    'damage' => lambda { |params, number_of_dice|
      target_wounds = params['target_wounds'].to_i
      damage = params['damage']

      d_index = damage.index('d')
      if d_index
        rolls = damage[0...d_index].to_i
        sides = damage[d_index + 1..-1].to_i
      end

      wounds_inflicted = 0
      current_target_wounds = target_wounds

      number_of_dice.times do
        wounds_to_apply =
          if d_index
            (0...rolls).map { rand(sides) + 1 }.reduce(:+)
          else
            damage.to_i
          end

        if wounds_to_apply < current_target_wounds
          current_target_wounds -= wounds_to_apply
          wounds_inflicted += wounds_to_apply
        else
          wounds_inflicted += current_target_wounds # can't spill over
          current_target_wounds = target_wounds # assume there's another model
        end
      end

      wounds_inflicted
    }.curry
  }.freeze

  def initialize(input)
    @times_to_roll = input['times_to_roll'].to_i
    @distribution_type = input['distribution_type']
    @tests = input['tests']
  end

  def run
    if @distribution_type == 'offensive'
      run_offensive
    elsif @distribution_type == 'defensive'
      run_defensive
    end
  end

  def run_offensive
    string_rv = ''
    @tests.each do |_index, test|
      roll_pipe = roll_pipe(test['rolls'].values)

      distribution =
        Transducer.new(Array.new(@times_to_roll) { |i| roll_xdy(test['number_of_dice']) }).
        map(lambda { |number| roll_pipe.(number) }).
        reduce(lambda { |memo, result| memo[result] += 1; memo }, Hash.new { |h,k| h[k] = 0.0 })

      d_index = test['number_of_dice'].index('d')
      max_number_of_dice =
        if d_index
          test['number_of_dice'][0...d_index].to_i * test['number_of_dice'][d_index + 1..-1].to_i
        else
          test['number_of_dice'].to_i
        end

      damage = @tests["0"]["rolls"].values.find { |roll| roll["roll_type"] == "damage" }["params"]["damage"]
      if damage
        d_index = damage.index('d')
        max_damage =
          if d_index
            damage[0...d_index].to_i * damage[d_index + 1..-1].to_i
          else
            damage.to_i
          end
        max_number_of_dice *= max_damage
      end

      max_number_of_dice.downto(0).reduce(0) do |memo, n|
        this_percent = (distribution[n] / @times_to_roll) * 100
        rv = memo + this_percent
        string_rv << (sprintf '%02d %6.2f%% %6.2f%% %s', n, this_percent, rv, '#' * this_percent)
        string_rv << '<br>'
        rv
      end
    end
    string_rv
  end

  def run_defensive
    string_rv = ''
    @tests.each do |_index, test|
      target_wounds = test['target_wounds'].to_i
      roll_pipe = roll_pipe(test['rolls'].values)

      max_shots = 0

      distribution =
        Transducer.new(Array.new(@times_to_roll, target_wounds)).
        map(lambda { |number|
          wound_count = 0
          total_shots = 0
          while wound_count < target_wounds do
            total_shots += 1
            wound_count += roll_pipe.(1)
          end

          max_shots = total_shots if total_shots > max_shots

          total_shots
        }).
        reduce(lambda { |memo, result| memo[result] += 1; memo }, Hash.new { |h,k| h[k] = 0.0 })

      (1..max_shots).reduce(0) do |memo, n|
        this_percent = (distribution[n] / @times_to_roll) * 100
        rv = memo + this_percent
        string_rv << (sprintf '%02d %6.2f%% %6.2f%% %s', n, this_percent, rv, '#' * this_percent)
        string_rv << '<br>'
        rv
      end
    end
    string_rv
  end

private

  def roll_xdy(input)
    d_index = input.index('d')
    if d_index
      rolls = input[0...d_index].to_i
      sides = input[d_index + 1..-1].to_i
      (0...rolls).map { rand(sides) + 1 }.reduce(:+)
    else
      input.to_i
    end
  end

  def roll_pipe(rolls)
    Transducer.new(rolls).
      map(lambda { |roll_definition| ROLL_TYPES[roll_definition['roll_type']].(roll_definition['params']) }).
      reduce(lambda { |memo, roll_proc| if memo.present? then self.class.pipe(memo, roll_proc) else roll_proc end }, nil)
  end

  def self.pipe (lambda1, lambda2)
    lambda { |*params| lambda2.(lambda1.(*params)) }
  end

  def self.roll_d6(number_of_dice, roll_needed, reroll)
    roll_result = (0...number_of_dice).map { rand(6) + 1 }
    successes =
      roll_result.
      select(&roll_needed).
      count
    successes += reroll_dice(roll_result, successes, reroll, roll_needed) if reroll.present?
    successes
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

    if number_to_reroll > 0
      roll_d6(number_to_reroll, roll_needed, nil)
    else
      0
    end
  end
end
