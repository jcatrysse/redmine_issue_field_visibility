require_dependency 'issue_query'

module RedmineIssueFieldVisibility
  module Patches
    # Prepended, see ApplicationControllerPatch.
    module IssueQueryPatch
      def initialize_available_filters
        super

        hidden_core_fields.each do |field|
          delete_available_filter field
        end
      end

      def available_columns
        return @available_columns if @available_columns

        @available_columns = super.reject do |col|
          hidden_core_fields.include?(col.name.to_s) || hidden_core_fields.include?("#{col.name}_id")
          end
      end

      def hidden_core_fields
        @hidden_core_fields ||= begin
                                  fields = RedmineIssueFieldVisibility.hidden_core_fields(
                                    User.current, project
                                  )
                                  if fields.include?("estimated_hours")
                                    fields << "total_estimated_hours"
                                    # column and total since Redmine 6
                                    fields << "estimated_remaining_hours"
                                  end
                                  fields
                                end
      end
    end
  end
end

IssueQuery.prepend(RedmineIssueFieldVisibility::Patches::IssueQueryPatch)
