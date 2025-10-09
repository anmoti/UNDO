module MeasurementsHelper
  def estimate_bod(turbidity)
    return nil unless turbidity.is_a?(Numeric) && turbidity >= 0

    # 285.9265 * T ^ 0.49050 + 1152.7511 * ( T ^ 5.0 / ( 23.0836 ^ 5.0 + T ^ 5.0 ) )

    t = 730.0 - turbidity.to_f

    part1 = 285.9265 * (t ** 0.49050)

    part2Numerator = t ** 5.0
    part2Denominator = (23.0836 ** 5.0) + (t ** 5.0)

    return part1 if part2Denominator.zero?

    part2 = 1152.7511 * (part2Numerator / part2Denominator)

    result = part1 + part2

    format("%.2f", result.round(2)).to_f
  end

  def estimate_cod(turbidity)
    return nil unless turbidity.is_a?(Numeric) && turbidity >= 0

    # 493.65 * (t ** 0.2536) + 49.05

    t = 730.0 - turbidity.to_f

    result = 493.65 * (t ** 0.2536) + 49.05

    format("%.2f", result.round(2)).to_f
  end
end
