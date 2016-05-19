# you can buy just a few things at this nanomart
require 'highline'


class Nanomart
  class NoSale < StandardError
    # TODO: so far, just raising a generic error - what should really happen if the sale is not approved?
  end

  def initialize(prompter)
    @prompter = prompter
  end
  
  def self.logfile
    'nanomart.log'
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
    # imply raises an exception if any restriction fails
    itm.log_sale
  end
end

class HighlinePrompter
  def get_age
    # prompts for an customer's age from the command line, and returns it
    # TODO: not actually being tested from the standpoint of command-line entry, does it work?
    # TODO: what's the use case, is this the best way to implement age checking, how to use it?
    HighLine.new.ask('Age? ', Integer)
  end
end


module Restriction
  DRINKING_AGE = 21
  SMOKING_AGE = 18

  class BaseRestriction
    def initialize(p)

      @prompter = p
      
    end
    
    def passes?
      @prompter.get_age >= restriction_age
    end
  end

  class DrinkingAge < BaseRestriction
    def restriction_age
      DRINKING_AGE
    end
  end

  class SmokingAge < BaseRestriction
    def restriction_age
      SMOKING_AGE
    end
  end
  
  class SundayBlueLaw < BaseRestriction
    def passes?
      Time.now.wday != 0      # 0 is Sunday
    end
  end
end

class Item
  # INVENTORY_LOG = 'inventory.log' #<--- TODO: this constant wasn't in use -- what's the intention
  # TODO: I'd suggest that the implementation of this class could be cleaner and clearer
  # without passing around a prompter, but it's a fairly major refactor so needs to be thought through

  def initialize(prompter)
    @prompter = prompter
  end

  def log_sale
    # log each sale to a file; so far, is only logging the name of the item sold, and not even checking if a sale occurred
    # this appears to be a stub, unsure what the original intention was (seemed to write to /dev/null)
    # in effect, the logging was only discarding what it was appearing to write, so let's turn if off for now
    
    # until we have better specs for what it's supposed to do:
    return nil #TODO: temp
    File.open(Nanomart.logfile) do |f|
      f.write(self.name + "\n")
    end
  end

  def name
    # returns the Item's for logging; was standardized as underscored symbol (TODO: was that correct?)
    # self.class.name.demodulize.underscore.to_sym
    self.class.name.demodulize.titleize
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
    # the common-case implementation of Item.name doesn't work here
    # TBD: clarify this comment
    def name
      :canned_haggis
    end

    def rstrctns
      []
    end
  end
end

