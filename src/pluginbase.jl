module PluginBase

export handle_command, handle_observer

"Entry point for a new command plugin, only triggers on MessageCreate"
function handle_command end

"Entry point for a new observer plugin, triggers on almost all events related to text chat"
function handle_observer end #I suggest renaming handlers to observers since they act on observations

end
