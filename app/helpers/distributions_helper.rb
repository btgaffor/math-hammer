module DistributionsHelper
  def distribution_new_props
    {
      ROLL_TYPES: DistributionCalculator::ROLL_TYPES.keys
    }.to_json
  end
end
