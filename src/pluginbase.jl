module PluginBase

export handle_command, handle_observer, request, persist!, store!

"Entry point for a new command plugin, only triggers on MessageCreate"
function handle_command end

"Entry point for a new observer plugin, triggers on almost all events related to text chat"
function handle_observer end #I suggest renaming handlers to observers since they act on observations

"Persist the storage object for cross-session availability"
function persist! end

"Request the given datapoints from the storage"
function request end

"Store new datapoints in the storage"
function store! end

end
