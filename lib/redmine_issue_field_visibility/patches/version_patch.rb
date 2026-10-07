module RedmineIssueFieldVisibility
  module Patches
    # Prepended, see ApplicationControllerPatch.
    module VersionPatch
      # The version page and API sum the estimated time over
      # visible_fixed_issues (Version::FixedIssuesExtension).
      module HiddenEstimatedHours
        def estimated_hours
          0
        end

        def estimated_remaining_hours
          0
        end
      end

      def estimated_hours
        if estimated_hours_hidden_by_ifv?
          0
        else
          super
        end
      end

      def estimated_remaining_hours
        if estimated_hours_hidden_by_ifv?
          0
        else
          super
        end
      end

      def visible_fixed_issues
        if estimated_hours_hidden_by_ifv?
          @visible_fixed_issues_with_ifv ||= super.extending(HiddenEstimatedHours)
        else
          super
        end
      end

      def estimated_hours_hidden_by_ifv?
        RedmineIssueFieldVisibility.hidden_core_fields(User.current, project).include?("estimated_hours")
      end
    end
  end
end

Version.prepend(RedmineIssueFieldVisibility::Patches::VersionPatch)
