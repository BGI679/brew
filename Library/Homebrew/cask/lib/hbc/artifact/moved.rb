require "hbc/artifact/relocated"

module Hbc
  module Artifact
    class Moved < Relocated
      def self.english_description
        "#{artifact_english_name}s"
      end

      def install_phase
        each_artifact do |artifact|
          load_specification(artifact)
          next unless preflight_checks
          delete if Utils.path_occupied?(target) && force
          move
        end
      end

      def uninstall_phase
        each_artifact do |artifact|
          load_specification(artifact)
          next unless File.exist?(target)
          delete
        end
      end

      private

      def each_artifact
        # the sort is for predictability between Ruby versions
        @cask.artifacts[self.class.artifact_dsl_key].sort.each do |artifact|
          yield artifact
        end
      end

      def move
        ohai "Moving #{self.class.artifact_english_name} '#{source.basename}' to '#{target}'"
        target.dirname.mkpath
        FileUtils.move(source, target)
        add_altname_metadata target, source.basename.to_s
      end

      def preflight_checks
        if Utils.path_occupied?(target)
          if force
            ohai(warning_target_exists { |s| s << "overwriting." })
          else
            ohai(warning_target_exists { |s| s << "not moving." })
            return false
          end
        end
        unless source.exist?
          message = "It seems the #{self.class.artifact_english_name} source is not there: '#{source}'"
          raise CaskError, message
        end
        true
      end

      def warning_target_exists
        message_parts = [
                          "It seems there is already #{self.class.artifact_english_article} #{self.class.artifact_english_name} at '#{target}'",
                        ]
        yield(message_parts) if block_given?
        message_parts.join("; ")
      end

      def delete
        ohai "Removing #{self.class.artifact_english_name}: '#{target}'"
        raise CaskError, "Cannot remove undeletable #{self.class.artifact_english_name}" if MacOS.undeletable?(target)

        if force
          Utils.gain_permissions_remove(target, command: @command)
        else
          target.rmtree
        end
      end

      def summarize_artifact(artifact_spec)
        load_specification artifact_spec

        if target.exist?
          "#{printable_target} (#{target.abv})"
        else
          Formatter.error(printable_target, label: "Missing #{self.class.artifact_english_name}")
        end
      end
    end
  end
end
