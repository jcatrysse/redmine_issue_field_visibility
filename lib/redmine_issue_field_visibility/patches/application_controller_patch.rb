module RedmineIssueFieldVisibility
  module Patches
    # Prepended, never an alias_method chain: other plugins patch the same
    # core methods with prepend, and a chain set up after their prepend
    # recurses (SystemStackError).
    module ApplicationControllerPatch
      # API responses, and every response of the issues controller (the
      # description on the issue page, PDF, Atom), leave out the issue fields
      # hidden for the user. Only the rendering is wrapped, not the action
      # that saves the issue.
      def render_to_body(*args)
        if api_request? || is_a?(IssuesController)
          RedmineIssueFieldVisibility.hide_values do
            super
          end
        else
          super
        end
      end
    end
  end
end

ApplicationController.prepend(RedmineIssueFieldVisibility::Patches::ApplicationControllerPatch)
