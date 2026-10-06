module RedmineIssueFieldVisibility
  module Patches
    module VersionPatch
      def self.included(base)
        base.class_eval do
          alias_method :estimated_hours_without_ifv, :estimated_hours
          alias_method :estimated_hours, :estimated_hours_with_ifv
          alias_method :visible_fixed_issues_without_ifv, :visible_fixed_issues
          alias_method :visible_fixed_issues, :visible_fixed_issues_with_ifv
          if method_defined?(:estimated_remaining_hours)
            alias_method :estimated_remaining_hours_without_ifv, :estimated_remaining_hours
            alias_method :estimated_remaining_hours, :estimated_remaining_hours_with_ifv
          end
        end
      end

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

      def estimated_hours_with_ifv
        if estimated_hours_hidden_by_ifv?
          0
        else
          estimated_hours_without_ifv
        end
      end

      def estimated_remaining_hours_with_ifv
        if estimated_hours_hidden_by_ifv?
          0
        else
          estimated_remaining_hours_without_ifv
        end
      end

      def visible_fixed_issues_with_ifv
        @visible_fixed_issues_with_ifv ||=
          if estimated_hours_hidden_by_ifv?
            visible_fixed_issues_without_ifv.extending(HiddenEstimatedHours)
          else
            visible_fixed_issues_without_ifv
          end
      end

      def estimated_hours_hidden_by_ifv?
        RedmineIssueFieldVisibility.hidden_core_fields(User.current, project).include?("estimated_hours")
      end
    end
  end
end

Version.include(RedmineIssueFieldVisibility::Patches::VersionPatch)
