module RedmineIssueFieldVisibility
  module Patches
    # Prepended, see ApplicationControllerPatch.
    #
    # Mailer#process makes the recipient User.current, so the headers
    # (X-Redmine-Issue-Assignee) and the body (description) of an issue mail
    # leave out the fields hidden for the recipient.
    module MailerPatch
      def issue_add(*args)
        RedmineIssueFieldVisibility.hide_values do
          super
        end
      end

      def issue_edit(*args)
        RedmineIssueFieldVisibility.hide_values do
          super
        end
      end
    end
  end
end

Mailer.prepend(RedmineIssueFieldVisibility::Patches::MailerPatch)
