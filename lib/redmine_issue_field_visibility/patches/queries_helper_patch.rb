require_dependency 'queries_helper'

module RedmineIssueFieldVisibility
  module Patches
    # Prepended, see ApplicationControllerPatch.
    module QueriesHelperPatch
      def column_content(column, item)
        if item.is_a?(Issue)
          super unless item.hidden_core_field?(column.name)
        else
          super
        end
      end
    end
  end
end

QueriesHelper.prepend(RedmineIssueFieldVisibility::Patches::QueriesHelperPatch)
