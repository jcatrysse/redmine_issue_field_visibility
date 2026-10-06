module RedmineIssueFieldVisibility
  module Patches
    module MailerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method :issue_add_without_ifv, :issue_add
          alias_method :issue_add, :issue_add_with_ifv
          alias_method :issue_edit_without_ifv, :issue_edit
          alias_method :issue_edit, :issue_edit_with_ifv
        end
      end

      # Mailer#process makes the recipient User.current, so the headers
      # (X-Redmine-Issue-Assignee) and the body (description) of an issue mail
      # leave out the fields hidden for the recipient.
      module InstanceMethods
        def issue_add_with_ifv(*args)
          RedmineIssueFieldVisibility.hide_values do
            issue_add_without_ifv(*args)
          end
        end

        def issue_edit_with_ifv(*args)
          RedmineIssueFieldVisibility.hide_values do
            issue_edit_without_ifv(*args)
          end
        end
      end
    end
  end
end

Mailer.include(RedmineIssueFieldVisibility::Patches::MailerPatch)
