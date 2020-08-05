require "./spec_helper"
include ConcurrencyUtil

describe ConcurrencyUtil do
  describe "Channel#partition" do
    it "works" do
      done = Channel(Nil).new
      ch = Channel(Int32).new
      even, odd = ch.partition do |v|
        v.even?
      end
      spawn do
        (1..5).each {|i| ch.send i }
      end
      spawn do
        even.receive.should eq 2
        even.receive.should eq 4
        puts "done"
        done.send nil
      end
      spawn do
        odd.receive.should eq 1
        odd.receive.should eq 3
        odd.receive.should eq 5
        puts "done"
        done.send nil
      end
      2.times { done.receive }
    end
  end
end
