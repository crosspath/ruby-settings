# frozen_string_literal: true

require "json"
require "psych"

require_relative "settings/version"

# Intialize configuration from specified files.
module Settings
  # Parser for configuration files.
  class Configurator
    # @return [Hash<Symbol, Object>]
    attr_reader :values

    def initialize
      @values = {}
    end

    # @param search_pattern [String]
    # @return [Array<String>] Matched file paths
    def files(search_pattern)
      Dir.glob(search_pattern).each { |f| file(f) }
    end

    # @param file_path [String]
    # @return [Hash<Symbol, Object>]
    def file(file_path)
      hash = parse_file(file_path)
      raise ArgumentError, "File #{file_name} is empty" if hash.blank?

      @values.merge!(hash)
    end

    private

    # @param file_path [String]
    # @return [Hash<Symbol, Object>]
    # @raise [ArgumentError] When file extension is not supported
    def parse_file(file_path)
      case File.extname(file_path)
      when ".json" then JSON.load_file(file_path, symbolize_names: true)
      when ".yaml", ".yml" then Psych.safe_load_file(file_path, symbolize_names: true)
      else
        raise ArgumentError, "Unsupported file extension: #{file_path}"
      end
    end
  end

  extend self

  # @returns [Struct-like object]
  def configurate(&)
    conf = Configurator.new
    conf.instance_eval(&)

    @struct_cache = {}
    @struct_methods = Struct.instance_methods | Struct.private_instance_methods
    generate_struct(conf.values)
  end

  private

  # Returns primitive values as they are, converts Hashes into Struct-like objects, and converts
  # Array elements recursively.
  # @param value [Object]
  # @return [Object] Primitive value, Array, or Struct-like object
  def generate_struct(value)
    case value
    when Numeric, String, TrueClass, FalseClass, NilClass, Range, Date, Time
      value
    when Array
      value.map { |v| generate_struct(v) }
    when Hash
      hash_to_struct(value)
    else
      raise ArgumentError, "Unknown class: #{value.class.name}"
    end
  end

  # @param value [Hash]
  # @returns [Struct-like object]
  def hash_to_struct(value)
    value = value.to_h { |k, v| [k.to_sym, generate_struct(v)] }
    keys = value.keys.sort
    matches_with_base_methods = keys & @struct_methods

    unless matches_with_base_methods.empty?
      error_keys = matches_with_base_methods.join(", ")
      raise ArgumentError, "These keys should not be present in settings file: #{error_keys}"
    end

    @struct_cache[keys] ||= Struct.new(*keys, keyword_init: true)
    @struct_cache[keys].new(value)
  end
end
