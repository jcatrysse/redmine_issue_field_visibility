module RedmineIssueFieldVisibility
  module Patches
    # Prepended, see ApplicationControllerPatch.
    module IssuesHelperPatch
      def email_issue_attributes(issue, user, *_)
        issue.with_hidden_core_fields_for_user(user) do
          super
        end
      end
    end
  end
end

IssuesHelper.prepend(RedmineIssueFieldVisibility::Patches::IssuesHelperPatch)
