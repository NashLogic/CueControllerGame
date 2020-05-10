#! /usr/local/bin/ruby
#Source: https://gist.github.com/macmv/a31fb9381d0f46d949ee

require 'gosu'

class Circle
  attr_reader :columns, :rows

  def initialize(radius, colorR, colorG, colorB)
    @columns = @rows = radius * 2
    lower_half = (0...radius).map do |y|
      x = Math.sqrt(radius**2 - y**2).round
      right_half = "#{"#{colorR.chr}" * x}#{"#{0.chr}" * (radius - x)}"
      "#{right_half.reverse}#{right_half}"
    end.join
    blob0 = lower_half.reverse + lower_half
    blob0.gsub!(/./) { |alpha| "#{colorR.chr}#{colorG.chr}#{colorB.chr}#{alpha}"}
    lower_half = (0...radius).map do |y|
      x = Math.sqrt(radius**2 - y**2).round
      right_half = "#{"#{colorG.chr}" * x}#{"#{0.chr}" * (radius - x)}"
      "#{right_half.reverse}#{right_half}"
    end.join
    blob1 = lower_half.reverse + lower_half
    blob1.gsub!(/./) { |alpha| "#{colorR.chr}#{colorG.chr}#{colorB.chr}#{alpha}"}
    lower_half = (0...radius).map do |y|
      x = Math.sqrt(radius**2 - y**2).round
      right_half = "#{"#{colorB.chr}" * x}#{"#{0.chr}" * (radius - x)}"
      "#{right_half.reverse}#{right_half}"
    end.join
    blob2 = lower_half.reverse + lower_half
    blob2.gsub!(/./) { |alpha| "#{colorR.chr}#{colorG.chr}#{colorB.chr}#{alpha}"}
    if colorB > 0
      @blob = blob2
    elsif colorG > 0
      @blob = blob1
    else
      @blob = blob0
    end
  #  puts @blob.inspect
  end

  def to_blob
    @blob
  end
end
