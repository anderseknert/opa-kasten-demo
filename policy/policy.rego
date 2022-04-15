package policy

import future.keywords

deny["Frequency value for policy should be '@daily'"] {
    not policy_frequency_daily
}

deny["Actions must include both backup and export, in that order"] {
    not includes_backup_and_export
}

deny["Export actions must have an hourly frequency"] {
    not export_frequency_hourly
}

policy_frequency_daily {
    input.request.object.spec.frequency == "@daily"
}

export_frequency_hourly {
    export_actions := [item | some item in input.request.object.spec.actions
                              item.action == "export"]

    every export_action in export_actions {
        export_action.exportParameters.frequency == "@hourly"
    }
}

includes_backup_and_export {
    # Get name of each action, filter out actions other than backup and export
    actions := [item.action | some item in input.request.object.spec.actions
                              item.action in {"backup", "export"}]

    # Make sure that they appear in order
    # TODO: Could be more than once?
    actions == ["backup", "export"]
}