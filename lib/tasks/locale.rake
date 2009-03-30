$KCODE = 'u'

require 'rubygems'
require 'i18n'

module I18n
  module Backend
    class Simple
      public :translations, :init_translations
    end
  end
end

class KeyStructure
  attr_reader :result
  
  def initialize(source_locale, target_locale)
    @source_locale = source_locale.to_sym || :"en"
    @locale = target_locale.to_sym
    init_backend

    @reference = I18n.backend.translations[@source_locale]
    @data = I18n.backend.translations[@locale]
    
    @result = {:bogus => [], :missing => [], :pluralization => []}
    @key_stack = []
  end
  
  def run
    compare :missing, @reference, @data
    compare :bogus, @data, @reference
  end
  
  def output
    [:missing, :bogus, :pluralization].each do |direction|
      next unless result[direction].size > 0
      case direction
      when :pluralization
        puts "\nThe following pluralization keys seem to differ:"
      else
        puts "\nThe following keys seem to be #{direction} for #{@locale.inspect}:"
      end
      puts '   ' + result[direction].join("\n   ")
    end
    if result.map{|k, v| v.size == 0}.uniq == [true]
      puts "No inconsistencies found."
    end
    puts "\n"
  end
  
  protected
  
    def compare(direction, reference, data)
      reference.each do |key, value|
        if data.has_key?(key)
          @key_stack << key
          if namespace?(value)
            compare direction, value, (namespace?(data[key]) ? data[key] : {})
          elsif pluralization?(value)
            compare :pluralization, value, (pluralization?(data[key]) ? data[key] : {})
          end
          @key_stack.pop
        else
          @result[direction] << current_key(key)
        end
      end
    end
  
    def current_key(key)
      (@key_stack.dup << key).join('.')
    end
    
    def namespace?(hash)
      Hash === hash and !pluralization?(hash)
    end
    
    def pluralization?(hash)
      Hash === hash and hash.has_key?(:one) and hash.has_key?(:other)
    end
  
    def init_backend
      I18n.load_path = []
      I18n.load_path += Dir[File.dirname(__FILE__) + "/../../config/locales/#{@source_locale}.{rb,yml}"]
      I18n.load_path += Dir[File.dirname(__FILE__) + "/../../config/locales/#{@locale}.{rb,yml}"]
      I18n.backend.init_translations
    end
end


namespace :locales do
  desc "Compare locale files and get differences and missing keys"
  task :compile do
    ENV['LANG_SOURCE'] = 'en-US' if ENV['LANG_SOURCE'].nil?
    if ENV['LANG_TARGET'].nil?
      puts "define the target language using the LANG_TARGET environment variable\nrake locales:compile LANG_TARGET=pt-BR"
      exit(1)
    end
    test = KeyStructure.new ENV['LANG_SOURCE'], ENV['LANG_TARGET']
    test.run
    test.output
  end
end