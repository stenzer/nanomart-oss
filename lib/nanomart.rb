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
  
  def sell_me(itm_type)
    itm = case itm_type
          when :beer
            Item::Beer.new(@prompter)
          when :whiskey
            Item::Whiskey.new(@prompter)
          when :cigarettes
            Item::Cigarettes.new(@prompter)
          when :cola
            Item::Cola.new(@prompter)
          when :canned_haggis
            Item::CannedHaggis.new(@prompter)
          else
            raise ArgumentError, "Don't know how to sell #{itm_type}"
          end
    itm.rstrctns.each { |r| itm.try_purchase(r.passes?)} 
    # Simply raises an exception if any restriction fails
    itm.log_sale
  end
end

class HighlinePrompter
  def get_age
    # prompts for an customer's age from the command line, and returns it
    # TODO: not actually being tested from the standpoint of command-line entry, does it work?
    # TODO: let's discuss context: what's the use case, is this the best way to implement age checking, how we plan to use it?
    HighLine.new.ask('Age? ', Integer)
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
      @prompter.get_age >= restriction_age
    end
  end

  class DrinkingAge < BaseRestriction
    def restriction_age; DRINKING_AGE; end
  end

  class SmokingAge < BaseRestriction
    def restriction_age; SMOKING_AGE; end
  end
  
  class SundayBlueLaw < BaseRestriction
    def passes?
      # return false if today is Sunday
      Time.now.wday != 0  
    end
  end
end

class Item
  # TODO: the implementation of this class could be cleaner and clearer
  # without passing around a prompter, but it's a fairly major refactor, let's think it through

  def initialize(prompter)
    @prompter = prompter
  end

  def log_sale
    # Append item name for each verified age-check to a file - in use?
    # so far, is only logging the name of the item checked, if the check passed
    
    # TODO: let's discuss use case this would seem to be a stub, originally wrote to /dev/null,
    # Previously, the logging was only discarding what it appeared to be intending to write
    
    File.open(Nanomart.inventory_log,'a') { | log | log.write("#{name}\n") }
  end

  def name
    # returns the Item's name for logging, underscored
    self.class.name.split(':').last.downcase
  end

  def try_purchase(success)
    success ||  raise( Nanomart::NoSale)
  end

  class Beer < Item
    def rstrctns
      [Restriction::DrinkingAge.new(@prompter)]
    end
  end

  class Whiskey < Item
    # No Hard Liquor sales allowed on Sundays
    def rstrctns
      [Restriction::DrinkingAge.new(@prompter), Restriction::SundayBlueLaw.new(@prompter)]
    end
  end

  class Cigarettes < Item
    def rstrctns
      [Restriction::SmokingAge.new(@prompter)]
    end
  end

  class Cola < Item
    def rstrctns
      [] # Anyone can buy. Can you imagine?
    end
  end

  class CannedHaggis < Item
    def rstrctns
      []
    end
 
    def name
      # TODO: rethink this, prevents the underscore from disappearing in the name
      'canned_haggis'
    end
  end
end

