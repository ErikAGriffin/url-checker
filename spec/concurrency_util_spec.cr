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
        (1..5).each { |i| ch.send i }
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

  describe "Channel#map" do
    it "transforms values coming from a channel" do
      ch = Channel(Int32).new
      squares = ch.map { |i| i**2 }
      spawn do
        (1..5).each { |i| ch.send i }
      end
      (1..5).map { |i| i**2 }.each do |s|
        squares.receive.should eq(s)
      end
    end

    it "transforms values coming from a channel using multiple workers" do
      ch = Channel(Int32).new
      squares = ch.map(workers: 4) do |i|
        sleep 0.1 * rand
        i**2
      end
      spawn do
        (1..8).each { |i| ch.send i }
      end
      expected = (1..8).map { |i| i**2 }
      8.times do
        val = squares.receive
        expected.should contain(val)
      end
    end
  end
end
