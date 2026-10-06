module RedmineIssueFieldVisibility
  module Patches
    module ApplicationControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method :render_to_body_without_ifv, :render_to_body
          alias_method :render_to_body, :render_to_body_with_ifv
        end
      end

      module InstanceMethods
        # API responses, and every response of the issues controller (the
        # description on the issue page, PDF, Atom), leave out the issue fields
        # hidden for the user. Only the rendering is wrapped, not the action
        # that saves the issue.
        def render_to_body_with_ifv(*args)
          if api_request? || is_a?(IssuesController)
            RedmineIssueFieldVisibility.hide_values do
              render_to_body_without_ifv(*args)
            end
          else
            render_to_body_without_ifv(*args)
          end
        end
      end
    end
  end
end

ApplicationController.include(RedmineIssueFieldVisibility::Patches::ApplicationControllerPatch)
