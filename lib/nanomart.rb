# you can buy just a few things at this nanomart
require 'highline'


class Nanomart
  class NoSale < StandardError
    # TODO: so far, just raising a generic error - what should really happen if the sale is not approved?
  end

  def initialize(prompter)
    @prompter = prompter
  end
  
  def self.inventory_log
    'inventory.log'
  end
  
  def sell_me(item_type)
    begin
      item =   Item.const_get(item_type.to_s.split('_').collect{|w|w.capitalize}.join).new(@prompter) #instantiate a CannedHaggis, for example, if :canned_haggis is passed
    rescue
      raise ArgumentError, "Unexpected error: Don't know how to sell #{item_type}"
    end
    item.restrictions.each { |r| item.try_purchase(r.passes?)} 
    item.log_sale
  end
end

class HighlinePrompter
  def get_age
    # prompts for an customer's age from the command line, and returns it
    # TODO: not actually being tested from the standpoint of command-line entry, does it work?
    # TODO: let's discuss context: what's the use case, is this the best way to implement age checking, how we plan to use it?
    # TODO: we're also not keeping the age around at all, will we ever need it?
    HighLine.new.ask('Age? ', Integer)
  end
end

class String
  def underscore
    self.gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
  end
end


class Item
  # TODO: the implementation of this class could be cleaner and clearer
  # without passing around a prompter, but it's a fairly major refactor, let's think it through

  def initialize(prompter)
    @prompter = prompter
  end
  
  def restrictions
    [] # By default, anyone can buy
  end
  
  def log_sale
    # Append item name for each verified age-check to the log TODO: what else?
    File.open(Nanomart.inventory_log,'a') { | log | log.write("#{name}\n") }
  end

  def name
    self.class.name.underscore  # my class name, underscored, standardized for logging
  end

  def try_purchase(success)
    success ||  raise( Nanomart::NoSale)
  end
end

module Restriction
  DRINKING_AGE = 21
  SMOKING_AGE  = 18

  class BaseRestriction
    def initialize(p)
      @prompter = p
    end
    
    def passes?
      @prompter.get_age >= minimum_age
    end
    
  end
  
  # ==================== Restriction Subclasses =================

  class DrinkingAge < BaseRestriction
    def minimum_age; DRINKING_AGE; end
  end

  class SmokingAge < BaseRestriction
    def minimum_age; SMOKING_AGE; end
  end
  
  class SundayBlueLaw < BaseRestriction
    def passes?
      # Indicates no hard liquor sales allowed on Sundays (weekday value for Sunday is 0)
      Time.now.wday != 0  
    end
  end
end

 # ==================== Item Subclasses =================


  class Beer < Item
    def restrictions
      [Restriction::DrinkingAge.new(@prompter)]
    end
  end

  class Whiskey < Item
    def restrictions
      [Restriction::DrinkingAge.new(@prompter), Restriction::SundayBlueLaw.new(@prompter)]
    end
  end

  class Cigarettes < Item
    def restrictions
      [Restriction::SmokingAge.new(@prompter)]
    end
  end

  class Cola < Item
  end

  class CannedHaggis < Item
  end

