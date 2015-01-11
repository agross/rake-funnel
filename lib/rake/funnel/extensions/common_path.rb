require 'abbrev'
require 'pathname'

module Rake::Funnel::Extensions
  module CommonPath
    def common_path
      list = self
        .to_a
        .compact
        .map { |x| components(x) }

      min = list.min_by { |x| x.length }

      matches = list.map do |path|
        longest_prefix = []

        path.zip(min).each do |left, right|
          if left != right
            next
          end
          longest_prefix << right
        end

        File.join(longest_prefix)
      end

      matches.min_by { |x| x.length } || ''
    end

    private
    def components(path)
      paths = []
      Pathname.new(path).descend do |p|
        paths << p
      end

      paths.inject([]) { |components, path|
        relative = path.relative_path_from(components.last[:absolute]) if components.any?

        components << { absolute: path, relative: relative || path }
      }.map { |component| component[:relative].to_s }
    end
  end
end

class Array
  include Rake::Funnel::Extensions::CommonPath
end

class Rake::FileList
  include Rake::Funnel::Extensions::CommonPath
end
