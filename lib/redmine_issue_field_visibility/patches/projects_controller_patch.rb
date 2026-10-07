module RedmineIssueFieldVisibility
  module Patches
    # Prepended, see ApplicationControllerPatch.
    module ProjectsControllerPatch
      # The project overview sums the estimated time of the project's issues
      # (and of its subprojects, Setting.display_subprojects_issues). The total
      # is left out where the user has estimated time hidden in the project,
      # and the issues of subprojects where it is hidden are not counted.
      def show
        super
        return unless @total_estimated_hours

        projects = Setting.display_subprojects_issues? ? @project.self_and_descendants.to_a : [@project]
        hidden = projects.select do |project|
          RedmineIssueFieldVisibility.hidden_core_fields(User.current, project).include?('estimated_hours')
        end
        if hidden.include?(@project)
          @total_estimated_hours = nil
        elsif hidden.any?
          @total_estimated_hours = Issue.visible.
            where(@project.project_condition(Setting.display_subprojects_issues?)).
            where.not(project_id: hidden.map(&:id)).
            sum(:estimated_hours).to_f
        end
      end
    end
  end
end

ProjectsController.prepend(RedmineIssueFieldVisibility::Patches::ProjectsControllerPatch)
