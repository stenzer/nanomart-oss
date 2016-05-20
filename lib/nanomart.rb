# Nanomart validates purchases using age- and date-related restrictions 

class Nanomart
  attr_accessor :customer_age
  @customer_age = nil
  class NoSale < StandardError
    # TODO: so far, just raise generic error if sale isn't approved
  end

  def initialize(age=0)
    @customer_age = age
  end
  
  def self.inventory_log
    'inventory.log'
  end
  
  def sell_me(item_type)
    begin
      item =   BaseItem.const_get(item_type.to_s.split('_').collect{|w|w.capitalize}.join).new 
      # instantiate a CannedHaggis, for example, if :canned_haggis is passed
    rescue
      raise ArgumentError, "Unexpected error: Don't know how to sell #{item_type}"
    end
    item.restrictions.each { |r| item.try_purchase(r.validate_age! customer_age)} 
    item.log_sale
  end
end
 
class String
  def underscore
    self.gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
  end
end


class BaseItem

  def restrictions
    [] # By default, anyone can buy
  end
  
  def log_sale
    # Append item name for each verified age-check to the log 
    # TODO: what else needs to be logged?
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
    def validate_age!(current_age)
      current_age >= minimum_age
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
    def validate_age! current_age
      # Indicates no hard liquor sales allowed on Sundays (weekday value for Sunday is 0)
      Time.now.wday != 0  
    end
  end
end

 # ==================== BaseItem Subclasses =================

  class Beer < BaseItem
    def restrictions
      [Restriction::DrinkingAge.new]
    end
  end

  class Whiskey < BaseItem
    def restrictions
      [Restriction::DrinkingAge.new, Restriction::SundayBlueLaw.new]
    end
  end

  class Cigarettes < BaseItem
    def restrictions
      [Restriction::SmokingAge.new]
    end
  end

  class Cola < BaseItem
  end

  class CannedHaggis < BaseItem
  end
