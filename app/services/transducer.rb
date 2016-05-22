class Transducer
  def initialize(list, transforms = [])
    @list = list
    @transforms = transforms
  end

  def map(mapper)
    @transforms.push Transducer.mapping(mapper)
    self
  end

  def filter(filterer)
    @transforms.push Transducer.filtering(filterer)
    self
  end

  def reduce(combiner, initial_value)
    transducer = Transducer.compose(@transforms)
    reducer = transducer.(combiner)
    @list.inject(initial_value, &reducer)
  end

  def self.compose (lambdas, accumulator = nil)
    return accumulator if lambdas.empty?

    new_accumulator =
      if accumulator.present?
        lambda { |params| lambdas[-1].(accumulator.(params)) }
      else
        lambdas[-1]
      end

    Transducer.compose(lambdas[0...-1], new_accumulator)
  end

  def self.mapping(transform)
    lambda { |combine|
      lambda { |accumulator, item|
        combine.(accumulator, transform.(item))
      }
    }
  end

  def self.filtering(predicate)
    lambda { |combine|
      lambda { |accumulator, item|
        if predicate.(item)
          combine.(accumulator, item)
        else
          accumulator
        end
      }
    }
  end
end
