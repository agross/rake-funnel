require 'abbrev'
require 'pathname'

module Rake
  module Funnel
    module Extensions
      module CommonPath
        def common_path
          list = to_a
                 .compact
                 .map { |x| components(x) }

          min = list.min_by(&:length)

          matches = find_matches(list, min)
          matches.min_by(&:length) || ''
        end

        private

        def components(path)
          paths = []
          Pathname.new(path).descend do |p|
            paths << p
          end

          paths = paths.inject([]) do |components, p|
            relative = p.relative_path_from(components.last[:absolute]) if components.any?

            components << { absolute: p, relative: relative || p }
          end

          paths.map { |component| component[:relative].to_s }
        end

        def find_matches(list, min)
          list.map do |path|
            longest_prefix = []

            path.zip(min).each do |left, right|
              next if left != right
              longest_prefix << right
            end

            File.join(longest_prefix)
          end
        end
      end
    end
  end
end

class Array
  include Rake::Funnel::Extensions::CommonPath
end

module Rake
  class FileList
    include Rake::Funnel::Extensions::CommonPath
  end
end
